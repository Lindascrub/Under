"""SUONI SEGNAPOSTO del Capitolo 5 (la Città), generati: rumore e onde semplici, niente campioni.
Si sostituiscono con suoni veri della stessa durata (vedi docs/ASSET_LIST.md).
  audio/crash.wav          la vetrina che si rompe (5.13)
  audio/thump.wav          il libro che cade dalla libreria di Ada (5.02)
  audio/crack.wav          il biscotto di Rina (scena segreta)
  audio/music_citta.wav    vento e uccelli: l'esterno (5.01), in loop

Esegui dalla cartella del progetto:  python tools/make_sfx_citta.py
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RATE = 22050


def write(name, samples):
    path = os.path.join(ROOT, "audio", name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s)) * 30000)) for s in samples))
    print("audio/" + name, len(samples) / RATE, "s")


def crash():
    rnd = random.Random(5)
    out = []
    n = int(RATE * 0.9)
    for i in range(n):
        t = i / RATE
        env = math.exp(-t * 6.0)
        noise = rnd.uniform(-1, 1)
        # tintinnii di vetro: tante sinusoidi acute che si spengono
        ring = sum(math.sin(2 * math.pi * f * t) * math.exp(-t * d) for f, d in ((2800, 9), (3700, 12), (5100, 15), (4300, 8)))
        out.append(0.55 * noise * env + 0.12 * ring)
    return out


def thump():
    out = []
    n = int(RATE * 0.35)
    for i in range(n):
        t = i / RATE
        f = 90 - 50 * t
        out.append(0.9 * math.sin(2 * math.pi * f * t) * math.exp(-t * 14))
    return out


def crack():
    rnd = random.Random(7)
    out = []
    n = int(RATE * 0.18)
    for i in range(n):
        t = i / RATE
        out.append(rnd.uniform(-1, 1) * math.exp(-t * 40) * (1.0 if (i // 90) % 3 else 0.3))
    return out


def ambience():
    """Dodici secondi di vento (rumore filtrato) e qualche cinguettio. Il loop si chiude senza scatti."""
    rnd = random.Random(3)
    n = RATE * 12
    out = [0.0] * n
    lp = 0.0
    for i in range(n):
        lp += (rnd.uniform(-1, 1) - lp) * 0.02
        swell = 0.6 + 0.4 * math.sin(2 * math.pi * i / n * 2)
        out[i] = lp * 0.9 * swell
    for k in range(9):
        start = rnd.randint(0, n - RATE)
        base = rnd.choice((2400, 2900, 3300))
        for j in range(3):
            s0 = start + j * int(RATE * 0.12)
            for i in range(int(RATE * 0.08)):
                t = i / RATE
                f = base + 900 * math.sin(2 * math.pi * 18 * t)
                out[(s0 + i) % n] += 0.12 * math.sin(2 * math.pi * f * t) * math.sin(math.pi * i / (RATE * 0.08))
    return out


if __name__ == "__main__":
    write("crash.wav", crash())
    write("thump.wav", thump())
    write("crack.wav", crack())
    write("music_citta.wav", ambience())
