"""Crop generated parts and eye donors. No painting or alpha replacement."""
from collections import deque
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / 'art/characters/los'
OUT = ROOT / 'assets/characters/los'
manifest = {}


def trim_part(name, source):
    im = Image.open(source).convert('RGBA')
    bounds = im.getchannel('A').point(lambda a: 255 if a > 24 else 0).getbbox()
    box = (max(0, bounds[0]-3), max(0, bounds[1]-3),
           min(im.width, bounds[2]+3), min(im.height, bounds[3]+3))
    im = im.crop(box)
    im.thumbnail((512, 512), Image.Resampling.LANCZOS)
    im.save(OUT / f'{name}.png')
    manifest[name] = {'source': str(source.relative_to(ROOT)), 'crop': box, 'size': im.size}
    print(name, im.size)


trim_part('neck', ART / 'neck-v3.png')
trim_part('pelvis', ART / 'pelvis-v3.png')
if (ART / 'torso-v3.png').exists():
    trim_part('torso', ART / 'torso-v3.png')
# The original atlas fist cell has a disconnected tuft from the head above it.
# Find the fist's component and crop its rectangle, preserving all RGBA inside it.
atlas = Image.open(ART / 'atlas-v1.png').convert('RGBA')
cell = (1024, 341, 1536, 682)
fist = atlas.crop(cell)
alpha = fist.getchannel('A')
points = {(x, y) for y in range(fist.height) for x in range(fist.width) if alpha.getpixel((x, y)) > 64}
components = []
while points:
    first = points.pop()
    queue = deque([first])
    component = [first]
    while queue:
        x, y = queue.popleft()
        for neighbour in ((x-1, y), (x+1, y), (x, y-1), (x, y+1)):
            if neighbour in points:
                points.remove(neighbour)
                component.append(neighbour)
                queue.append(neighbour)
    components.append(component)
main = max(components, key=len)
xs, ys = zip(*main)
box = (max(0, min(xs)-4), max(0, min(ys)-4),
       min(fist.width, max(xs)+5), min(fist.height, max(ys)+5))
fist = fist.crop(box)
fist.save(OUT / 'fist.png')
manifest['fist'] = {'source': 'art/characters/los/atlas-v1.png', 'cell': cell,
                    'crop': box, 'size': fist.size}
print('fist', fist.size, box)
head = Image.open(ART / 'head-forward-v3.png')
for name, box in [('eye_near_forward', (835, 480, 976, 550)),
                  ('eye_far_forward', (995, 479, 1072, 533))]:
    head.crop(box).save(OUT / f'{name}.png')
    manifest[name] = {'source': 'art/characters/los/head-forward-v3.png', 'crop': box}
(OUT / 'parts_v3_manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
