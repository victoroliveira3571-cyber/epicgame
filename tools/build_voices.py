#!/usr/bin/env python3
"""Copia clipes dos packs de voz do Victor (raw_assets/audio) para assets/audio/voice/<voz>/<categoria>_<n>.(wav|ogg)
e gera scripts/core/VoiceCatalog.gd.
Categorias de diálogo: greet, laugh, angry, sad, ask, yes, no, bye, happy, hurt.
Categorias de combate do herói: attack, attack_big, death, victory, roll, gameover.
Contextos especiais: guard (guarda prende), cast (lança magia).
Cada personagem usa UMA voz (um pack = uma pessoa), para não misturar gente diferente no mesmo personagem.
Uso: python3 tools/build_voices.py"""
import os, re, shutil, glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(os.path.dirname(ROOT), "raw_assets", "audio")
OUT = os.path.join(ROOT, "assets", "audio", "voice")
MAX_PER_CAT = 4
MAX_BY_CAT = {"attack": 9, "attack_big": 6, "hurt": 10, "death": 3, "victory": 2, "roll": 2}


def base(path):
    return os.path.splitext(os.path.basename(path))[0].lower()


def mage_orc(name):
    # sem as falas em inglês (welcome, hello, goodbye, "yes commander", "here yes", thankful, no)
    b = re.sub(r"\d+$", "", base(name))
    return {"amused": "laugh", "laugh": "laugh",
            "irritated": "angry", "angry": "angry", "tired": "sad", "sleep": "sad", "sleepy": "sad",
            "satisfied": "happy", "hit": "hurt", "damaged": "hurt",
            "inquisitive": "ask", "sceptical": "ask", "surprised": "ask"}.get(b)


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


def adventurer(name):
    """RPG Male Adventurer (voz do herói): attack0-8, attackbig0-5, hurt0-9, death, victory, jump, yes, no, greet."""
    b = re.sub(r"\d+$", "", base(name))
    return {"attack": "attack", "attackbig": "attack_big", "hurt": "hurt", "death": "death", "victory": "victory",
            "jump": "roll", "yes": "yes", "no": "no", "greet": "greet", "gameover": "gameover"}.get(b)


def male_protagonist(name):
    """RPG Male Vocal (konakuma): cumprimentos, despedidas, grunhidos. Os JP_* e frases soltas ficam de fora."""
    b = re.sub(r"\s*\d+$", "", base(name))
    if b.startswith(("hello", "hey", "hi", "howdy", "oh hel", "now then")): return "greet"
    if b.startswith(("bye", "good bye", "fair well", "see ya", "see you", "when we next", "another time")): return "bye"
    if b in ("ok", "alrighty then"): return "yes"
    if b.startswith("no"): return "no"
    if b.startswith("thank"): return "happy"
    if b.startswith(("is that so", "what should", "what to")): return "ask"
    if b in ("ouch", "ow", "grunt oof"): return "hurt"
    if b.startswith("hiyah"): return "attack"
    if b.startswith("pained death"): return "death"
    if b in ("grunt gr", "grunt ra", "stupid monster death"): return "angry"
    if b in ("grunt oh", "grunt ehh"): return "ask"
    if b in ("grunt uhuhh", "grunt uoe"): return "sad"
    if b.startswith("jump"): return "roll"
    return None


def female_rpg(name):
    """Female RPG Character voice pack: frases curtas, usadas só onde combinam com o contexto."""
    return {"hello": "greet", "howdareyou": "angry", "colourmeunimpressed": "angry", "whodidthis": "ask",
            "areyouhurt": "ask", "letmehelp": "yes", "stop": "no", "dramaticno": "no", "imsorry": "sad",
            "ihavefailedyou": "sad", "wearealltired": "sad", "oww": "hurt", "gah": "hurt",
            "comeandgetme": "attack", "takeaim": "attack", "fire": "cast", "arrestthosepeople": "guard",
            "helpme": "hurt"}.get(base(name))


VOICES = {
    "mage": ("johncarroll-mage-voice", mage_orc),
    "orc": ("johncarroll-orc-voice", mage_orc),
    "fem_mid": ("witpop-vocal-female-mid", mid),
    "adv": ("brandon-male-adventurer", adventurer),
    "male2": ("konakuma-male-protagonist", male_protagonist),
    "fem_rpg": ("riddles-female-rpg-voice", female_rpg),
}

shutil.rmtree(OUT, ignore_errors=True)
catalog = {}
for vid, (folder, fn) in VOICES.items():
    files = sorted(glob.glob(os.path.join(RAW, folder, "**", "*.wav"), recursive=True)
                   + glob.glob(os.path.join(RAW, folder, "**", "*.ogg"), recursive=True))
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
        cap = MAX_BY_CAT.get(c, MAX_PER_CAT)
        step = max(1, len(lst) // cap)
        for i, f in enumerate(lst[::step][:cap]):
            dest = "%s_%d%s" % (c, i + 1, os.path.splitext(f)[1].lower())
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
