#!/usr/bin/env python3
"""Copia clipes dos packs de voz do Victor (raw_assets/audio) para assets/audio/voice/<voz>/<categoria>_<n>.wav
e gera scripts/core/VoiceCatalog.gd. Categorias: greet, laugh, angry, sad, ask, yes, no, bye, happy, hurt.
Uso: python3 tools/build_voices.py"""
import os, re, shutil, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(os.path.dirname(ROOT), "raw_assets", "audio")
OUT = os.path.join(ROOT, "assets", "audio", "voice")
MAX_PER_CAT = 4


def base(path):
    return os.path.splitext(os.path.basename(path))[0].lower()


def mage_orc(name):
    b = re.sub(r"\d+$", "", base(name))
    return {"welcome": "greet", "hello": "greet", "hereyes": "greet", "amused": "laugh", "laugh": "laugh",
            "irritated": "angry", "angry": "angry", "tired": "sad", "sleep": "sad", "sleepy": "sad",
            "satisfied": "happy", "thankful": "happy", "yescommand": "yes", "hit": "hurt", "damaged": "hurt",
            "inquisitive": "ask", "sceptical": "ask", "surprised": "ask", "no": "no", "goodbye": "bye"}.get(b)


def bright(name):
    b = base(name)
    t = re.sub(r"^\d+-", "", b)
    if any(k in t for k in ["hello", "hey", "good morning", "good afternoon", "good evening"]): return "greet"
    if "laughter" in t: return "laugh"
    if t in ("why", "what", "actually") or "how are you" in t or "is this what" in t: return "ask"
    if t in ("okay",) or "thank you" in t or "good thank" in t: return "yes"
    if "goodbye" in t or "see ya" in t: return "bye"
    if "rejection" in t or "don't wanna" in t or "feel the same" in t: return "no"
    if "love you" in t or "under the weather" in t: return "sad"
    return None


def mid(name):
    n = int(re.match(r"(\d+)", base(name)).group(1))
    for rng, cat in [((1, 5), "greet"), ((57, 59), "laugh"), ((39, 43), "ask"), ((35, 36), "ask"),
                     ((20, 23), "yes"), ((16, 17), "yes"), ((6, 6), "happy"), ((45, 45), "happy"), ((49, 50), "happy"),
                     ((24, 25), "no"), ((10, 10), "no"), ((7, 7), "no"), ((30, 31), "no"),
                     ((32, 34), "bye"), ((51, 55), "angry"), ((26, 29), "angry"),
                     ((11, 15), "sad"), ((56, 56), "hurt")]:
        if rng[0] <= n <= rng[1]:
            return cat
    return None


def male(name):
    b = base(name)
    m = re.match(r"gmorkh-simpledialogue - \d+ - (\w+) - (.*)", b)
    if not m:
        return None
    grp, rest = m.group(1), m.group(2)
    if grp == "greetings": return "ask" if rest.startswith("hmm") else "greet"
    if grp == "confirmation": return "yes"
    if grp == "refusal": return "no"
    if grp == "farewell": return "bye"
    if grp == "completion": return "happy"
    if grp == "miscellaneous":
        if rest.startswith(("hmm", "uh")): return "ask"
        if rest.startswith(("woo", "wow", "new high")): return "happy"
        if rest.startswith(("game over", "low on")): return "sad"
        if rest.startswith(("we're under", "enemy")): return "angry"
    return None


VOICES = {
    "mage": ("johncarroll-mage-voice", mage_orc),
    "orc": ("johncarroll-orc-voice", mage_orc),
    "fem_bright": ("cicifyre-voice-clips-bright-female", bright),
    "fem_mid": ("witpop-vocal-female-mid", mid),
    "male": ("gmorkh-simple-dialogue-voice", male),
}

shutil.rmtree(OUT, ignore_errors=True)
catalog = {}
for vid, (folder, fn) in VOICES.items():
    files = sorted(glob.glob(os.path.join(RAW, folder, "**", "*.wav"), recursive=True))
    cats = {}
    for f in files:
        try:
            c = fn(f)
        except Exception:
            c = None
        if c:
            cats.setdefault(c, []).append(f)
    os.makedirs(os.path.join(OUT, vid), exist_ok=True)
    catalog[vid] = {}
    for c, lst in sorted(cats.items()):
        step = max(1, len(lst) // MAX_PER_CAT)
        for i, f in enumerate(lst[::step][:MAX_PER_CAT]):
            dest = "%s_%d.wav" % (c, i + 1)
            shutil.copy(f, os.path.join(OUT, vid, dest))
            catalog[vid].setdefault(c, []).append("res://assets/audio/voice/%s/%s" % (vid, dest))
    print(vid, {c: len(v) for c, v in catalog[vid].items()})

lines = ["# Gerado por tools/build_voices.py. Não edite à mão.", "class_name VoiceCatalog", "", "const CLIPS := {"]
for vid, cats in catalog.items():
    lines.append('\t"%s": {' % vid)
    for c, paths in cats.items():
        lines.append('\t\t"%s": [%s],' % (c, ", ".join('"%s"' % p for p in paths)))
    lines.append("\t},")
lines.append("}")
open(os.path.join(ROOT, "scripts", "core", "VoiceCatalog.gd"), "w").write("\n".join(lines) + "\n")
