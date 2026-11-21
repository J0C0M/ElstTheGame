"""Makes every sound effect and music loop of Elst from scratch: no samples,
only oscillators, noise, envelopes and simple filters, so it is all our own
work. Writes OGG files (through ffmpeg) to assets/audio/sfx/ and
assets/audio/music/.

Run from the project root: python3 tools/audio/gen_audio.py [name ...]
A fixed random seed per sound gives the same files every run.
"""
import math
import pathlib
import random
import struct
import subprocess
import sys
import tempfile
import wave

RATE = 22050
OUT = pathlib.Path("assets/audio")
TAU = math.tau


# --- Building blocks ---------------------------------------------------------

def silence(seconds):
    return [0.0] * int(seconds * RATE)


def osc(kind, freq, seconds, phase=0.0, sweep_to=None):
    """An oscillator; with sweep_to the pitch glides there exponentially."""
    n = int(seconds * RATE)
    out = [0.0] * n
    p = phase
    for i in range(n):
        f = freq if sweep_to is None else freq * (sweep_to / freq) ** (i / max(n - 1, 1))
        p += f / RATE
        x = p % 1.0
        if kind == "sine":
            out[i] = math.sin(TAU * x)
        elif kind == "square":
            out[i] = 1.0 if x < 0.5 else -1.0
        elif kind == "pulse":
            out[i] = 1.0 if x < 0.25 else -1.0
        elif kind == "saw":
            out[i] = 2.0 * x - 1.0
        elif kind == "tri":
            out[i] = 4.0 * abs(x - 0.5) - 1.0
    return out


def noise(seconds, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(int(seconds * RATE))]


def env(buf, attack=0.005, decay=0.1, sustain=0.0, release=0.0, hold=None):
    """Attack, decay to sustain, hold (the rest by default) and release."""
    n = len(buf)
    a, d, r = int(attack * RATE), int(decay * RATE), int(release * RATE)
    hold_n = n - a - d - r if hold is None else int(hold * RATE)
    out = []
    for i, v in enumerate(buf):
        if i < a:
            g = i / max(a, 1)
        elif i < a + d:
            g = 1.0 - (1.0 - sustain) * (i - a) / max(d, 1)
        elif i < a + d + hold_n:
            g = sustain
        else:
            g = sustain * max(0.0, 1.0 - (i - a - d - hold_n) / max(r, 1))
        out.append(v * g)
    return out


def lowpass(buf, cutoff, end_cutoff=None):
    out = []
    y = 0.0
    n = len(buf)
    for i, v in enumerate(buf):
        c = cutoff if end_cutoff is None else cutoff * (end_cutoff / cutoff) ** (i / max(n - 1, 1))
        a = 1.0 - math.exp(-TAU * c / RATE)
        y += a * (v - y)
        out.append(y)
    return out


def highpass(buf, cutoff):
    low = lowpass(buf, cutoff)
    return [v - l for v, l in zip(buf, low)]


def mix(*bufs, gains=None):
    n = max(len(b) for b in bufs)
    out = [0.0] * n
    for k, b in enumerate(bufs):
        g = 1.0 if gains is None else gains[k]
        for i, v in enumerate(b):
            out[i] += v * g
    return out


def place(target, buf, at, gain=1.0):
    start = int(at * RATE)
    if start + len(buf) > len(target):
        target.extend([0.0] * (start + len(buf) - len(target)))
    for i, v in enumerate(buf):
        target[start + i] += v * gain
    return target


def tremolo(buf, rate, depth):
    return [v * (1.0 - depth + depth * (0.5 + 0.5 * math.sin(TAU * rate * i / RATE))) for i, v in enumerate(buf)]


def pluck(freq, seconds, rng, damping=0.996):
    """Karplus-Strong: a plucked string, for the crossbow."""
    period = max(int(RATE / freq), 2)
    ring = [rng.uniform(-1, 1) for _ in range(period)]
    out = []
    for i in range(int(seconds * RATE)):
        v = ring[i % period]
        nxt = ring[(i + 1) % period]
        ring[i % period] = damping * 0.5 * (v + nxt)
        out.append(v)
    return out


def normalize(buf, peak=0.85):
    top = max((abs(v) for v in buf), default=1.0) or 1.0
    return [v / top * peak for v in buf]


def fade_edges(buf, seconds=0.01):
    n = min(int(seconds * RATE), len(buf) // 2)
    for i in range(n):
        buf[i] *= i / n
        buf[-1 - i] *= i / n
    return buf


def write(buf, path, quality=3):
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp_path = tmp.name
    with wave.open(tmp_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in buf))
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", tmp_path, "-c:a", "libvorbis", "-q:a", str(quality), str(path)], check=True)
    pathlib.Path(tmp_path).unlink()
    print("wrote", path, f"{len(buf) / RATE:.2f} s")


