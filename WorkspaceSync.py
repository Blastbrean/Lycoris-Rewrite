# WorkspaceSync.py
# Created by AI

import time
import os
import shutil
import sys
import json
import uuid
import msgpack

from datetime import datetime
from filecmp import cmp
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configuration
if len(sys.argv) <= 2:
    print("Usage: python WorkspaceSync.py <workspace_directory> <dev_name> <replace_existing>")
    sys.exit(1)

# CLI arguments
WORKSPACE_DIR = sys.argv[1]
DEV_NAME = sys.argv[2]
REPLACE_EXISTING = (len(sys.argv) > 3 and sys.argv[3].lower() in ('1', 'true', 'yes'))

# Module sync paths
SOURCE_MODULE_DIR = os.path.abspath('./Modules')
TARGET_MODULE_DIR = os.path.abspath(os.path.join(WORKSPACE_DIR, "Lycoris-Rewrite-Modules"))

# Timing sync paths
SOURCE_TIMING_DIR = os.path.abspath('./Timings')
TARGET_TIMING_DIR = os.path.abspath(os.path.join(WORKSPACE_DIR, "Lycoris-Rewrite-Timings"))
BASE_TIMING_FILE = os.path.abspath(os.path.join(SOURCE_TIMING_DIR, 'base.txt'))
TRUTH_TIMING_FILE = os.path.abspath(os.path.join(SOURCE_TIMING_DIR, "truth.txt"))
TARGET_TRUTH_FILE = os.path.abspath(os.path.join(TARGET_TIMING_DIR, "truth.txt"))
TIMING_SYNC_LAST_FILE = os.path.abspath(os.path.join(SOURCE_TIMING_DIR, 'timing.sync.last.json'))

# Backup path
BACKUP_DIR = os.path.abspath(f'./WorkspaceTimingBackup/{DEV_NAME}')

# Backup existing workspace timings
def backup_workspace_timings():
    if os.path.isdir(TARGET_TIMING_DIR):
        shutil.copytree(TARGET_TIMING_DIR, BACKUP_DIR, dirs_exist_ok=True)
        print(f"Backed up workspace timings to: {BACKUP_DIR}")

def sync_modules():
    """Sync modules from source to target directory."""
    print("[*] Performing sync...")

    if os.path.isdir(SOURCE_MODULE_DIR):
        for root, _, files in os.walk(SOURCE_MODULE_DIR):
            for file in files:
                src_path = os.path.join(root, file)
                rel_path = os.path.relpath(src_path, SOURCE_MODULE_DIR)
 
                if not rel_path.lower().endswith('.lua'):
                    continue
            
                dest_path = os.path.join(TARGET_MODULE_DIR, rel_path)
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            
                if not os.path.exists(dest_path) or not cmp(src_path, dest_path, shallow=False):
                    shutil.copy2(src_path, dest_path)
                    print(f"Synced module: {rel_path} → {os.path.relpath(dest_path, TARGET_MODULE_DIR)}")
    
    print("[*] Sync complete.")

def load_json_data(path):
    """Load JSON data from a file, returning an empty dict if file is missing or invalid."""
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return {}

    try:
        with open(path, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return {}

def save_json_data(data, path):
    """Save data as JSON to a file."""
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)

def load_data(path):
    """Load msgpack data from a file, returning an empty dict if file is missing or invalid."""
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return {}

    try:
        with open(path, 'rb') as f:
            return msgpack.load(f, raw=False)
    except (msgpack.exceptions.UnpackException, FileNotFoundError):
        return {}

def save_data(data, path):
    """Save data as msgpack to a file."""
    with open(path, 'wb') as f:
        msgpack.dump(data, f)

def get_timing_key(timing, container_name):
    """Get a unique key for a timing entry based on its container type."""
    if container_name == 'part':
        return timing.get('pname')
    # Animation & sound use _id; fallback to name if missing

    return timing.get('_id') or timing.get('name')

def _deep_sort(obj):
    """Recursively sort dict keys for consistent comparison."""
    if isinstance(obj, dict):
        # Sort keys, recursively normalize values
        return {k: _deep_sort(obj[k]) for k in sorted(obj.keys())}

    if isinstance(obj, list):
        return [_deep_sort(v) for v in obj]

    return obj

def _parse_iso(ts):
    if not ts or not isinstance(ts, str):
        return None
    try:
        return datetime.fromisoformat(ts)
    except ValueError:
        try:
            return datetime.fromisoformat(ts.replace('Z', '+00:00'))
        except Exception:
            return None

def _equal_truth(a, b) -> bool:
    try:
        an = _deep_sort(a)
        bn = _deep_sort(b)
        return json.dumps(an, sort_keys=True, separators=(',', ':')) == json.dumps(bn, sort_keys=True, separators=(',', ':'))
    except Exception:
        return str(a) == str(b)

