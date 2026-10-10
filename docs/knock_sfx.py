"""Toc-toc à la porte (amulette « La Porte ») à partir d'un vrai enregistrement
(docs/knock_source.mp3 : 3 coups sur une porte, Pixabay). On découpe les 3 coups, on recompose
plusieurs rythmes (légères variations de force et de hauteur), on baisse le volume (une porte un
peu au loin, rien de saturé) et on place le son en 3D au casque (binaural : retard et atténuation
entre les deux oreilles, l'oreille la plus loin entend plus sourd).
Sortie : assets/sfx/knock_1.ogg ... knock_N.ogg (ffmpeg pour décoder et encoder).
python docs/knock_sfx.py
"""
import os
import subprocess
import numpy as np
from scipy.signal import butter, lfilter, resample
from scipy.io import wavfile

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(HERE, "knock_source.mp3")
OUT = os.path.join(ROOT, "assets", "sfx")
PEAK_DB = -12.0   # crête finale : léger, jamais cramé
rng = np.random.default_rng(11)


def lowpass(x, f):
    b, a = butter(2, f / (SR / 2), "low")
    return lfilter(b, a, x)


def load():
    tmp = os.path.join(OUT, "_src.wav")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", SRC, "-ac", "1", "-ar", str(SR), tmp], check=True)
    sr, x = wavfile.read(tmp)
    os.remove(tmp)
    return x.astype(float) / 32768.0


def hits(x):
    """Découpe les coups : chaque attaque (enveloppe qui monte d'un coup) jusqu'à la suivante."""
    env = np.convolve(np.abs(x), np.ones(220) / 220, "same")
    th = env.max() * 0.25
    starts = []
    i = 0
    while i < len(env):
        if env[i] > th:
            starts.append(max(0, i - int(SR * 0.004)))
            i += int(SR * 0.15)   # (pas deux attaques à moins de 150 ms)
        else:
            i += 1
    out = []
    for k, s in enumerate(starts):
        e = starts[k + 1] if k + 1 < len(starts) else len(x)
        h = x[s:e].copy()
        fade = min(len(h), int(SR * 0.02))
        h[-fade:] *= np.linspace(1, 0, fade)
        out.append(h)
    return out


def vary(h, strength):
    """Le même coup, un poil plus fort/faible et plus aigu/grave."""
    f = rng.uniform(0.96, 1.04)
    h = resample(h, int(len(h) / f))
    return h * strength


def binaural(x, angle):
    """Place le son à un angle (radians, 0 = devant, + = à droite, pi = derrière)."""
    s = np.sin(angle)
    itd = int(abs(s) * 0.00066 * SR)
    near = x
    far = np.concatenate([np.zeros(itd), x])[: len(x)]
    far = lowpass(far, 1800 + 6000 * (1 - abs(s))) * (1 - 0.55 * abs(s))   # l'ombre de la tête
    if np.cos(angle) < 0:   # derrière : un peu plus sourd des deux côtés
        near = lowpass(near, 5000)
        far = lowpass(far, 3500)
    return (far, near) if s >= 0 else (near, far)


# Rythmes : (instant en s, force)
PATTERNS = [
    [(0.0, 1.0), (0.24, 0.9)],                               # toc toc
    [(0.0, 1.0), (0.24, 0.85), (0.48, 0.95)],                # toc toc toc
    [(0.0, 0.9), (0.22, 0.8), (0.44, 0.85), (1.0, 1.0)],     # toc toc toc... toc
    [(0.0, 1.0), (0.2, 0.9), (0.75, 1.0), (0.95, 0.95)],     # toc toc... toc toc
    [(0.0, 0.7), (0.26, 0.8), (0.52, 1.0)],                  # qui monte
]
# Où se trouve la porte : derrière à droite, à gauche, derrière, à droite, derrière à gauche
ANGLES = [2.3, -1.6, 3.05, 1.5, -2.4]


def make(hs, pattern, angle):
    total = int(SR * (pattern[-1][0] + 0.5))
    mono = np.zeros(total)
    for k, (at, st) in enumerate(pattern):
        h = vary(hs[k % len(hs)], st)
        i = int(at * SR)
        n = min(len(h), total - i)
        mono[i:i + n] += h[:n]
    l, r = binaural(mono, angle)
    st = np.stack([l, r], axis=1)
    st *= (10 ** (PEAK_DB / 20)) / np.max(np.abs(st))
    tail = int(SR * 0.05)
    st[-tail:] *= np.linspace(1, 0, tail)[:, None]
    return st


def main():
    os.makedirs(OUT, exist_ok=True)
    hs = hits(load())
    print("%d coups trouvés" % len(hs))
    for i, (p, a) in enumerate(zip(PATTERNS, ANGLES), start=1):
        st = make(hs, p, a)
        wav = os.path.join(OUT, "knock_%d.wav" % i)
        wavfile.write(wav, SR, (st * 32767).astype(np.int16))
        ogg = os.path.join(OUT, "knock_%d.ogg" % i)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "6", ogg], check=True)
        os.remove(wav)
        print(ogg)


if __name__ == "__main__":
    main()
