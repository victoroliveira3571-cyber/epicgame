"""Sons PROVISÓRIOS de ambiente do Pomodoro, sintetizados (sem licença de terceiros).

Gera assets/audio/pomodoro/ambiente/<id>.wav (loops sem emenda) e fx_<evento>.wav.
Quando o Victor enviar os sons dele, basta salvar como <id>.mp3 na mesma pasta: o jogo
prefere o .mp3 e ignora o .wav (ver scripts/core/PomoSound.gd).

Uso (da pasta game/):  python3 tools/gen_pomodoro_sfx.py
"""
import os, wave
import numpy as np

SR = 22050
OUT = "assets/audio/pomodoro/ambiente/"
rng = np.random.default_rng(7)


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def fft_band(x, lo, hi):
    """Filtro passa-faixa pela FFT (rápido para ruído longo)."""
    f = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / SR)
    mask = ((freqs >= lo) & (freqs <= hi)).astype(float)
    # bordas suaves
    soft = np.exp(-((np.clip(lo - freqs, 0, None) / (lo * 0.3 + 1)) ** 2)) * np.exp(-((np.clip(freqs - hi, 0, None) / (hi * 0.3 + 1)) ** 2))
    return np.fft.irfft(f * np.maximum(mask, soft), len(x))


def env(n, attack, decay):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(attack, 1e-4)) * np.exp(-t / max(decay, 1e-4))
    return e


def loopify(x, fade_s=1.0):
    """Faz o fim emendar no começo (crossfade)."""
    f = int(fade_s * SR)
    head, body, tail = x[:f], x[f:-f], x[-f:]
    w = np.linspace(0, 1, f)
    return np.concatenate([tail * (1 - w) + head * w, body])


def norm(x, peak=0.7):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def loud(x, rms=0.08):
    """Sobe o volume médio (sons de estalos têm pico alto e média baixa) com limite suave."""
    x = x / (np.sqrt(np.mean(x ** 2)) or 1.0) * rms
    return np.tanh(x * 1.6) / 1.6