def find_differences(data1, data2):
    """Compute semantic differences grounded in the timing model (animation/part/sound).

    Patch schema per timing:
      removed  -> {status: removed, name: <displayName>}
      added    -> {status: added, data: <fullTimingObj>}
      modified -> {status: modified, changes: { field: {from: x, to: y}, ... }}

    For action differences we replace the entire 'actions' list if any action added/removed/modified.
    """
    patch = {}

    if not isinstance(data1, dict):
        data1 = {}
    if not isinstance(data2, dict):
        data2 = {}

    EXPECTED_CONTAINERS = ("animation", "part", "sound", "effect")
    all_containers = [c for c in EXPECTED_CONTAINERS if c in data1 or c in data2]

    def index_timings(raw_list, container):
        out = {}
        if isinstance(raw_list, list):
            for entry in raw_list:
                if isinstance(entry, dict):
                    k = get_timing_key(entry, container)
                    if k:
                        out[k] = entry
        return out

    def diff_actions(a1_list, a2_list):
        if not (isinstance(a1_list, list) and isinstance(a2_list, list)):
            return str(a1_list) != str(a2_list)  # treat as changed if structure differs
    
        map1 = {a.get("name"): a for a in a1_list if isinstance(a, dict) and a.get("name")}
        map2 = {a.get("name"): a for a in a2_list if isinstance(a, dict) and a.get("name")}
        keys = set(map1.keys()) | set(map2.keys())
    
        for k in keys:
            a1 = map1.get(k)
            a2 = map2.get(k)
            if a1 and not a2:
                return True
            if not a1 and a2:
                return True
            if a1 and a2:
                # Compare action fields (excluding transient like tp if present)
                flds = set(a1.keys()) | set(a2.keys())
                for f in flds:
                    if f == "tp":
                        continue  # transient runtime field
                    if str(a1.get(f)) != str(a2.get(f)):
                        return True
                
        return False

    for container in all_containers:
        list1 = data1.get(container, [])
        list2 = data2.get(container, [])
        timings1 = index_timings(list1, container)
        timings2 = index_timings(list2, container)

        all_keys = set(timings1.keys()) | set(timings2.keys())
        for key in all_keys:
            t1 = timings1.get(key)
            t2 = timings2.get(key)
            if t1 and not t2:
                patch.setdefault(container, {})[key] = {"status": "removed", "name": t1.get("name") or key}
                continue
        
            if t2 and not t1:
                patch.setdefault(container, {})[key] = {"status": "added", "data": t2}
                continue
        
            # Both exist: field-level diff
            changes = {}
            if not (isinstance(t1, dict) and isinstance(t2, dict)):
                if str(t1) != str(t2):
                    patch.setdefault(container, {})[key] = {"status": "modified", "changes": {"*": {"from": t1, "to": t2}}}
                continue
        
            fields = set(t1.keys()) | set(t2.keys())
            for field in fields:
                v1 = t1.get(field)
                v2 = t2.get(field)
                if field == "actions":
                    if diff_actions(v1, v2):
                        changes[field] = {"from": v1, "to": v2}
                    continue
            
                if str(v1) != str(v2):
                    changes[field] = {"from": v1, "to": v2}
            if changes:
                patch.setdefault(container, {})[key] = {"status": "modified", "changes": changes}
            
    return patch

def write_patch_file(differences, author):
    """Persist a differences dict (already in diff format) to a patch_*.json file and return its path."""
    patch_id = uuid.uuid4()
    timestamp = datetime.now().isoformat()
    patch_filename = f"patch_{timestamp.replace(':', '-')}_{patch_id}.json"
    patch_filepath = os.path.join(SOURCE_TIMING_DIR, patch_filename)
    patch_content = {
        "patch_id": str(patch_id),
        "timestamp": timestamp,
        "author": author,
        "diff": differences
    }
    print(f"Generating new patch file: {patch_filename}")
    save_json_data(patch_content, patch_filepath)
    return patch_filepath

def list_patches_sorted():
    patches = []
    try:
        for f in os.listdir(SOURCE_TIMING_DIR):
            if f.startswith('patch_') and f.endswith('.json'):
                path = os.path.join(SOURCE_TIMING_DIR, f)
                data = load_json_data(path)
                ts = data.get('timestamp')
                if ts:
                    patches.append((ts, data))
    except FileNotFoundError:
        pass
    patches.sort(key=lambda p: p[0])
    return patches

def get_latest_patch_timestamp():
    latest = None
    for ts, _ in list_patches_sorted():
        latest = ts
    return latest

def get_all_patch_ids_sorted():
    """Return list of all patch_ids in chronological order (based on filename timestamp)."""
    ids = []
    for _, data in list_patches_sorted():
        pid = data.get("patch_id")
        if pid:
            ids.append(pid)
    return ids

