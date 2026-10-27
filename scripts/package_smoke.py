#!/usr/bin/env python3
"""Unpack a desktop artifact and exercise its real Flutter/Rust host."""
import argparse
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import zipfile

MACOS = sys.platform == "darwin"


def run_host(root: Path) -> None:
    if MACOS:
        run_macos_host(root)
        return
    executable_name = "skyport.exe" if os.name == "nt" else "skyport"
    library_name = "skyport_flutter_bridge.dll" if os.name == "nt" else "lib/libskyport_flutter_bridge.so"
    executables = [p for p in root.rglob(executable_name)
                   if p.is_file() and not p.is_symlink() and (p.parent / library_name).is_file()]
    if len(executables) != 1:
        raise RuntimeError(f"Expected one bundled {executable_name} with {library_name}, found {executables}")
    executable = executables[0]
    library = executable.parent / library_name
    if os.name != "nt":
        dependencies = subprocess.run(["ldd", str(library)], check=True, capture_output=True, text=True)
        print(dependencies.stdout)
        if "not found" in dependencies.stdout:
            raise RuntimeError("Unresolved bundled Rust bridge dependency")
        executable.chmod(executable.stat().st_mode | 0o111)
    with tempfile.TemporaryDirectory(prefix="skyport-smoke-result-") as directory:
        exercise(executable, Path(directory) / "result")


def run_macos_host(root: Path) -> None:
    apps = [p for p in root.rglob("*.app") if p.is_dir() and not p.is_symlink()
            and (p / "Contents/Frameworks/libskyport_flutter_bridge.dylib").is_file()]
    if len(apps) != 1:
        raise RuntimeError(f"Expected one app bundle with the Rust bridge, found {apps}")
    contents = apps[0] / "Contents"
    with open(contents / "Info.plist", "rb") as handle:
        info = plistlib.load(handle)
    executable = contents / "MacOS" / info["CFBundleExecutable"]
    library = contents / "Frameworks/libskyport_flutter_bridge.dylib"
    dependencies = subprocess.run(["otool", "-L", str(library)], check=True, capture_output=True, text=True)
    print(dependencies.stdout)
    for line in dependencies.stdout.splitlines()[1:]:
        path = line.strip().split(" (")[0]
        if not path.startswith(("/usr/lib/", "/System/Library/", "@rpath/libskyport_flutter_bridge.dylib")):
            raise RuntimeError(f"Unexpected Rust bridge dependency: {path}")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(apps[0])], check=True)
    # The sandboxed host may only write inside its own container.
    container = Path.home() / "Library/Containers" / info["CFBundleIdentifier"] / "Data/tmp"
    container.mkdir(parents=True, exist_ok=True)
    exercise(executable, container / "skyport-smoke-result")


def exercise(executable: Path, proof: Path) -> None:
    result = subprocess.run([str(executable), "--kernel-smoke",
                             f"--kernel-smoke-result={proof}"],
                            cwd=executable.parent, capture_output=True,
                            text=True, timeout=60)
    print(result.stdout)
    print(result.stderr)
    if result.returncode != 0 or not proof.is_file() or proof.read_text().strip() != "SKYPORT_KERNEL_SMOKE_OK":
        raise RuntimeError(f"Packaged host smoke failed with exit {result.returncode}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("artifact", type=Path)
    args = parser.parse_args()
    artifact = args.artifact.resolve()
    if artifact.is_dir():
        run_host(artifact)
        return
    with tempfile.TemporaryDirectory(prefix="skyport-package-") as directory:
        root = Path(directory)
        if artifact.suffix == ".deb":
            subprocess.run(["dpkg-deb", "--extract", str(artifact), str(root)], check=True)
        elif artifact.suffix == ".rpm":
            subprocess.run(["bsdtar", "-xf", str(artifact), "-C", str(root)], check=True)
        elif artifact.suffix.lower() == ".appimage":
            artifact.chmod(artifact.stat().st_mode | 0o111)
            subprocess.run([str(artifact), "--appimage-extract"], cwd=root, check=True, stdout=subprocess.DEVNULL)
        elif artifact.suffix == ".zip":
            with zipfile.ZipFile(artifact) as archive:
                archive.extractall(root)
        elif artifact.suffix == ".dmg":
            mount = root / "mount"
            mount.mkdir()
            subprocess.run(["hdiutil", "attach", "-nobrowse", "-readonly",
                            "-mountpoint", str(mount), str(artifact)],
                           check=True, stdout=subprocess.DEVNULL)
            try:
                # Copy out so the image can be detached before the host runs.
                for app in mount.glob("*.app"):
                    shutil.copytree(app, root / app.name, symlinks=True)
            finally:
                subprocess.run(["hdiutil", "detach", str(mount)], check=True, stdout=subprocess.DEVNULL)
        else:
            parser.error(f"Unsupported desktop artifact: {artifact}")
        run_host(root)


if __name__ == "__main__":
    main()
