"""Dessine l'icone de KAIROS (lampe a huile allumee sur fond d'or), de zero.

Genere, depuis un seul dessin :
  - assets/icon/kairos_icon.png : maitre 1024 px (boutique, communication)
  - les icones Android : adaptatives (fond + avant-plan) et anciennes (mipmap)

Usage : python tools/make_icon.py <dossier apps/kairos_app>
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

S = 1024  # taille de travail
INK = (58, 42, 26, 255)
INK_SOFT = (91, 58, 26, 255)
FLAME = (255, 182, 46, 255)
FLAME_CORE = (255, 241, 207, 255)


def background():
    """Or chaud, plus clair au centre : meme famille que les boutons de pierre."""
    y, x = np.mgrid[0:S, 0:S].astype(float)
    d = np.hypot(x - S * 0.62, y - S * 0.42) / (S * 0.75)
    d = np.clip(d, 0, 1)[..., None]
    inner = np.array([247, 221, 160], float)
    outer = np.array([185, 128, 62], float)
    rgb = inner * (1 - d) + outer * d
    alpha = np.full((S, S, 1), 255.0)
    return Image.fromarray(np.concatenate([rgb, alpha], axis=2).astype("uint8"), "RGBA")


def teardrop(cx, base, height, half):
    """Contour d'une flamme : pointe en haut, ventre en bas."""
    left, right = [], []
    n = 40
    for i in range(n + 1):
        s = i / n  # 0 = pointe, 1 = base
        w = half * math.sin(math.pi * min(1.0, s ** 0.75 * 1.0)) ** 0.9
        y = base - height * (1 - s)
        left.append((cx - w, y))
        right.append((cx + w, y))
    return left + right[::-1]


def foreground():
    """Lampe + flamme sur fond transparent, dans la zone sure (66 % central)."""
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    # Anse (a gauche), pied, bol, bord, bec.
    d.ellipse((185, 585, 315, 725), outline=INK, width=38)
    d.rounded_rectangle((395, 745, 590, 795), radius=22, fill=INK)
    d.pieslice((275, 430, 710, 770), 0, 180, fill=INK)
    d.ellipse((255, 565, 730, 650), fill=INK_SOFT)
    d.polygon([(690, 582), (835, 540), (848, 575), (705, 648)], fill=INK_SOFT)
    d.ellipse((255, 565, 730, 650), outline=INK, width=10)

    # Flamme : or, puis coeur clair.
    d.polygon(teardrop(840, 548, 300, 84), fill=FLAME)
    d.polygon(teardrop(840, 540, 165, 42), fill=FLAME_CORE)
    # Centre le dessin dans la zone sure (decalage sans reboucler les bords).
    dx, dy = -30, -10
    shifted = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shifted.paste(layer, (dx, dy))

    # Lueur autour de la flamme, dessinee dessous : couleur unie, seule la
    # transparence varie (sinon le flou fait un halo sombre).
    cx, cy = 840 + dx, 420 + dy
    halo = Image.new("L", (S, S), 0)
    ImageDraw.Draw(halo).ellipse((cx - 230, cy - 230, cx + 230, cy + 230), fill=170)
    halo = halo.filter(ImageFilter.GaussianBlur(60))
    glow = Image.new("RGBA", (S, S), (255, 196, 70, 0))
    glow.putalpha(halo)
    return Image.alpha_composite(glow, shifted)


def main(app_dir: Path):
    fg = foreground()
    bg = background()
    full = Image.alpha_composite(bg, fg)

    master = app_dir / "assets" / "icon"
    master.mkdir(parents=True, exist_ok=True)
    full.convert("RGB").save(master / "kairos_icon.png")

    res = app_dir / "android" / "app" / "src" / "main" / "res"
    # Icone adaptative (Android 8+) : fond et avant-plan en 432 px (108 dp x 4).
    drawable = res / "drawable"
    drawable.mkdir(parents=True, exist_ok=True)
    fg.resize((432, 432), Image.LANCZOS).save(drawable / "ic_launcher_foreground.png")
    bg.resize((432, 432), Image.LANCZOS).convert("RGB").save(drawable / "ic_launcher_background.png")
    any_dpi = res / "mipmap-anydpi-v26"
    any_dpi.mkdir(parents=True, exist_ok=True)
    (any_dpi / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@drawable/ic_launcher_background"/>\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground"/>\n'
        "</adaptive-icon>\n",
        encoding="utf-8",
    )

    # Anciennes versions : carre aux coins arrondis.
    sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for name, px in sizes.items():
        icon = full.resize((px, px), Image.LANCZOS)
        mask = Image.new("L", (px, px), 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, px - 1, px - 1), radius=px // 5, fill=255)
        icon.putalpha(mask)
        out = res / f"mipmap-{name}"
        out.mkdir(parents=True, exist_ok=True)
        icon.save(out / "ic_launcher.png")
    print("icones generees")


main(Path(sys.argv[1]))