def read_remote_applied_patches():
    """Read applied patch IDs from marker. Backward compatible with old timestamp-based format.

    If marker missing, default is: treat remote as up-to-date (all current patches applied).
    If legacy 'last_patch_ts' exists, treat patches with ts <= last_ts as applied.
    """
    # Default: assume up-to-date (apply none)
    if not os.path.exists(TIMING_SYNC_LAST_FILE):
        return set(get_all_patch_ids_sorted())

    data = load_json_data(TIMING_SYNC_LAST_FILE)
    if not isinstance(data, dict):
        return set(get_all_patch_ids_sorted())

    # New format
    if isinstance(data.get("applied_patches"), list):
        return set([str(x) for x in data.get("applied_patches", [])])

    # Legacy format fallback
    last_ts = data.get('last_patch_ts')
    if last_ts:
        applied = set()
        dt_last = _parse_iso(last_ts)
        for ts, patch in list_patches_sorted():
            dt_ts = _parse_iso(ts)
            if dt_ts and dt_last and dt_ts <= dt_last:
                pid = patch.get("patch_id")
                if pid:
                    applied.add(pid)
        return applied

    # Fallback default
    return set(get_all_patch_ids_sorted())

def write_remote_applied_patches(patch_ids):
    os.makedirs(os.path.dirname(TIMING_SYNC_LAST_FILE), exist_ok=True)
    save_json_data({'applied_patches': list(patch_ids)}, TIMING_SYNC_LAST_FILE)

def apply_patch(base_data, patch_data):
    """Applies a patch to the base data."""
    for container, timings in patch_data.get("diff", {}).items():
        if container not in base_data:
            base_data[container] = []
        
        timings_map = {get_timing_key(t, container): t for t in base_data[container]}

        for key, change in timings.items():
            status = change["status"]
            if status == "added":
                base_data[container].append(change["data"])
            elif status == "removed":
                base_data[container] = [t for t in base_data[container] if get_timing_key(t, container) != key]
            elif status == "modified":
                if key in timings_map:
                    for field, values in change.get("changes", {}).items():
                        timings_map[key][field] = values["to"]
                    
    return base_data

def reconcile_truths(reason: str = ""):
    """Reconcile truths using patches and a remote marker.

    Steps:
    - If no difference between local and remote truths, log and exit.
    - Apply all patches (oldest->latest) to local truth (base -> truth.txt).
    - Read remote last patch ts from TARGET_TIMING_DIR/timing.sync.last.json (default = latest patch ts).
    - Apply patches newer than remote ts to remote truth, write remote truth.
    - Update remote marker to latest applied ts (or latest overall if none applied).
    - Compute differences between updated remote truth and local truth; if any, write a new patch.
    - Rebuild local truth again from base + all patches and write.
    - Backup before pushing local truth to remote, then push.
    """
    print(f"[*] ({reason}) Reconciling truths...")

    # 1) Apply all patches to local truth starting from base
    base = load_data(BASE_TIMING_FILE)
    patches = list_patches_sorted()
    current = base

    for _, p in patches:
        current = apply_patch(current, p)
    
    save_data(current, TRUTH_TIMING_FILE)

    # Compare truths
    local_truth = load_data(TRUTH_TIMING_FILE)
    remote_truth = load_data(TARGET_TRUTH_FILE) if os.path.exists(TARGET_TRUTH_FILE) else {}

    if _equal_truth(local_truth, remote_truth):
        print("[=] Local and remote truth are identical. Nothing to do.")
        return

    local_truth = current
    latest_ts = get_latest_patch_timestamp()

    # 2) Fetch remote applied patches marker (default: all current patches considered applied)
    remote_applied = set(read_remote_applied_patches())

    # 3) Apply only patches not yet applied to remote truth
    applied_any_patch = False
    newly_applied = []
    for _, p in patches:
        pid = p.get("patch_id")
        if not pid or pid in remote_applied:
            continue
        remote_truth = apply_patch(remote_truth, p)
        newly_applied.append(pid)
        applied_any_patch = True

    # If we didn't apply any patches while catching up, don't touch remote truth or marker.
    if not applied_any_patch:
        print("[=] No new patches to apply to remote. Skipping remote write and marker update.")
    else:
        # Write remote truth and update marker with applied patch IDs
        os.makedirs(os.path.dirname(TARGET_TRUTH_FILE), exist_ok=True)

        # Backup before writing remote changes
        backup_workspace_timings()
        save_data(remote_truth, TARGET_TRUTH_FILE)
        remote_applied.update(newly_applied)
        write_remote_applied_patches(remote_applied)
        
        # Log
        print(f"[+] Updated remote truth and applied patches: +{len(newly_applied)} (total {len(remote_applied)})")
    
    # 5) Find differences between updated remote truth and local truth
    diffs = find_differences(local_truth, remote_truth)
    
    if diffs:
        # 6) Create a patch from these diffs
        new_patch_path = write_patch_file(diffs, DEV_NAME)
        print(f"[+] Wrote reconcile patch: {os.path.basename(new_patch_path)}")
    
        # 7) Rebuild local truth with all patches including the new one
        base2 = load_data(BASE_TIMING_FILE)
        patches2 = list_patches_sorted()
        cur2 = base2
    
        for _, p in patches2:
            cur2 = apply_patch(cur2, p)
        
        save_data(cur2, TRUTH_TIMING_FILE)

        # Push local truth to remote (backup first)
        backup_workspace_timings()
        shutil.copy2(TRUTH_TIMING_FILE, TARGET_TRUTH_FILE)
    
        # After pushing the rebuilt local truth, mark all current patches as applied
        write_remote_applied_patches(get_all_patch_ids_sorted())
    else:
        print("[=] No remaining differences after applying missed patches. Truths are reconciled.")

