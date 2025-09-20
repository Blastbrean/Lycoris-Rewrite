# Gemini made this script - not me.
# This script is used to sync our module folder to the workspace.
# It was modified again to also sync the config folder to our current workspace so we can also commit those files for easy access and config history for each developer.

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
from watchdog.events import FileSystemEventHandler, LoggingEventHandler

# --- Configuration ---
if len(sys.argv) <= 2:
    print("Usage: python WorkspaceSync.py <workspace_directory> <dev_name>")
    sys.exit(1)

WORKSPACE_DIR = sys.argv[1]
DEV_NAME = sys.argv[2]

# Module sync paths
SOURCE_MODULE_DIR = os.path.abspath('./Modules')
TARGET_MODULE_DIR = os.path.abspath(os.path.join(WORKSPACE_DIR, "Lycoris-Rewrite-Modules"))

# Timing sync paths
SOURCE_TIMING_DIR = os.path.abspath('./Timings')
TARGET_TIMING_DIR = os.path.abspath(os.path.join(WORKSPACE_DIR, "Lycoris-Rewrite-Timings"))
BASE_TIMING_FILE = os.path.abspath(os.path.join(SOURCE_TIMING_DIR, 'base.txt'))
TRUTH_TIMING_FILE = os.path.abspath(os.path.join(SOURCE_TIMING_DIR, "truth.txt"))
TARGET_TRUTH_FILE = os.path.abspath(os.path.join(TARGET_TIMING_DIR, "truth.txt"))

# Backup path
BACKUP_DIR = os.path.abspath(f'./WorkspaceTimingBackup/{DEV_NAME}')

# --- Helper Functions ---

