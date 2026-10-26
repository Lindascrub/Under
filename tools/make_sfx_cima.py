"""SUONI SEGNAPOSTO del Capitolo 6 (la Cima), generati: rumore e onde semplici, niente campioni.
Si sostituiscono con suoni veri della stessa durata (vedi docs/ASSET_LIST.md).
  audio/strap.wav          la bustina di zucchero che si strappa (6.02)
  audio/drring.wav         il telefono del Capo, l'ultima volta (6.08)
  audio/music_cima.wav     la Cima: un accordo lungo e vuoto, quasi elegante, in loop
  audio/music_epilogo.wav  sei mesi dopo: poche note che tornano, in loop

Esegui dalla cartella del progetto:  python tools/make_sfx_cima.py
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from make_sfx_citta import write, RATE  # noqa: E402


def strap():
    rnd = random.Random(7)
    out = []
    n = int(RATE * 0.35)
    for i in range(n):
        t = i / RATE
        # carta che si strappa: rumore a raffiche
        burst = 1.0 if (int(t * 90) % 3) else 0.3
        out.append(0.6 * rnd.uniform(-1, 1) * burst * math.exp(-t * 5))
    return out


def drring():
    out = []
    n = int(RATE * 1.6)
    for i in range(n):
        t = i / RATE
        on = (t % 0.8) < 0.55
        bell = math.sin(2 * math.pi * 1200 * t) * (1 if int(t * 40) % 2 else -1)
        out.append(0.35 * bell * (1 if on else 0))
    return out


def chord(notes, seconds, decay=0.0, vol=0.18):
    out = []
    n = int(RATE * seconds)
    for i in range(n):
        t = i / RATE
        swell = 0.5 - 0.5 * math.cos(2 * math.pi * t / seconds)
        s = sum(math.sin(2 * math.pi * f * t) for f in notes) / len(notes)
        out.append(vol * s * swell * math.exp(-t * decay))
    return out


def music_cima():
    # due accordi lunghi, maggiori e un po' troppo puliti
    return chord([261.6, 329.6, 392.0, 523.3], 6.0) + chord([220.0, 277.2, 329.6, 440.0], 6.0)


def music_epilogo():
    out = []
    melody = [392.0, 440.0, 523.3, 440.0, 392.0, 329.6, 392.0, 0]
    for f in melody:
        n = int(RATE * 0.75)
        for i in range(n):
            t = i / RATE
            out.append(0.2 * math.sin(2 * math.pi * f * t) * math.exp(-t * 2.5) if f else 0.0)
    return out


if __name__ == "__main__":
    write("strap.wav", strap())
    write("drring.wav", drring())
    write("music_cima.wav", music_cima())
    write("music_epilogo.wav", music_epilogo())
