"""Trim supplied title button PNGs without resampling or changing artwork pixels.

Uses the already installed Pillow; source images are read-only. The source exports
have real alpha, plus isolated alpha=1 noise in otherwise transparent margins.
Use the shared alpha>=2 artwork bounds with two pixels of fringe protection.
"""
import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image

SOURCES = {
    "start": "ChatGPT Image Oct 13, 2026, 02_11_47 AM-1.png",
    "continue": "ChatGPT Image Oct 13, 2026, 02_11_49 AM-2.png",
    "settings": "ChatGPT Image Oct 13, 2026, 02_11_51 AM-3.png",
    "quit": "ChatGPT Image Oct 13, 2026, 02_11_53 AM-4.png",
}


def prepare(source_dir: Path, destination: Path):
    images, bounds, hashes = {}, [], {}
    for name, filename in SOURCES.items():
        source = source_dir / filename
        hashes[name] = hashlib.sha256(source.read_bytes()).hexdigest()
        with Image.open(source) as original:
            assert original.mode == "RGBA", f"Expected genuine source alpha: {filename}"
            images[name] = original.copy()
        alpha = images[name].getchannel("A")
        assert alpha.getextrema() == (0, 255), f"Unexpected source alpha: {filename}"
        bounds.append(alpha.point(lambda value: 255 if value >= 2 else 0).getbbox())
    assert len({image.size for image in images.values()}) == 1
    crop = (min(box[0] for box in bounds) - 2, min(box[1] for box in bounds) - 2,
            max(box[2] for box in bounds) + 2, max(box[3] for box in bounds) + 2)
    destination.mkdir(parents=True, exist_ok=True)
    for name, image in images.items():
        processed = image.crop(crop)
        # Cropping changes no pixel within the artwork, including dark/internal pixels.
        processed.save(destination / f"{name}.png")
        with Image.open(destination / f"{name}.png") as saved:
            assert saved.tobytes() == processed.tobytes()
            assert saved.getchannel("A").getextrema() == (0, 255)
        assert hashlib.sha256((source_dir / SOURCES[name]).read_bytes()).hexdigest() == hashes[name]
    report = {"source_files": SOURCES, "source_sha256": hashes, "crop": crop,
              "dimensions": list(processed.size), "resampled": False,
              "method": "Shared crop of existing RGBA; only external alpha=1 margin speckles trimmed"}
    (destination / "preparation.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Prepared four RGBA buttons: {processed.width}x{processed.height}; no resizing or recoloring")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-dir", type=Path, default=Path("C:/Zekrui"))
    parser.add_argument("--output-dir", type=Path, default=Path(__file__).resolve().parents[1] / "assets/ui/title_buttons")
    args = parser.parse_args()
    prepare(args.source_dir, args.output_dir)
