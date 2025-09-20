from pathlib import Path
import msgpack
import argparse
import json
import uuid
from datetime import datetime
from typing import Optional, Iterable, Dict

def load_msgpack(p: Path):
    if not p.exists() or p.stat().st_size == 0:
        return {}
    
    file_content = p.read_bytes()
    
    try:
        # Use an unpacker and feed it the data.
        # This is more robust for files that might have extra trailing data.
        unpacker = msgpack.Unpacker(raw=False)
        unpacker.feed(file_content)
        return next(unpacker)
    except (msgpack.exceptions.ExtraData, StopIteration):
        # If the above fails, it might be a different packing issue.
        # Fallback to unpackb which can sometimes handle it.
        try:
            return msgpack.unpackb(file_content, raw=False)
        except msgpack.exceptions.ExtraData:
             # If unpackb also fails with extra data, try the unpacker again
             # but this time it's the last resort.
            try:
                unpacker = msgpack.Unpacker(raw=False)
                unpacker.feed(file_content)
                return next(unpacker)
            except (msgpack.exceptions.ExtraData, StopIteration):
                return {} # Return empty if all attempts fail
    except Exception:
        return {} # Catch any other unexpected errors during unpacking

def compare_timings(timing1, timing2, only_fields: Optional[Iterable[str]] = None):
    """Compares two timing dictionaries and returns a dict of modified fields.

    If only_fields is provided, only those fields are considered for modification detection.
    """
    modified_fields = {}
    if only_fields is not None:
        fields = set(only_fields)
        keys_to_check = fields
    else:
        keys_to_check = set(timing1.keys()) | set(timing2.keys())

    for key in keys_to_check:
        val1 = timing1.get(key)
        val2 = timing2.get(key)
        # Compare string representations to handle nested dicts/lists simply
        if str(val1) != str(val2):
            modified_fields[key] = (val1, val2)
    return modified_fields

