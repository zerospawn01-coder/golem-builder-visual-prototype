import argparse
from pathlib import Path
from hashlib import md5
from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
SOURCE_ROOT = ROOT / "assets/source/environment/quarry"
RUNTIME = ROOT / "assets/runtime/environment/quarry"
INSPECTION = ROOT / "tests/visual_log/v5_quarry"
CANDIDATE_ROOT = ROOT / "tests/fixtures/v5_quarry_candidate"
SIZE = (1024, 512)

LAYERS = {
    "background": "quarry_background_v1",
    "midground": "quarry_midground_v1",
    "foreground": "quarry_foreground_v1",
}

SOURCE_REVISIONS = {
    "v1": (
        SOURCE_ROOT / "reference/quarry_v1",
        {layer: f"{stem}_source.png" for layer, stem in LAYERS.items()},
    ),
    "v2": (
        SOURCE_ROOT,
        {layer: f"quarry_{layer}_v2_source.png" for layer in LAYERS},
    ),
}


def make_horizontal_wrap(image: Image.Image) -> Image.Image:
    """Preserve the authored composition and enforce the exact edge scanline contract."""
    wrapped = image.copy()
    pixels = wrapped.load()
    for y in range(wrapped.height):
        pixels[wrapped.width - 1, y] = pixels[0, y]
    return wrapped


def make_seam_composite(image: Image.Image) -> Image.Image:
    band = 8
    composite = Image.new(image.mode, (band * 2, image.height))
    composite.paste(image.crop((image.width - band, 0, image.width, image.height)), (0, 0))
    composite.paste(image.crop((0, 0, band, image.height)), (band, 0))
    return composite


def center_cover(image: Image.Image, viewport: tuple[int, int]) -> Image.Image:
    scale = max(viewport[0] / image.width, viewport[1] / image.height)
    scaled = image.resize(
        (round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS
    )
    left = (scaled.width - viewport[0]) // 2
    top = (scaled.height - viewport[1]) // 2
    return scaled.crop((left, top, left + viewport[0], top + viewport[1]))


def write_import_metadata(runtime_path: Path) -> None:
    resource_path = "res://" + runtime_path.relative_to(ROOT).as_posix()
    digest = md5(resource_path.encode("utf-8")).hexdigest()
    imported_path = f"res://.godot/imported/{runtime_path.name}-{digest}.ctex"
    text = f'''[remap]

importer="texture"
type="CompressedTexture2D"
path="{imported_path}"
metadata={{
"vram_texture": false
}}

[deps]

source_file="{resource_path}"
dest_files=["{imported_path}"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
'''
    runtime_path.with_suffix(runtime_path.suffix + ".import").write_text(text, encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export an explicit Quarry source-art revision to the frozen V5 runtime contract."
    )
    parser.add_argument(
        "--source-revision",
        choices=SOURCE_REVISIONS,
        default="v1",
        help="Source art to export. Runtime filenames remain *_v1.png by contract.",
    )
    parser.add_argument(
        "--preview-only",
        action="store_true",
        help="Build source-revision inspection images without changing frozen runtime assets.",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    source_dir, source_filenames = SOURCE_REVISIONS[args.source_revision]
    inspection_dir = (
        ROOT / f"tests/visual_log/v5_quarry_{args.source_revision}_source"
        if args.preview_only
        else INSPECTION
    )
    inspection_dir.mkdir(parents=True, exist_ok=True)
    candidate_dir = CANDIDATE_ROOT / args.source_revision
    if args.preview_only:
        candidate_dir.mkdir(parents=True, exist_ok=True)
    runtime_images: dict[str, Image.Image] = {}
    for layer, stem in LAYERS.items():
        source_path = source_dir / source_filenames[layer]
        if not source_path.is_file():
            raise FileNotFoundError(
                f"Missing Quarry {args.source_revision} source for {layer}: {source_path}"
            )
        with Image.open(source_path) as opened:
            mode = "RGB" if layer == "background" else "RGBA"
            image = opened.convert(mode)
            image = image.resize(SIZE, Image.Resampling.LANCZOS)
            image = make_horizontal_wrap(image)
            if args.preview_only:
                image.save(candidate_dir / f"quarry_{layer}_candidate.png", format="PNG", optimize=True)
            if not args.preview_only:
                runtime_dir = RUNTIME / layer
                runtime_dir.mkdir(parents=True, exist_ok=True)
                runtime_path = runtime_dir / f"{stem}.png"
                image.save(runtime_path, format="PNG", optimize=True)
                write_import_metadata(runtime_path)
                print(f"{layer}: {runtime_path.relative_to(ROOT)} {image.mode} {image.size}")
            runtime_images[layer] = image.copy()
            make_seam_composite(image).save(
                inspection_dir / f"{stem}_seam_8px.png", format="PNG", optimize=True
            )

    composite = runtime_images["background"].convert("RGBA")
    composite.alpha_composite(runtime_images["midground"])
    composite.alpha_composite(runtime_images["foreground"])
    composite.convert("RGB").save(inspection_dir / "quarry_composite_2x1.png", optimize=True)
    center_cover(composite, (1280, 720)).convert("RGB").save(
        inspection_dir / "quarry_pc_16x9_center_cover.png", optimize=True
    )
    center_cover(composite, (720, 1280)).convert("RGB").save(
        inspection_dir / "quarry_mobile_9x16_center_cover.png", optimize=True
    )
    repeated = Image.new("RGBA", (composite.width * 2, composite.height))
    repeated.alpha_composite(composite, (0, 0))
    repeated.alpha_composite(composite, (composite.width, 0))
    repeated.convert("RGB").save(inspection_dir / "quarry_repeat_a_a.png", optimize=True)
    if args.preview_only:
        print(
            f"preview: {inspection_dir.relative_to(ROOT)} ({args.source_revision}); "
            f"candidate: {candidate_dir.relative_to(ROOT)}"
        )


if __name__ == "__main__":
    main()
