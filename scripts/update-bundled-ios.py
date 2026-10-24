#!/usr/bin/env python3
"""Export the pinned iOS Git tag without using or modifying its working tree."""

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import shutil
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[1]
DESTINATION = ROOT / "ios/Bundled/PushPlatformSDK"
SOURCE_PREFIX = "Sources/PushPlatformSDK/"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ios-repo", required=True, type=Path, help="Local iOS Git repository (read only)")
    args = parser.parse_args()
    repository = args.ios_repo.resolve()
    lock = json.loads((ROOT / "ios/native-sdk.lock.json").read_text())

    def git(*arguments):
        return subprocess.check_output(["git", "-C", str(repository), *arguments])

    tag_ref = "refs/tags/" + lock["tag"]
    for ref, expected in ((tag_ref, lock["tag_object"]), (tag_ref + "^{commit}", lock["commit"])):
        actual = git("rev-parse", "--verify", ref).decode().strip()
        if actual != expected:
            raise ValueError(f"{ref}: expected {expected}, got {actual}")

    entries = git("ls-tree", "-rz", lock["commit"]).split(b"\0")
    files = {}
    for entry in filter(None, entries):
        metadata, raw_name = entry.split(b"\t", 1)
        name = raw_name.decode("utf-8")
        # Include the entire source tree, including resources, and all license notices.
        basename = PurePosixPath(name).name.upper()
        notice = any(basename.startswith(prefix) for prefix in ("LICENSE", "NOTICE", "COPYING"))
        if not (name.startswith(SOURCE_PREFIX) or notice):
            continue
        if PurePosixPath(name).is_absolute() or ".." in PurePosixPath(name).parts:
            raise ValueError(f"Unsafe upstream path: {name}")
        if metadata.split()[0] != b"100644":
            raise ValueError(f"Expected regular source file: {name}")
        files[name] = git("show", lock["commit"] + ":" + name)

    if "LICENSE" not in files or not any(name.endswith(".swift") for name in files):
        raise ValueError("Pinned tag must contain LICENSE and Swift sources")

    manifest = dict(lock, sha256={name: hashlib.sha256(data).hexdigest() for name, data in sorted(files.items())})
    DESTINATION.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".bundled-ios-", dir=DESTINATION.parent) as temporary:
        staging = Path(temporary) / "PushPlatformSDK"
        for name, data in files.items():
            target = staging / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        (staging / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
        if DESTINATION.exists():
            shutil.rmtree(DESTINATION)
        staging.rename(DESTINATION)
    print(f"Bundled {len(files)} files from {lock['tag']} ({lock['commit']})")


if __name__ == "__main__":
    main()
