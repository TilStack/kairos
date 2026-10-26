"""Compose le theme musical de KAIROS (boucle d'environ 43 s), de zero.

Musique originale generee par synthese : aucun echantillon, aucun droit
d'auteur tiers. Relancer ce script regenere exactement le meme fichier.

Usage : python tools/make_theme_music.py <sortie.wav>
"""
import sys
import wave

import numpy as np

SR = 22050
BPM = 88
BEAT = 60.0 / BPM
BAR = 4 * BEAT
BARS = 16
TOTAL = BARS * BAR


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


def env(n, attack, release):
    e = np.ones(n)
    a = max(1, int(attack * SR))
    r = max(1, int(release * SR))
    e[:a] = np.linspace(0, 1, a)
    e[-r:] *= np.linspace(1, 0, r)
    return e


def pad(note, dur):
    """Nappe douce : trois oscillateurs legerement desaccordes."""
    t = np.arange(int(dur * SR)) / SR
    f = midi(note)
    s = sum(np.sin(2 * np.pi * f * (1 + d) * t) for d in (-0.003, 0.0, 0.003))
    s += 0.3 * np.sin(2 * np.pi * f * 2 * t)
    return s * env(len(t), 0.5, 0.9) * 0.11


def pluck(note, dur):
    """Note pincee (harpe / luth) : harmoniques qui s'eteignent a tour de role."""
    t = np.arange(int(dur * SR)) / SR
    f = midi(note)
    s = np.zeros_like(t)
    for h, amp, decay in ((1, 1.0, 2.2), (2, 0.5, 3.5), (3, 0.28, 5.0), (4, 0.12, 7.0)):
        s += amp * np.sin(2 * np.pi * f * h * t) * np.exp(-decay * t)
    return s * env(len(t), 0.004, 0.05) * 0.34


def drum(dur=0.5):
    t = np.arange(int(dur * SR)) / SR
    f = 95 * np.exp(-9 * t) + 48
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-7 * t) * 0.55


def shaker(rng, dur=0.09):
    n = int(dur * SR)
    noise = rng.standard_normal(n)
    noise = np.diff(noise, prepend=0)  # passe-haut grossier
    return noise * np.exp(-np.linspace(0, 40, n)) * 0.10


def place(buf, sig, start):
    i = int(start * SR)
    end = min(len(buf), i + len(sig))
    buf[i:end] += sig[: end - i]
    # Queue qui deborde : rebouclee au debut pour une boucle sans coupure.
    if i + len(sig) > len(buf):
        over = i + len(sig) - len(buf)
        buf[:over] += sig[-over:]


rng = np.random.default_rng(7)
buf = np.zeros(int(TOTAL * SR))

# Progression en re mineur : Dm | Bb | F | C  (x2) puis  Gm | Dm | A | Dm (x2)
chords = [
    (50, 57, 62, 65), (46, 53, 58, 62), (53, 57, 60, 65), (48, 55, 60, 64),
] * 2 + [
    (55, 58, 62, 67), (50, 57, 62, 65), (45, 57, 61, 64), (50, 57, 62, 65),
] * 2
for bar, chord in enumerate(chords):
    for note in chord:
        place(buf, pad(note, BAR + 0.8), bar * BAR)

# Melodie (pentatonique de re mineur) : (mesure, temps, note midi, duree en temps)
D5, F5, G5, A5, C6, D6, E5, C5, A4 = 74, 77, 79, 81, 84, 86, 76, 72, 69
phrases = [
    # mesures 0-3 : theme principal, sobre
    (0, 0, A5, 2), (0, 2, D6, 1), (0, 3, C6, 1),
    (1, 0, A5, 2), (1, 2, F5, 2),
    (2, 0, G5, 1.5), (2, 1.5, A5, 0.5), (2, 2, C6, 2),
    (3, 0, A5, 3), (3, 3, G5, 1),
    # mesures 4-7 : reprise orne
    (4, 0, A5, 2), (4, 2, D6, 1), (4, 3, E5 + 12, 1),
    (5, 0, D6, 2), (5, 2, C6, 1), (5, 3, A5, 1),
    (6, 0, G5, 2), (6, 2, C6, 1), (6, 3, D6, 1),
    (7, 0, C6, 4),
    # mesures 8-11 : developpement, plus haut
    (8, 0, G5, 1), (8, 1, A5 + 2, 1), (8, 2, D6, 2),
    (9, 0, C6, 2), (9, 2, A5, 2),
    (10, 0, A5, 1), (10, 1, C6 + 1, 1), (10, 2, E5 + 12, 2),
    (11, 0, D6, 3), (11, 3, C6, 1),
    # mesures 12-15 : retour et conclusion apaisee
    (12, 0, A5, 2), (12, 2, D6, 1), (12, 3, C6, 1),
    (13, 0, A5, 2), (13, 2, F5, 2),
    (14, 0, G5, 2), (14, 2, A5, 2),
    (15, 0, D5 + 12, 4),
]
for bar, beat, note, dur in phrases:
    place(buf, pluck(note, dur * BEAT + 0.6), bar * BAR + beat * BEAT)

# Basse pincee sur le premier temps de chaque mesure.
for bar, chord in enumerate(chords):
    place(buf, pluck(chord[0] - 12, BAR * 0.9) * 1.6, bar * BAR)

# Percussions : tambour sur 1 et 3 (des la mesure 4), shaker sur les croches.
for bar in range(BARS):
    for beat in range(4):
        t0 = bar * BAR + beat * BEAT
        if bar >= 4 and beat in (0, 2):
            place(buf, drum(), t0)
        if bar >= 2:
            place(buf, shaker(rng), t0)
            place(buf, shaker(rng) * 0.6, t0 + BEAT / 2)

# Echo doux (espace), puis normalisation avec marge.
delay = int(0.34 * SR)
wet = np.zeros_like(buf)
wet[delay:] += buf[:-delay] * 0.34
wet[delay * 2:] += buf[:-delay * 2] * 0.18
wet[:delay] += buf[-delay:] * 0.34  # echo qui reboucle
out = buf + wet
out = np.tanh(out * 1.1)
out *= 0.82 / np.max(np.abs(out))

pcm = (out * 32767).astype("<i2")
with wave.open(sys.argv[1], "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(pcm.tobytes())
print(f"{TOTAL:.1f} s, {len(pcm) * 2 / 1e6:.2f} Mo")