def whoosh(rng, seconds, low, high, gain=1.0):
    n = noise(seconds, rng)
    band = highpass(lowpass(n, high, low), low * 0.5)
    return [v * gain for v in env(band, attack=seconds * 0.35, decay=seconds * 0.65)]


def clang(freqs, seconds, decay):
    parts = [env(osc("sine", f, seconds), attack=0.001, decay=decay * (1.0 - k * 0.15)) for k, f in enumerate(freqs)]
    return mix(*parts, gains=[1.0 / (k + 1) for k in range(len(parts))])


def thud(freq, seconds, rng, click=0.3):
    body = env(osc("sine", freq, seconds, sweep_to=freq * 0.5), attack=0.002, decay=seconds)
    tap = env(lowpass(noise(seconds, rng), 2500), attack=0.001, decay=seconds * 0.25)
    return mix(body, tap, gains=[1.0, click])


# --- Sound effects -----------------------------------------------------------

def sfx():
    s = {}
    r = lambda seed: random.Random(seed)  # noqa: E731
    s["sword_swing"] = whoosh(r(1), 0.24, 700, 3200)
    s["sword_heavy"] = whoosh(r(2), 0.42, 350, 1800)
    s["hit"] = thud(110, 0.18, r(3), click=0.6)
    s["block"] = mix(clang([820, 1290, 2140], 0.45, 0.35), thud(150, 0.1, r(4)), gains=[0.8, 0.4])
    s["parry"] = mix(clang([1040, 1660, 2490, 3320], 0.7, 0.55), whoosh(r(5), 0.2, 2000, 6000), gains=[0.9, 0.3])
    # A soft, muffled step: mostly a low thump, hardly any hiss.
    s["step"] = mix(env(lowpass(noise(0.1, r(6)), 320), attack=0.006, decay=0.09),
                    env(osc("sine", 75, 0.1, sweep_to=55), attack=0.004, decay=0.09), gains=[0.7, 0.5])
    s["jump"] = env(osc("tri", 180, 0.16, sweep_to=360), attack=0.005, decay=0.15)
    s["land"] = thud(80, 0.16, r(7), click=0.5)
    s["dodge"] = whoosh(r(8), 0.3, 300, 1400, gain=0.8)
    bubbles = silence(0.6)
    rng = r(9)
    for k in range(7):
        place(bubbles, env(osc("sine", rng.uniform(300, 500), 0.07, sweep_to=rng.uniform(700, 900)), attack=0.005, decay=0.06), 0.06 + k * 0.075)
    s["potion"] = bubbles
    s["coin"] = mix(env(osc("square", 1320, 0.25), attack=0.002, decay=0.2), place(silence(0.25), env(osc("square", 1760, 0.18), attack=0.002, decay=0.16), 0.06), gains=[0.35, 0.35])
    arp = silence(0.35)
    for k, f in enumerate((660, 830, 990, 1320)):
        place(arp, env(osc("pulse", f, 0.12), attack=0.002, decay=0.11), k * 0.06, 0.4)
    s["pickup"] = arp
    creak = env(lowpass(tremolo(osc("saw", 90, 0.5, sweep_to=140), 30, 0.6), 1200), attack=0.05, decay=0.45)
    s["chest"] = place(creak, thud(120, 0.2, r(10)), 0.42, 0.8)
    # A wooden door: the latch clicks, the hinge squeaks softly, air moves
    # and it falls shut with a muffled thud.
    door = silence(0.9)
    place(door, env(highpass(noise(0.025, r(11)), 2500), attack=0.001, decay=0.022), 0.0, 0.7)
    hinge = lowpass(tremolo(osc("sine", 540, 0.38, sweep_to=660), 16, 0.5), 2000)
    place(door, env(hinge, attack=0.04, decay=0.34), 0.04, 0.22)
    place(door, whoosh(r(31), 0.4, 200, 900, gain=0.5), 0.1)
    place(door, thud(90, 0.25, r(32), click=0.25), 0.55, 0.8)
    s["door"] = door
    crunch = env(lowpass(noise(0.5, r(12)), 3000, 600), attack=0.002, decay=0.5)
    buzz = env(lowpass(osc("saw", 120, 0.8, sweep_to=40), 800), attack=0.01, decay=0.8)
    s["generator_break"] = mix(crunch, buzz, gains=[0.8, 0.6])
    s["crossbow_shot"] = mix(env(pluck(150, 0.45, r(13), 0.993), attack=0.001, decay=0.45), whoosh(r(14), 0.15, 1500, 5000), gains=[1.0, 0.3])
    clicks = silence(0.4)
    place(clicks, env(highpass(noise(0.03, r(15)), 1500), decay=0.03), 0.05, 0.7)
    place(clicks, env(lowpass(osc("square", 400, 0.05), 2000), decay=0.05), 0.25, 0.5)
    s["crossbow_reload"] = clicks
    s["bolt_impact"] = thud(200, 0.14, r(16), click=0.9)
    s["enemy_hurt"] = env(lowpass(osc("saw", 220, 0.22, sweep_to=150), 1400), attack=0.01, decay=0.2)
    s["enemy_death"] = env(lowpass(tremolo(osc("saw", 200, 0.6, sweep_to=70), 9, 0.4), 1200), attack=0.01, decay=0.6)
    s["vape_puff"] = env(lowpass(noise(0.6, r(17)), 1500, 500), attack=0.15, decay=0.45)
    s["kick"] = thud(140, 0.14, r(18), click=1.0)
    engine = mix(lowpass(osc("saw", 55, 1.2, sweep_to=95), 900), lowpass(osc("square", 56, 1.2, sweep_to=96), 500), gains=[0.6, 0.4])
    s["engine_rev"] = env(tremolo(engine, 18, 0.35), attack=0.08, decay=0.2, sustain=0.8, release=0.25)
    s["shockwave"] = mix(thud(55, 1.0, r(19), click=0.4), env(lowpass(noise(1.0, r(20)), 700, 150), attack=0.005, decay=1.0), gains=[1.0, 0.6])
    roar_noise = lowpass(noise(2.0, r(21)), 1800)
    s["fire_breath"] = env(tremolo(roar_noise, 11, 0.3), attack=0.15, decay=0.1, sustain=0.9, release=0.4)
    roar = mix(lowpass(tremolo(osc("saw", 85, 1.4, sweep_to=60), 7, 0.4), 900), lowpass(noise(1.4, r(22)), 700), gains=[0.8, 0.5])
    s["dragon_roar"] = env(roar, attack=0.1, decay=0.3, sustain=0.7, release=0.6)
    s["wing_flap"] = whoosh(r(23), 0.32, 150, 700, gain=1.0)
    s["meteor"] = mix(thud(60, 0.8, r(24), click=0.6), env(lowpass(noise(0.8, r(25)), 2400, 300), attack=0.003, decay=0.8), gains=[1.0, 0.7])
    s["ui_click"] = env(osc("square", 1800, 0.04), attack=0.001, decay=0.035)
    jingle = silence(1.3)
    for k, (f, t, d) in enumerate(((523, 0.0, 0.15), (659, 0.15, 0.15), (784, 0.3, 0.15), (1047, 0.45, 0.6))):
        place(jingle, env(osc("pulse", f, d + 0.1), attack=0.004, decay=d + 0.08), t, 0.35)
        place(jingle, env(osc("tri", f / 2, d + 0.1), attack=0.004, decay=d + 0.08), t, 0.4)
    s["quest_done"] = jingle
    s["player_death"] = env(lowpass(osc("square", 330, 1.4, sweep_to=80), 1500, 300), attack=0.01, decay=1.4)
    s["bingo"] = mix(clang([660, 990], 0.6, 0.5), place(silence(0.6), clang([880, 1320], 0.5, 0.45), 0.12), gains=[0.6, 0.6])
    # One "syllable" of a voice in dialogue, played for every few letters at
    # the pitch of the speaker.
    s["blip"] = env(lowpass(osc("square", 330, 0.06), 2400), attack=0.003, decay=0.05)
    s["heal"] = mix(*[place(silence(0.6), env(osc("sine", f, 0.3), attack=0.01, decay=0.28), k * 0.08, 0.4) for k, f in enumerate((523, 659, 784, 1047))])
    return {name: normalize(fade_edges(buf), 0.8) for name, buf in s.items()}