class TimingChangeHandler(FileSystemEventHandler):
    """Handles changes in the timing directories."""
    def on_modified(self, event):
        if event.is_directory:
            return
        
        if os.path.abspath(event.src_path) != TARGET_TRUTH_FILE:
            return
    
        # Change detected in the workspace, create a patch
        print(f"Change detected in workspace truth file: {event.src_path}")
        reconcile_truths("remote truth modified")

    def on_created(self, event):
        if event.is_directory or not ("patch_" in event.src_path): # pyright: ignore[reportOperatorIssue]
             return
         
        # A new patch was added manually or by another process
        print(f"New patch file detected: {event.src_path}. Rebuilding truth file.")
        reconcile_truths("new patch detected")

class ModuleChangeHandler(FileSystemEventHandler):
    """Handles simple file copy for modules."""
    def on_any_event(self, event):
        if event.is_directory:
            return
        
        src_path = event.src_path
    
        try:
            rel_path = os.path.relpath(src_path, SOURCE_MODULE_DIR) # pyright: ignore[reportArgumentType, reportCallIssue]
            if not rel_path.lower().endswith('.lua'):
                return
        
            dest_path = os.path.join(TARGET_MODULE_DIR, rel_path)
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
        
            if not os.path.exists(src_path):
                return
        
            shutil.copy2(src_path, dest_path) # pyright: ignore[reportArgumentType, reportCallIssue]
            print(f"Synced module: {rel_path} → {os.path.relpath(dest_path, TARGET_MODULE_DIR)}")
        
        except Exception as e:
            print(f"Error syncing module {src_path}: {e}")

def main():
    """Main entry point."""

    # Create directories
    for d in [SOURCE_MODULE_DIR, TARGET_MODULE_DIR, SOURCE_TIMING_DIR, TARGET_TIMING_DIR, BACKUP_DIR]:
        os.makedirs(d, exist_ok=True)

    # Ensure base file exists
    if not os.path.exists(BASE_TIMING_FILE):
        save_data({}, BASE_TIMING_FILE)
        print(f"Created empty base file: {BASE_TIMING_FILE}")

    # Ensure marker file exists with default (treat all current patches as applied)
    if not os.path.exists(TIMING_SYNC_LAST_FILE):
        os.makedirs(os.path.dirname(TIMING_SYNC_LAST_FILE), exist_ok=True)
        write_remote_applied_patches(get_all_patch_ids_sorted())

    if REPLACE_EXISTING:
        # 1) Apply all patches to local truth starting from base
        base = load_data(BASE_TIMING_FILE)
        patches = list_patches_sorted()
        current = base

        for _, p in patches:
            current = apply_patch(current, p)
        
        save_data(current, TRUTH_TIMING_FILE)
        
        # 2) Push local truth to remote forcefully and mark all current patches as applied
        shutil.copy2(TRUTH_TIMING_FILE, TARGET_TRUTH_FILE)
        write_remote_applied_patches(get_all_patch_ids_sorted())
    
    # Sync modules 
    sync_modules()

    # Backup timings
    backup_workspace_timings()

    # Build/merge truths on startup
    reconcile_truths("startup")

    # Start observers
    print("[!] Watching for file changes...")
    observer = Observer()
    observer.schedule(ModuleChangeHandler(), path=SOURCE_MODULE_DIR, recursive=True)
    observer.schedule(TimingChangeHandler(), path=SOURCE_TIMING_DIR, recursive=True)
    observer.schedule(TimingChangeHandler(), path=TARGET_TIMING_DIR, recursive=True)
    observer.start()

    # Run indefinitely until stopped
    try:
        while True: 
            time.sleep(1)
    
    except KeyboardInterrupt:
        observer.stop()
        print("[!] Observer stopped.")
    
    # Wait for threads to finish
    observer.join()

# Only run if executed as a script
if __name__ == "__main__":
    main()