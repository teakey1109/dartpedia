"""Build a source-only GitHub upload archive using an explicit allowlist."""
from pathlib import Path
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "release"
TOP = {"README.md", "README.en.md", ".gitignore", "pubspec.yaml", "pubspec.lock"}
PACKAGE_TOP = {"pubspec.yaml", "README.md", "CHANGELOG.md", "analysis_options.yaml", ".gitignore"}
PACKAGE_DIRS = {"lib", "bin", "test", "example"}

def selected_files():
    for path in sorted(ROOT.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(ROOT)
        if path.is_symlink() or any(part.startswith(".") for part in rel.parts[:-1]):
            continue
        if len(rel.parts) == 1 and rel.name in TOP:
            yield path
        elif rel.parts[0] in {"cli", "command_runner", "wikipedia"}:
            if (len(rel.parts) == 2 and rel.name in PACKAGE_TOP) or (
                len(rel.parts) > 2 and rel.parts[1] in PACKAGE_DIRS
                and path.suffix in {".dart", ".json"}
            ):
                yield path
        elif rel.parts[0] == "docs" and path.suffix in {".md", ".mmd"}:
            yield path
        elif rel.as_posix() == "scripts/package_release.py":
            yield path

if __name__ == "__main__":
    OUTPUT.mkdir(exist_ok=True)
    archive = OUTPUT / "dartpedia-github.zip"
    files = list(selected_files())
    manifest = "\n".join(
        hashlib.sha256(p.read_bytes()).hexdigest() + "  " + p.relative_to(ROOT).as_posix()
        for p in files
    ) + "\n"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as z:
        for path in files:
            z.write(path, path.relative_to(ROOT).as_posix())
        z.writestr("MANIFEST.sha256", manifest)
    (OUTPUT / "MANIFEST.sha256").write_text(manifest, encoding="utf-8")
    print(f"Created {archive}: {len(files)} source files + MANIFEST.sha256")
