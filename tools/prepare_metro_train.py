"""Bounded painted train textures and original loopable railway sound beds."""
import json
import math
import random
import struct
import wave
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "art/props"


def sound_bed(path, wind):
    rate = 22050
    count = rate * 2
    rng = random.Random(510 if wind else 511)
    low = 0.0
    mid = 0.0
    samples = []
    for index in range(count):
        t = index / rate
        noise = rng.uniform(-1, 1)
        low += (noise - low) * 0.035
        mid += (noise - mid) * 0.24
        if wind:
            value = (mid - low) * (0.65 + 0.12 * math.sin(math.tau * t * 2))
        else:
            # A pair of bogies crosses each rail joint; deep traction hum below it.
            beat = t % 0.4
            clack = math.exp(-beat * 95) + math.exp(-((beat - 0.09) % 0.4) * 105)
            value = low * 1.7 + mid * clack * 0.4
            value += math.sin(math.tau * 53 * t) * 0.075
            value += math.sin(math.tau * 106 * t) * 0.025
        samples.append(value)
    # Crossfade the noise seam without muting the loop at each repetition.
    seam = 256
    for index in range(seam):
        blend = index / seam
        samples[index] = samples[-seam + index] * (1 - blend) + samples[index] * blend
    payload = b"".join(struct.pack("<h", round(max(-1, min(1, v)) * 26000)) for v in samples)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(rate)
        output.writeframes(payload)
    return {"file": path.relative_to(ROOT).as_posix(), "seconds": 2,
            "peak": round(max(abs(v) for v in samples), 4)}


def main():
    report = {"images": [], "sounds": []}
    car = Image.open(ART / "sources/metro-car.png").convert("RGBA")
    if car.getchannel("A").getextrema()[0] != 0:
        raise ValueError("The train must have real alpha")
    car = car.crop(car.getchannel("A").getbbox())
    car.thumbnail((1320, 480), Image.Resampling.LANCZOS)
    target = ROOT / "assets/environment/props/metro-car.png"
    car.save(target, optimize=True)
    report["images"].append({"file": target.relative_to(ROOT).as_posix(), "size": car.size})
    for name in ("metro-station-clear", "metro-train-clear"):
        image = Image.open(ART / "sources" / (name + ".png")).convert("RGB")
        image = image.resize((1280, 720), Image.Resampling.LANCZOS)
        target = ROOT / "assets/environment" / (name + ".webp")
        image.save(target, quality=94, method=6)
        report["images"].append({"file": target.relative_to(ROOT).as_posix(), "size": image.size})
    audio = ROOT / "assets/audio"
    audio.mkdir(exist_ok=True)
    for name, wind in (("metro-rails", False), ("metro-wind", True)):
        report["sounds"].append(sound_bed(audio / (name + ".wav"), wind))
    (ART / "metro-manifest.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report))


if __name__ == "__main__":
    main()