def main():
    parser = argparse.ArgumentParser(description="Compare timing data in two msgpack config files.")
    parser.add_argument("file1", type=Path, help="Path to the first config file.")
    parser.add_argument("file2", type=Path, help="Path to the second config file.")
    parser.add_argument(
        "--add-removed",
        action="store_true",
        help="Restore all entries detected as (removed) from file1 back into file2 before writing output.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Optional path to write the updated second config. If omitted and --add-removed is set, file2 will be overwritten (a .bak backup will be created).",
    )
    parser.add_argument(
        "--log-modified-fields",
        action="store_true",
        help="Include the list of changed field names for modified entries in the diff output.",
    )
    parser.add_argument(
        "--write-patch",
        action="store_true",
        help="Write a patch JSON into ./Timings (no in-place modification of the second file).",
    )
    parser.add_argument(
        "--author",
        type=str,
        default=None,
        help="Optional author to include in the generated patch file.",
    )
    parser.add_argument(
        "-F", "--only-field",
        action="append",
        default=None,
        help="Restrict modification detection to specific fields (repeatable).",
    )
    args = parser.parse_args()

    config1 = load_msgpack(args.file1)
    config2 = load_msgpack(args.file2)

    only_fields = set(args.only_field) if args.only_field else None

    containers = ["animation", "part", "sound"]

    # Counters and detail aggregation to match Preprocessor.py's logging style
    per_container_counts: Dict[str, Dict[str, int]] = {k: {"added": 0, "removed": 0, "modified": 0} for k in containers}
    added_total = removed_total = modified_total = 0
    restored_total = 0  # count of items restored into config2
    detail_lines = []
    detail_cap = 500
    full_len = 0

    def type_label(c: str) -> str:
        return "Animation" if c == "animation" else ("Part" if c == "part" else ("Sound" if c == "sound" else c))

    # Prepare mutable container lists in config2 (ensure lists exist if we may restore)
    if args.add_removed and not args.write_patch:
        for container_name in containers:
            if container_name not in config2 or not isinstance(config2.get(container_name), list):
                config2[container_name] = []

    # Patch accumulator when --write-patch is enabled
    patch_diff: Dict[str, Dict[str, dict]] = {}

    for container_name in containers:
        # The data is a list of timings, so we convert it to a dict for easier lookup.
        # The key for each timing is different depending on the container.
        def get_timing_key(timing, container):
            if container == 'part':
                return timing.get('pname')
            return timing.get('_id')

        timings1_list = config1.get(container_name, [])
        timings2_list = config2.get(container_name, [])

        timings1 = {get_timing_key(t, container_name): t for t in timings1_list if get_timing_key(t, container_name)}
        timings2 = {get_timing_key(t, container_name): t for t in timings2_list if get_timing_key(t, container_name)}

        keys1 = set(timings1.keys())
        keys2 = set(timings2.keys())

        added_keys = sorted(keys2 - keys1)
        removed_keys = sorted(keys1 - keys2)
        common_keys = sorted(keys1 & keys2)

        # Added
        for key in added_keys:
            per_container_counts[container_name]["added"] += 1
            added_total += 1
            if len(detail_lines) < detail_cap:
                name_display = (timings2.get(key, {}) or {}).get('name', key)
                detail_lines.append(f"+ (added) {type_label(container_name)} : {name_display}")
            full_len += 1

            if args.write_patch:
                patch_diff.setdefault(container_name, {})[key] = {
                    "status": "added",
                    "data": timings2.get(key),
                }

        # Removed
        for key in removed_keys:
            per_container_counts[container_name]["removed"] += 1
            removed_total += 1
            if len(detail_lines) < detail_cap:
                name_display = (timings1.get(key, {}) or {}).get('name', key)
                detail_lines.append(f"- (removed) {type_label(container_name)} : {name_display}")
            full_len += 1

            # Optionally restore removed entries into config2
            if args.add_removed and not args.write_patch:
                removed_item = timings1.get(key)
                if removed_item is not None:
                    # Append to the original list in config2 to preserve order semantics
                    if not isinstance(timings2_list, list):
                        # If somehow not list, coerce
                        config2[container_name] = list(config2.get(container_name, []))
                        timings2_list = config2[container_name]
                    timings2_list.append(removed_item)
                    restored_total += 1

            if args.write_patch:
                # Reverse removal: emit as an 'added' entry using data from file1
                patch_diff.setdefault(container_name, {})[key] = {
                    "status": "added",
                    "data": timings1.get(key),
                }

        # Modified
        for key in common_keys:
            timing1 = timings1.get(key, {})
            timing2 = timings2.get(key, {})
            modified_fields = compare_timings(timing1, timing2, only_fields)
            if modified_fields:
                per_container_counts[container_name]["modified"] += 1
                modified_total += 1
                if len(detail_lines) < detail_cap:
                    name_display = timing2.get('name') or timing1.get('name') or key
                    if args.log_modified_fields:
                        changed_keys = ", ".join(sorted(map(str, modified_fields.keys())))
                        detail_lines.append(f"+ (changed) {type_label(container_name)} : {name_display} [fields: {changed_keys}]")
                    else:
                        detail_lines.append(f"+ (changed) {type_label(container_name)} : {name_display}")
                full_len += 1

                if args.write_patch:
                    changes = {field: {"from": vals[0], "to": vals[1]} for field, vals in modified_fields.items()}
                    patch_diff.setdefault(container_name, {})[key] = {
                        "status": "modified",
                        "changes": changes,
                    }

    # Build and print summary to match Preprocessor.py style
    if added_total or removed_total or modified_total:
        per_container_msgs = []
        for key in containers:
            c = per_container_counts[key]
            if c["added"] or c["removed"] or c["modified"]:
                per_container_msgs.append(f"{key}: +{c['added']}/-{c['removed']}/~{c['modified']}")
        summary = ", ".join(per_container_msgs) if per_container_msgs else "no container changes"
        print(f"Timing diff vs. previous snapshot: +{added_total}/-{removed_total}/~{modified_total} ({summary})")
        if detail_lines:
            if len(detail_lines) == detail_cap:
                detail_lines.append(f"... (truncated output, only showing {len(detail_lines)} diff out of {full_len})")
            for ln in detail_lines:
                print(ln)
    else:
        print("Timing diff vs. previous snapshot: no changes detected.")

    # If requested, write a patch file into ./Timings and exit without modifying file2
    if args.write_patch:
        timings_dir = Path(__file__).parent / "Timings"
        timings_dir.mkdir(parents=True, exist_ok=True)

        patch_id = uuid.uuid4()
        timestamp = datetime.now().isoformat()
        filename = f"patch_{timestamp.replace(':', '-')}_{patch_id}.json"
        patch_path = timings_dir / filename

        author = args.author if args.author else None
        patch_content = {
            "patch_id": str(patch_id),
            "timestamp": timestamp,
            **({"author": author} if author else {}),
            "diff": patch_diff,
        }

        # Only write a patch if there are any changes
        if any(patch_diff.get(c) for c in patch_diff):
            try:
                patch_path.write_text(json.dumps(patch_content, indent=2, ensure_ascii=False))
                print(f"Wrote patch file: {patch_path}")
            except Exception as e:
                print(f"Error: Failed to write patch file '{patch_path}': {e}")
        else:
            print("No differences detected; no patch file created.")

        # If both flags were passed, clarify precedence
        if args.add_removed:
            print("Note: --write-patch was set; skipped restoring removed entries into file2.")

        return

    # If we restored removed entries, write out the updated config2
    if args.add_removed and restored_total > 0:
        out_path: Path = args.output if args.output is not None else args.file2

        # Make a .bak if overwriting the original file2
        if args.output is None and args.file2.exists():
            try:
                backup_path = args.file2.with_suffix(args.file2.suffix + ".bak")
                # Only create/overwrite backup if different file or we choose to always backup
                backup_path.write_bytes(args.file2.read_bytes())
                print(f"Backup created at: {backup_path}")
            except Exception as e:
                print(f"Warning: Failed to create backup '{args.file2}.bak': {e}")

        try:
            # Write using msgpack, prefer bin types
            out_bytes: bytes = msgpack.packb(config2, use_bin_type=True)  # type: ignore[assignment]
            out_path.write_bytes(out_bytes)
            print(f"Restored {restored_total} removed item(s) into: {out_path}")
        except Exception as e:
            print(f"Error: Failed to write updated config to '{out_path}': {e}")

if __name__ == "__main__":
    main()
