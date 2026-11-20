"""Builds launcher icon sources from the site logo (requires Pillow).

    python tool/make_icons.py
    dart run flutter_launcher_icons

Outputs in tool/icons/:
- icon-foreground.png  Android adaptive foreground; flutter_launcher_icons insets it
                       by 16% per side, which keeps the logo inside the 66% safe zone
- icon-monochrome.png  Android 13 themed icon; white silhouette, same placement
- icon-legacy.png      Android < 8; logo on a rounded parchment tile
- icon-ios.png         iOS; opaque, no alpha
Also writes assets/branding/app-icon.png (192 px) for the in-app About section.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
LOGO = ROOT / 'image' / 'parchment-logo-transparent.png'
OUT = Path(__file__).resolve().parent / 'icons'
SIZE = 1024
BACKGROUND = (0xF8, 0xF1, 0xE7, 255)


def placed(logo: Image.Image, scale: float) -> Image.Image:
    """Logo cropped to its visible bounds, centered at `scale` of the canvas."""
    cropped = logo.crop(logo.getchannel('A').getbbox())
    target = int(SIZE * scale)
    ratio = target / max(cropped.size)
    resized = cropped.resize(
        (round(cropped.width * ratio), round(cropped.height * ratio)),
        Image.LANCZOS,
    )
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(
        resized,
        ((SIZE - resized.width) // 2, (SIZE - resized.height) // 2),
    )
    return canvas


def fitted_in_circle(logo: Image.Image, radius: float) -> Image.Image:
    """Logo scaled so its farthest visible pixel is `radius` (fraction of the
    canvas) from the center. Launchers mask adaptive icons to a circle, so a
    square-ish logo must fit by its corners, not by its bounding box."""
    cropped = logo.crop(logo.getchannel('A').getbbox())
    alpha = cropped.getchannel('A')
    width, height = cropped.size
    cx, cy = width / 2, height / 2
    pixels = alpha.load()
    farthest = 0.0
    for y in range(0, height, 2):
        for x in range(0, width, 2):
            if pixels[x, y] > 40:
                farthest = max(farthest, ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5)
    ratio = radius * SIZE / farthest
    resized = cropped.resize(
        (round(width * ratio), round(height * ratio)), Image.LANCZOS
    )
    canvas = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    canvas.alpha_composite(
        resized,
        ((SIZE - resized.width) // 2, (SIZE - resized.height) // 2),
    )
    return canvas


def on_background(image: Image.Image, rounded: bool) -> Image.Image:
    base = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    if rounded:
        ImageDraw.Draw(base).rounded_rectangle(
            (0, 0, SIZE - 1, SIZE - 1), radius=int(SIZE * 0.22), fill=BACKGROUND
        )
    else:
        base.paste(BACKGROUND, (0, 0, SIZE, SIZE))
    base.alpha_composite(image)
    return base


def main() -> None:
    OUT.mkdir(exist_ok=True)
    logo = Image.open(LOGO).convert('RGBA')

    # The foreground is inset 16% per side, so the drawable spans 68% of the
    # icon and the circular mask (diameter 66.7% of the icon) has a radius of
    # 0.49 of the drawable. Keep the logo at 0.44 for a visible margin.
    foreground = fitted_in_circle(logo, 0.44)
    foreground.save(OUT / 'icon-foreground.png')

    alpha = foreground.getchannel('A').point(lambda a: 255 if a > 96 else 0)
    monochrome = Image.new('RGBA', (SIZE, SIZE), (255, 255, 255, 0))
    monochrome.putalpha(alpha)
    monochrome.save(OUT / 'icon-monochrome.png')

    legacy = on_background(placed(logo, 0.80), rounded=True)
    legacy.save(OUT / 'icon-legacy.png')
    branding = Path(__file__).resolve().parents[1] / 'assets' / 'branding'
    branding.mkdir(parents=True, exist_ok=True)
    legacy.resize((192, 192), Image.LANCZOS).save(branding / 'app-icon.png')
    on_background(placed(logo, 0.78), rounded=False).convert('RGB').save(
        OUT / 'icon-ios.png'
    )
    print('icons written to', OUT)


if __name__ == '__main__':
    main()
