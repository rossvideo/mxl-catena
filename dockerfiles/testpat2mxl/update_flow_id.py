#!/usr/bin/env python3
import argparse
import json
import sys
import uuid


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Update the 'id' field in an MXL flow JSON file"
    )
    parser.add_argument("--file", required=True, help="Path to flow JSON file")
    parser.add_argument(
        "--id",
        dest="flow_id",
        help="UUID to set; if omitted, a new UUID4 will be generated",
    )
    args = parser.parse_args()

    flow_id = args.flow_id or str(uuid.uuid4())

    with open(args.file, "r", encoding="utf-8") as f:
        data = json.load(f)

    data["id"] = flow_id

    with open(args.file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")

    # Print resulting ID so callers can capture/log it if desired
    print(flow_id)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # noqa: BLE001 - keep simple for entrypoint
        print(f"Error updating flow id: {e}", file=sys.stderr)
        sys.exit(1)