def load_json_data(path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return {}
    try:
        with open(path, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, FileNotFoundError):
        return {}

def save_json_data(data, path):
    with open(path, 'w') as f:
        json.dump(data, f, indent=2)

def load_data(path):
    if not os.path.exists(path) or os.path.getsize(path) == 0:
        return {}

    try:
        with open(path, 'rb') as f:
            return msgpack.load(f, raw=False)
    except (msgpack.exceptions.UnpackException, FileNotFoundError):
        return {}

def save_data(data, path):
    with open(path, 'wb') as f:
        msgpack.dump(data, f)

def get_timing_key(timing, container_name):
    if container_name == 'part':
        return timing.get('pname')
    # Animation & sound use _id; fallback to name if missing
    return timing.get('_id') or timing.get('name')

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

    EXPECTED_CONTAINERS = ("animation", "part", "sound")
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

    IGNORE_ONLY_FIELDS = {"dp", "pfht"}  # If a timing's modified changes are confined to this set, ignore it

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

def rebuild_truth_from_patches():
    """Rebuilds truth.txt from base.txt and all patch files."""
    print("[-] Rebuilding truth file from patches...")
    current_data = load_data(BASE_TIMING_FILE)
    
    patch_filenames = [f for f in os.listdir(SOURCE_TIMING_DIR) if f.startswith('patch_') and f.endswith('.json')]
    
    patches_to_apply = []
    for filename in patch_filenames:
        patch_path = os.path.join(SOURCE_TIMING_DIR, filename)
        patch_data = load_json_data(patch_path)
        timestamp = patch_data.get("timestamp")
        if timestamp:
            patches_to_apply.append((timestamp, patch_data))

    # Sort patches by timestamp (oldest first)
    patches_to_apply.sort(key=lambda p: p[0])

    for _, patch_data in patches_to_apply:
        current_data = apply_patch(current_data, patch_data)
    
    save_data(current_data, TRUTH_TIMING_FILE)
    print("[+] Rebuild complete. TRUTH_TIMING_FILE is up to date.")
    return current_data

# --- File System Event Handlers ---

class TimingChangeHandler(FileSystemEventHandler):
    """Handles changes in the timing directories."""
    def on_modified(self, event):
        if event.is_directory:
            return
        
        # Change detected in the workspace, create a patch
        if os.path.abspath(event.src_path) == TARGET_TRUTH_FILE:
            print(f"Change detected in workspace truth file: {event.src_path}")
            
            local_truth_data = load_data(TRUTH_TIMING_FILE)
            remote_truth_data = load_data(TARGET_TRUTH_FILE)

            if str(local_truth_data) == str(remote_truth_data):
                return # No actual change

            differences = find_differences(local_truth_data, remote_truth_data)
            if not differences:
                print("No functional differences found.")
                return

            patch_id = uuid.uuid4()
            timestamp = datetime.now().isoformat()
            patch_filename = f"patch_{timestamp.replace(':', '-')}_{patch_id}.json"
            patch_filepath = os.path.join(SOURCE_TIMING_DIR, patch_filename)

            patch_content = {
                "patch_id": str(patch_id),
                "timestamp": timestamp,
                "author": DEV_NAME,
                "diff": differences
            }
            
            print(f"Generating new patch file: {patch_filename}")
            save_json_data(patch_content, patch_filepath)
            
            # Rebuild local truth and sync back to ensure consistency
            rebuild_truth_from_patches()
            shutil.copy2(TRUTH_TIMING_FILE, TARGET_TRUTH_FILE)
            print("Synced updated truth file back to workspace.")

    def on_created(self, event):
        # A new patch was added manually or by another process
        if not event.is_directory and "patch_" in event.src_path: # pyright: ignore[reportOperatorIssue]
             print(f"New patch file detected: {event.src_path}. Rebuilding truth file.")
             rebuild_truth_from_patches()
             sync_all_dirs() # Sync the newly built truth file

class ModuleChangeHandler(FileSystemEventHandler):
    """Handles simple file copy for modules."""
    def on_any_event(self, event):
        if event.is_directory:
            return
        
        src_path = event.src_path
        try:
            rel_path = os.path.relpath(src_path, SOURCE_MODULE_DIR) # pyright: ignore[reportArgumentType, reportCallIssue]
            # Only sync .lua files; skip others without converting
            if not rel_path.lower().endswith('.lua'):
                # Optional: log skip
                # print(f"Skipped non-Lua module change: {rel_path}")
                return
            dest_path = os.path.join(TARGET_MODULE_DIR, rel_path)
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            if os.path.exists(src_path):
                shutil.copy2(src_path, dest_path) # pyright: ignore[reportArgumentType, reportCallIssue]
                print(f"Synced module: {rel_path} → {os.path.relpath(dest_path, TARGET_MODULE_DIR)}")
        except Exception as e:
            print(f"Error syncing module {src_path}: {e}")

# --- Main Sync Logic ---

def sync_all_dirs():
    """Initial sync of all directories."""
    print("[*] Performing sync...")

    # 1. Sync Modules
    if os.path.isdir(SOURCE_MODULE_DIR):
        for root, _, files in os.walk(SOURCE_MODULE_DIR):
            for file in files:
                src_path = os.path.join(root, file)
                rel_path = os.path.relpath(src_path, SOURCE_MODULE_DIR)
                # Only sync Lua modules
                if not rel_path.lower().endswith('.lua'):
                    continue
                dest_path = os.path.join(TARGET_MODULE_DIR, rel_path)
                os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                if not os.path.exists(dest_path) or not cmp(src_path, dest_path, shallow=False):
                    shutil.copy2(src_path, dest_path)
                    print(f"Synced module: {rel_path} → {os.path.relpath(dest_path, TARGET_MODULE_DIR)}")
    
    # 2. Sync Timings (truth.txt)
    if os.path.exists(TRUTH_TIMING_FILE):
        shutil.copy2(TRUTH_TIMING_FILE, TARGET_TRUTH_FILE)
        print(f"Synced: {TRUTH_TIMING_FILE} → {TARGET_TRUTH_FILE}")

    # 3. Sync to Backup
    if os.path.isdir(TARGET_TIMING_DIR):
        shutil.copytree(TARGET_TIMING_DIR, BACKUP_DIR, dirs_exist_ok=True)
        print(f"Backed up workspace timings to: {BACKUP_DIR}")

    print("[*] Sync complete.")

def main():
    # Create directories
    for d in [SOURCE_MODULE_DIR, TARGET_MODULE_DIR, SOURCE_TIMING_DIR, TARGET_TIMING_DIR, BACKUP_DIR]:
        os.makedirs(d, exist_ok=True)

    # Ensure base file exists
    if not os.path.exists(BASE_TIMING_FILE):
        save_data({}, BASE_TIMING_FILE)
        print(f"Created empty base file: {BASE_TIMING_FILE}")

    # Initial state setup
    # 1. Rebuild local truth from patches so we have authoritative baseline
    rebuild_truth_from_patches()

    # 2. If a remote truth already exists (TARGET_TRUTH_FILE), compute differences BEFORE overwriting it
    if os.path.exists(TARGET_TRUTH_FILE) and os.path.getsize(TARGET_TRUTH_FILE) > 0 and os.path.exists(TRUTH_TIMING_FILE):
        try:
            local_truth_data = load_data(TRUTH_TIMING_FILE)
            remote_truth_data = load_data(TARGET_TRUTH_FILE)
            if str(local_truth_data) != str(remote_truth_data):
                initial_diff = find_differences(local_truth_data, remote_truth_data)
                if initial_diff:
                    print("[!] Detected differences between existing remote truth and local truth on startup. Creating patch.")
                    write_patch_file(initial_diff, DEV_NAME)
                    # Rebuild again including the new patch, then push truth outward
                    rebuild_truth_from_patches()
        except Exception as e:
            print(f"[!] Failed to compute initial differences: {e}")

    # 3. Perform sync (this will copy our rebuilt truth outward)
    sync_all_dirs()

    # Start observers
    print("[!] Watching for file changes...")
    observer = Observer()
    observer.schedule(ModuleChangeHandler(), path=SOURCE_MODULE_DIR, recursive=True)
    observer.schedule(TimingChangeHandler(), path=SOURCE_TIMING_DIR, recursive=True)
    observer.schedule(TimingChangeHandler(), path=TARGET_TIMING_DIR, recursive=True)
    observer.start()

    try:
        while True:
            time.sleep(5)
            # Periodic backup sync
            shutil.copytree(TARGET_TIMING_DIR, BACKUP_DIR, dirs_exist_ok=True)
    except KeyboardInterrupt:
        observer.stop()
        print("[!] Observer stopped.")
    observer.join()

if __name__ == "__main__":
    main()