def ambience():
    rng = random.Random(30)
    seconds = 8.0
    base = lowpass(noise(seconds, rng), 500)
    gust = lowpass(noise(seconds, rng), 1400)
    n = len(base)
    out = [b * (0.6 + 0.4 * math.sin(TAU * i / n)) + g * 0.35 * (0.5 + 0.5 * math.sin(TAU * 2 * i / n + 1.0)) for i, (b, g) in enumerate(zip(base, gust))]
    # A seamless loop: blend the end into the start.
    blend = int(1.0 * RATE)
    for i in range(blend):
        t = i / blend
        out[i] = out[i] * t + out[n - blend + i] * (1 - t)
    out = out[: n - blend]
    return {"tornado_wind": normalize(out, 0.7)}


# --- Music -------------------------------------------------------------------

NOTE = {"C": 0, "C#": 1, "Db": 1, "D": 2, "D#": 3, "Eb": 3, "E": 4, "F": 5, "F#": 6, "Gb": 6, "G": 7, "G#": 8, "Ab": 8, "A": 9, "A#": 10, "Bb": 10, "B": 11}


def midi(name, octave):
    return 12 * (octave + 1) + NOTE[name]


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def chord_tones(symbol, octave=3):
    minor = symbol.endswith("m")
    root = symbol[:-1] if minor else symbol
    r = midi(root, octave)
    return [r, r + (3 if minor else 4), r + 7]


