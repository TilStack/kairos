"""Compose les effets sonores de KAIROS (clic, bonne reponse, erreur), de zero.

Sons originaux generes par synthese : aucun echantillon, aucun droit d'auteur
tiers. Relancer ce script regenere exactement les memes fichiers.

Usage : python tools/make_sfx.py <dossier_de_sortie>
"""
import sys
import wave
from pathlib import Path

import numpy as np

SR = 22050


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def tone(freq, dur, decay, harmonics=((1, 1.0),)):
    t = np.arange(int(dur * SR)) / SR
    s = np.zeros_like(t)
    for h, amp in harmonics:
        s += amp * np.sin(2 * np.pi * freq * h * t)
    return s * np.exp(-decay * t)


def tap():
    """« Toc » de pierre : une note grave qui chute, avec un petit claquement."""
    n = int(0.14 * SR)
    t = np.arange(n) / SR
    f = 150 + 330 * np.exp(-55 * t)
    body = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-38 * t)
    rng = np.random.default_rng(3)
    click = np.diff(rng.standard_normal(n), prepend=0) * np.exp(-420 * t) * 0.22
    return (body * 0.8 + click) * np.minimum(1, t * 900)


def success():
    """Arpege ascendant de harpe : la Cle est forgee."""
    out = np.zeros(int(1.3 * SR))
    for i, note in enumerate((74, 77, 81, 86)):
        s = tone(midi(note), 0.9, 3.4, ((1, 1.0), (2, 0.4), (3, 0.18))) * 0.32
        s *= np.minimum(1, np.arange(len(s)) / (0.004 * SR))
        a = int(i * 0.085 * SR)
        out[a:a + len(s)] += s[: len(out) - a]
    return out


def error():
    """Deux notes douces qui descendent : pas tout a fait, sans reproche."""
    out = np.zeros(int(0.55 * SR))
    for i, note in enumerate((60, 55)):
        s = tone(midi(note), 0.4, 7.0, ((1, 1.0), (2, 0.25))) * 0.45
        s *= np.minimum(1, np.arange(len(s)) / (0.006 * SR))
        a = int(i * 0.13 * SR)
        out[a:a + len(s)] += s[: len(out) - a]
    return out


def save(path, sig, peak=0.8):
    sig = sig * (peak / np.max(np.abs(sig)))
    pcm = (sig * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    print(f"{path.name}: {len(pcm) / SR:.2f} s, {len(pcm) * 2 / 1000:.0f} Ko")


out_dir = Path(sys.argv[1])
out_dir.mkdir(parents=True, exist_ok=True)
save(out_dir / "tap.wav", tap(), 0.7)
save(out_dir / "success.wav", success(), 0.8)
save(out_dir / "error.wav", error(), 0.7)