def save(name, x):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype("<i2")
    with wave.open(OUT + name + ".wav", "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    print(f"{name}.wav  {len(x) / SR:.1f}s")


def place(buf, snd, at):
    end = min(len(buf), at + len(snd))
    buf[at:end] += snd[: end - at]


# ------------------------------------------------------------------ peças
def crackle(n):
    """Estalo de lenha."""
    s = rng.normal(0, 1, n) * env(n, 0.0005, 0.004 + rng.random() * 0.01)
    return fft_band(s, 800, 6000) * (0.4 + rng.random())


def clink(freq=2600.0, dur=0.9, amp=0.5):
    n = int(dur * SR)
    t = np.arange(n) / SR
    parts = [(1.0, 1.0), (2.76, 0.5), (5.4, 0.25), (8.9, 0.12)]
    s = sum(a * np.sin(2 * np.pi * freq * k * t) * np.exp(-t * (6 + k * 3)) for k, a in parts)
    s += rng.normal(0, 0.3, n) * env(n, 0.0002, 0.003)
    return s * amp


def page(dur=0.45):
    n = int(dur * SR)
    t = np.arange(n) / SR
    s = rng.normal(0, 1, n)
    s = fft_band(s, 1500, 9000)
    e = np.sin(np.pi * np.clip(t / dur, 0, 1)) ** 1.5 * (0.6 + 0.4 * np.sin(2 * np.pi * 14 * t) ** 2)
    return s * e


def scratch(dur):
    n = int(dur * SR)
    s = fft_band(rng.normal(0, 1, n), 2500, 8000)
    t = np.arange(n) / SR
    strokes = 0.5 + 0.5 * np.sin(2 * np.pi * (5 + 2 * np.sin(t * 3)) * t)
    return s * strokes * np.sin(np.pi * t / dur)


def chirp(f0, f1, dur, amp=0.3):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = np.linspace(f0, f1, n) + 300 * np.sin(2 * np.pi * 30 * t)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * np.sin(np.pi * t / dur) ** 2 * amp


# ------------------------------------------------------------------ loops
def fire(seconds=16, crackles=5.0):
    n = int((seconds + 1) * SR)
    base = fft_band(rng.normal(0, 1, n), 40, 400) * 0.6
    base *= 0.75 + 0.25 * np.sin(2 * np.pi * 0.21 * np.arange(n) / SR)
    for _ in range(int(seconds * crackles)):
        place(base, crackle(int(0.04 * SR)) * 2.2, rng.integers(0, n - 2000))
    return norm(loopify(base), 0.6)


def rain(seconds=16):
    n = int((seconds + 1) * SR)
    x = fft_band(rng.normal(0, 1, n), 300, 7000) * 0.5
    x += fft_band(rng.normal(0, 1, n), 60, 300) * 0.4
    for _ in range(seconds * 30):
        d = crackle(int(0.01 * SR)) * 0.5
        place(x, d, rng.integers(0, n - 300))
    return norm(loopify(x), 0.55)


def wind(seconds=20):
    n = int((seconds + 1) * SR)
    t = np.arange(n) / SR
    x = fft_band(rng.normal(0, 1, n), 80, 900)
    gust = 0.45 + 0.35 * np.sin(2 * np.pi * t / 7.0) + 0.2 * np.sin(2 * np.pi * t / 3.1 + 1)
    return norm(loopify(x * gust), 0.5)


def water(seconds=16):
    n = int((seconds + 1) * SR)
    x = fft_band(rng.normal(0, 1, n), 200, 2500) * 0.3
    for _ in range(seconds * 14):
        dur = 0.03 + rng.random() * 0.05
        m = int(dur * SR)
        t = np.arange(m) / SR
        f0 = 500 + rng.random() * 900
        bub = np.sin(2 * np.pi * (f0 + 2000 * t) * t) * np.exp(-t * 60) * 0.25
        place(x, bub, rng.integers(0, n - m))
    return norm(loopify(x), 0.5)


def birds(seconds=20):
    n = int((seconds + 1) * SR)
    x = fft_band(rng.normal(0, 1, n), 200, 1200) * 0.03
    at = 0
    while at < n - SR:
        f0 = 2600 + rng.random() * 1800
        for k in range(rng.integers(2, 6)):
            c = chirp(f0, f0 + rng.choice([-900, 700, 1200]), 0.07 + rng.random() * 0.05, 0.25)
            place(x, c, at + k * int(0.11 * SR))
        at += int((0.8 + rng.random() * 2.2) * SR)
    return norm(loopify(x, 0.5), 0.5)


def cups(seconds=20):
    n = int((seconds + 1) * SR)
    x = fft_band(rng.normal(0, 1, n), 100, 500) * 0.04       # sala
    at = int(0.5 * SR)
    while at < n - SR:
        if rng.random() < 0.6:
            place(x, clink(2200 + rng.random() * 1800, 0.6, 0.25 + rng.random() * 0.2), at)
        else:   # talher no prato
            place(x, clink(4200 + rng.random() * 1500, 0.25, 0.15), at)
        at += int((0.9 + rng.random() * 2.8) * SR)
    return norm(loopify(x, 0.5), 0.5)


def pages(seconds=24):
    n = int((seconds + 1) * SR)
    x = fft_band(rng.normal(0, 1, n), 100, 400) * 0.02
    at = int(1.0 * SR)
    while at < n - SR:
        place(x, page(0.35 + rng.random() * 0.2) * 0.5, at)
        at += int((3.0 + rng.random() * 5.0) * SR)
    return norm(loopify(x, 0.5), 0.5)


def writing(seconds=20):
    n = int((seconds + 1) * SR)
    x = np.zeros(n)
    at = int(0.3 * SR)
    while at < n - 2 * SR:
        d = 0.6 + rng.random() * 1.4
        place(x, scratch(d) * 0.4, at)
        at += int((d + 0.3 + rng.random() * 1.2) * SR)
    return norm(loopify(x, 0.5), 0.45)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    save("lareira", loud(fire(16, 5.0), 0.09))
    save("fogueira", loud(fire(16, 9.0), 0.09))
    save("chuva", rain(16))
    save("vento", wind(20))
    save("agua", water(16))
    save("passaros", birds(20))
    save("copos", loud(cups(20), 0.07))
    save("paginas", loud(pages(24), 0.07))
    save("escrita", loud(writing(20), 0.09))
    # eventos curtos das ações do herói
    cup = clink(2400, 0.7, 0.6)
    place(cup, clink(1800, 0.4, 0.2), int(0.05 * SR))
    save("fx_xicara", norm(cup, 0.6))
    save("fx_pagina", norm(page(0.45), 0.55))
    t = np.arange(int(0.25 * SR)) / SR
    thud = np.sin(2 * np.pi * 140 * t) * np.exp(-t * 30) + fft_band(rng.normal(0, 1, len(t)), 200, 2000) * np.exp(-t * 50) * 0.5
    save("fx_livro", norm(thud, 0.55))
    g = np.arange(int(0.5 * SR)) / SR
    gulp = np.sin(2 * np.pi * (300 + 500 * np.exp(-g * 12)) * g) * np.exp(-((g - 0.12) / 0.06) ** 2) * 0.6
    save("fx_gole", norm(gulp + fft_band(rng.normal(0, 1, len(g)), 300, 1500) * np.exp(-((g - 0.12) / 0.05) ** 2) * 0.2, 0.4))
