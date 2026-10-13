"""Genera gli effetti sonori e le musiche chiptune di Cheap in audio/.

Tutto è sintetizzato qui (onde quadre, triangolari e rumore), quindi i file
sono originali e si possono pubblicare nel repo.

Uso:  python tools/make_audio.py
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")


def square(f, t, duty=0.5):
    return 1.0 if (t * f) % 1.0 < duty else -1.0


def triangle(f, t):
    p = (t * f) % 1.0
    return 4 * p - 1 if p < 0.5 else 3 - 4 * p


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32000)) for s in samples))


def tone(freq, dur, vol=0.3, wave_fn=square, slide=0.0, decay=True):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        f = freq + slide * (i / n)
        env = (1 - i / n) if decay else 1.0
        out.append(wave_fn(f, t) * vol * env)
    return out


def noise(dur, vol=0.3):
    n = int(RATE * dur)
    return [random.uniform(-1, 1) * vol * (1 - i / n) for i in range(n)]


def sfx():
    write("blip.wav", tone(620, 0.03, 0.18))
    write("move.wav", tone(880, 0.04, 0.2))
    write("select.wav", tone(660, 0.05, 0.22) + tone(990, 0.07, 0.22))
    write("deny.wav", tone(180, 0.12, 0.25))
    write("hurt.wav", [a + b for a, b in zip(tone(240, 0.22, 0.3, slide=-160), noise(0.22, 0.2))])
    write("heal.wav", tone(520, 0.08, 0.2, triangle) + tone(780, 0.08, 0.2, triangle) + tone(1040, 0.14, 0.2, triangle))
    write("coin.wav", tone(988, 0.06, 0.22) + tone(1318, 0.16, 0.22))
    write("stamp.wav", [a + b for a, b in zip(noise(0.18, 0.5), tone(90, 0.18, 0.5, slide=-40))])
    write("encounter.wav", tone(440, 0.06, 0.25) + tone(660, 0.06, 0.25) + tone(880, 0.06, 0.25) + tone(1320, 0.18, 0.25))
    write("spare.wav", tone(523, 0.1, 0.2, triangle) + tone(659, 0.1, 0.2, triangle) + tone(784, 0.25, 0.2, triangle))
    write("glitch.wav", [square(random.choice([110, 220, 880, 1760]), i / RATE) * 0.2 for i in range(int(RATE * 0.35))])


NOTES = {n: i for i, n in enumerate(["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"])}


def freq(note):
    if note == "-":
        return 0.0
    name, octave = note[:-1], int(note[-1])
    return 440.0 * 2 ** ((NOTES[name] + 12 * (octave - 4) - 9) / 12)


def track(melody, bass, step, lead_vol=0.13, bass_vol=0.16, duty=0.25, drums=None):
    """melody e bass: liste di note (una per passo). drums: stringa 'k' cassa, 's' rullante, '.' niente."""
    n_step = int(RATE * step)
    total = n_step * len(melody)
    out = [0.0] * total
    for voice, vol, fn in ((melody, lead_vol, lambda f, t: square(f, t, duty)), (bass, bass_vol, triangle)):
        for k, note in enumerate(voice):
            f = freq(note)
            if f == 0:
                continue
            for i in range(n_step):
                env = max(0.0, 1 - i / (n_step * 1.1))
                out[k * n_step + i] += fn(f, i / RATE) * vol * env
    if drums:
        for k, d in enumerate(drums * (len(melody) // len(drums))):
            if d == ".":
                continue
            for i in range(min(n_step, int(RATE * 0.08))):
                env = 1 - i / (RATE * 0.08)
                if d == "k":
                    s = math.sin(2 * math.pi * (80 - 40 * i / RATE * 10) * i / RATE) * 0.35 * env
                else:
                    s = random.uniform(-1, 1) * 0.12 * env
                out[k * n_step + i] += s
    return out


def music():
    # "Quartiere": malinconico, in La minore, lento.
    mel = ("A4 - C5 - E5 - D5 C5 B4 - G4 - A4 - - - "
           "F4 - A4 - C5 - B4 A4 G4 - E4 - G4 - - - "
           "A4 - C5 - E5 - G5 F5 E5 - D5 - C5 - B4 - "
           "A4 - B4 C5 B4 - G4 - A4 - - - - - - - ").split()
    bas = ("A2 - - - A2 - - - G2 - - - G2 - - - "
           "F2 - - - F2 - - - E2 - - - E2 - - - "
           "A2 - - - A2 - - - F2 - - - G2 - - - "
           "A2 - - - E2 - - - A2 - - - - - - - ").split()
    write("music_quartiere.wav", track(mel, bas, 0.24))

    # "Battaglia": veloce, tesa.
    mel = ("E5 E5 - E5 D5 - E5 - G5 - E5 - D5 C5 D5 - "
           "E5 E5 - E5 D5 - E5 - A5 - G5 - E5 - D5 - "
           "C5 C5 - C5 B4 - C5 - E5 - C5 - B4 A4 B4 - "
           "C5 - D5 - E5 - G5 - F5 - E5 - D5 - B4 - ").split()
    bas = ("A2 A3 A2 A3 A2 A3 A2 A3 G2 G3 G2 G3 G2 G3 G2 G3 "
           "F2 F3 F2 F3 F2 F3 F2 F3 E2 E3 E2 E3 E2 E3 E2 E3 "
           "A2 A3 A2 A3 A2 A3 A2 A3 G2 G3 G2 G3 G2 G3 G2 G3 "
           "F2 F3 F2 F3 G2 G3 G2 G3 E2 E3 E2 E3 E2 E3 E2 E3").split()
    write("music_battaglia.wav", track(mel, bas, 0.12, duty=0.125, drums="k.s.k.s."))

    # "Ufficio": monotono, ripetitivo, freddo.
    mel = ("C5 - - - C5 - - - C5 - D5 - C5 - - - "
           "C5 - - - C5 - - - B4 - - - - - - - ").split()
    bas = ("C3 - G2 - C3 - G2 - C3 - G2 - C3 - G2 - "
           "C3 - G2 - C3 - G2 - G2 - D3 - G2 - D3 - ").split()
    write("music_ufficio.wav", track(mel, bas, 0.2, lead_vol=0.08, duty=0.5))


if __name__ == "__main__":
    random.seed(7)
    sfx()
    music()
    print("Audio generato in", os.path.abspath(OUT))