def song(name, bpm, progression, seed, lead_wave="pulse", bass_wave="tri", style="calm", bars_per_chord=1, repeats=2):
    rng = random.Random(seed)
    beat = 60.0 / bpm
    bar = beat * 4
    chords = progression * repeats
    total = len(chords) * bars_per_chord * bar
    out = silence(total)
    t = 0.0
    melody_scale = []
    for symbol in progression:
        melody_scale += chord_tones(symbol, 4)
    for index, symbol in enumerate(chords):
        tones = chord_tones(symbol, 3)
        for b in range(bars_per_chord):
            bar_start = t + b * bar
            # Bass: root on beats, octave hop for drive.
            steps = 8 if style in ("boss", "tense", "party") else 4
            for k in range(steps):
                note = tones[0] - 12 + (12 if style in ("boss", "party") and k % 2 else 0)
                length = bar / steps
                place(out, env(osc(bass_wave, hz(note), length * 0.95), attack=0.005, decay=length * 0.9), bar_start + k * length, 0.32)
            # Pad: the chord, soft.
            if style in ("calm", "dark", "party"):
                for tone in tones:
                    pad = lowpass(osc("saw", hz(tone), bar), 900 if style != "dark" else 500)
                    place(out, env(pad, attack=bar * 0.25, decay=bar * 0.75, sustain=0.0), bar_start, 0.05)
            # Arpeggio or lead.
            if style == "dark":
                for k in (0, 2):
                    note = tones[(k + index) % 3] + 12
                    place(out, env(osc("sine", hz(note), beat * 1.5), attack=0.02, decay=beat * 1.4), bar_start + k * beat, 0.16)
            else:
                count = 8 if style in ("calm", "party") else 16 if style == "boss" else 8
                length = bar / count
                for k in range(count):
                    if style == "calm" and rng.random() < 0.25:
                        continue
                    pool = tones if rng.random() < 0.7 else melody_scale
                    note = rng.choice(pool) + 12 + (12 if style == "party" and k % 4 == 0 else 0)
                    place(out, env(osc(lead_wave, hz(note), length * 0.9), attack=0.003, decay=length * 0.85), bar_start + k * length, 0.13)
            # Drums: kick, snare (noise) and hats.
            if style != "dark":
                for k in range(4):
                    if style != "calm" or k % 2 == 0:
                        place(out, thud(70, 0.16, rng, click=0.2), bar_start + k * beat, 0.45)
                    if k % 2 == 1:
                        place(out, env(highpass(noise(0.14, rng), 900), attack=0.001, decay=0.12), bar_start + k * beat, 0.22)
                hats = 8 if style in ("calm", "party") else 16
                for k in range(hats):
                    place(out, env(highpass(noise(0.03, rng), 5000), decay=0.025), bar_start + k * bar / hats, 0.08)
            else:
                place(out, thud(45, 0.6, rng, click=0.1), bar_start, 0.4)
        t += bars_per_chord * bar
    out = out[: int(total * RATE)]
    return normalize(out, 0.75)


def music():
    return {
        "village": song("village", 92, ["C", "G", "Am", "F"], 41, style="calm", bars_per_chord=2),
        "occupied": song("occupied", 104, ["Am", "F", "Dm", "E"], 42, lead_wave="square", style="tense", bars_per_chord=2),
        "dungeon": song("dungeon", 76, ["Dm", "Bb", "Gm", "A"], 43, style="dark", bars_per_chord=2),
        "boss": song("boss", 152, ["Em", "C", "D", "B"], 44, lead_wave="square", bass_wave="saw", style="boss", bars_per_chord=2),
        "ending": song("ending", 116, ["F", "C", "Dm", "Bb"], 45, style="party", bars_per_chord=2),
    }


def main():
    wanted = set(sys.argv[1:])
    for name, buf in {**sfx(), **ambience()}.items():
        if not wanted or name in wanted:
            write(buf, OUT / "sfx" / f"{name}.ogg")
    for name, buf in music().items():
        if not wanted or name in wanted:
            write(buf, OUT / "music" / f"{name}.ogg", quality=2)


if __name__ == "__main__":
    main()
