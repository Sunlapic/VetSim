#!/usr/bin/env python3
"""Превью шкал ожидания (пакет №334) — капсула из явных кругов, как в игре."""
import math
from PIL import Image, ImageDraw, ImageFont

S = 5
W_BAR, H_BAR = 56, 6
OUTLINE = (18, 16, 14)

PAL = {
    'оплата': (240, 168, 32),
    'регистратура': (64, 184, 232),
    'приём': (92, 204, 116),
    'манипуляции': (170, 122, 232),
    'стационар': (242, 122, 164),
    'мало терпения': (232, 64, 64),
    'прочее': (176, 186, 196),
}

def lighter(c, a): return tuple(min(255, v + a) for v in c)
def darker(c, a): return tuple(max(0, v - a) for v in c)

def capsule_fill(d, x1, y1, x2, y2, color, alpha):
    h = y2 - y1
    r = h / 2
    cy = (y1 + y2) / 2
    lx, rx = x1 + r, x2 - r
    if rx < lx:
        d.ellipse((x1, y1, x2, y2), fill=color + (int(alpha * 255),))
        return
    d.ellipse((lx - r, cy - r, lx + r, cy + r), fill=color + (int(alpha * 255),))
    d.ellipse((rx - r, cy - r, rx + r, cy + r), fill=color + (int(alpha * 255),))
    d.rectangle((lx, y1, rx, y2), fill=color + (int(alpha * 255),))

def ring_poly(d, cx, cy, r1, r2, a1, a2, col):
    # №339: как в игре — полукольцо из залитых кругов-«точек».
    rm = (r1 + r2) / 2
    dot = (r2 - r1) / 2 + 0.45 * S
    for i in range(15):
        a = math.radians(a1 + (a2 - a1) * i / 14)
        x = cx + rm * math.cos(a)
        y = cy - rm * math.sin(a)
        d.ellipse((x - dot, y - dot, x + dot, y + dot), fill=col)

def capsule_band(d, x1, y1, x2, y2, o1, o2, col):
    # №338: ЗАЛИТАЯ лента (прямоугольники + полукольца).
    h = y2 - y1
    ri = h / 2
    cy = (y1 + y2) / 2
    lx, rx = x1 + ri, x2 - ri
    if rx <= lx:
        ring_poly(d, lx, cy, ri + o1 - S, ri + o2, 90, 270, col)
        ring_poly(d, rx, cy, ri + o1 - S, ri + o2, 270, 450, col)
        return
    d.rectangle((lx, y1 - o2, rx, y1 - o1), fill=col)
    d.rectangle((lx, y2 + o1, rx, y2 + o2), fill=col)
    ring_poly(d, lx, cy, ri + o1 - S, ri + o2, 90, 270, col)
    ring_poly(d, rx, cy, ri + o1 - S, ri + o2, 270, 450, col)

def capsule_outline(d, x1, y1, x2, y2, t):
    capsule_band(d, x1, y1, x2, y2, S, t * S, OUTLINE + (255,))

def fill_box(x, y, h, ratio):
    # №337: без отступа — цвет впритык к постоянному контуру.
    if ratio <= 0.015: return None
    w = W_BAR * S * ratio
    if w < 2 * S: w = 2 * S
    return (x, y, x + w, y + h)

def shaded(d, b, color):
    x1, y1, x2, y2 = b
    h = y2 - y1
    r = h / 2
    capsule_fill(d, x1, y1, x2, y2, color, 1)
    capsule_fill(d, x1 + r * 0.3, y1, x2 - r * 0.3, y1 + h * 0.5, lighter(color, 70), 0.45)
    capsule_fill(d, x1 + r * 0.3, y2 - h * 0.34, x2 - r * 0.3, y2, darker(color, 70), 0.35)

def capsule(img, x, y, ratio, color):
    d = ImageDraw.Draw(img, 'RGBA')
    b = fill_box(x, y, H_BAR * S, ratio)
    if b:
        shaded(d, b, color)
        d.line((b[0] + 2 * S, b[1] + 1 * S, b[2] - 2 * S, b[1] + 1 * S), fill=(255, 255, 255, 82), width=S)
    capsule_outline(d, x, y, x + W_BAR * S, y + H_BAR * S, 2)

def glass(img, x, y, ratio, color):
    d = ImageDraw.Draw(img, 'RGBA')
    b = fill_box(x, y, H_BAR * S, ratio)
    if b:
        shaded(d, b, color)
        d.ellipse((b[0] + 2 * S, b[1] + 0.5 * S, b[2] - 2 * S, b[1] + (b[3] - b[1]) * 0.55), fill=(255, 255, 255, 107))
    capsule_outline(d, x, y, x + W_BAR * S, y + H_BAR * S, 2)

def segmented(img, x, y, ratio, color):
    d = ImageDraw.Draw(img, 'RGBA')
    b = fill_box(x, y, H_BAR * S, ratio)
    if b:
        shaded(d, b, color)
        for i in range(1, 10):
            lx = x + W_BAR * S * i * 0.1
            if b[0] + 2 * S < lx < b[2] - 2 * S:
                d.rectangle((lx, b[1] + 1 * S, lx + 1 * S, b[3] - 1 * S), fill=(18, 16, 14, 191))
    capsule_outline(d, x, y, x + W_BAR * S, y + H_BAR * S, 2)

def neon(img, x, y, ratio, color):
    d = ImageDraw.Draw(img, 'RGBA')
    b = fill_box(x, y, H_BAR * S, ratio)
    if b:
        capsule_fill(d, *b, color, 1)
        h = b[3] - b[1]
        r = h / 2
        cy = (b[1] + b[3]) / 2
        lx, rx = b[0] + r, b[2] - r
        if rx < lx: rx = lx
        capsule_band(d, b[0], b[1], b[2], b[3], S, 4 * S, color + (28,))
        capsule_band(d, b[0], b[1], b[2], b[3], S, 2 * S, color + (52,))
        capsule_fill(d, b[0] + 1 * S, b[1] + 1.5 * S, b[2] - 1 * S, b[3] - 1.5 * S, (255, 255, 255), 0.5)
    capsule_outline(d, x, y, x + W_BAR * S, y + H_BAR * S, 2)

def metal(img, x, y, ratio, color):
    d = ImageDraw.Draw(img, 'RGBA')
    b = fill_box(x, y, H_BAR * S, ratio)
    if b:
        h = b[3] - b[1]
        r = h / 2
        capsule_fill(d, *b, color, 1)
        d.line((b[0] + r * 0.5, b[1] + 1 * S, b[2] - r * 0.5, b[1] + 1 * S), fill=lighter(color, 90) + (153,), width=S)
        d.line((b[0] + r * 0.5, b[3] - 1 * S, b[2] - r * 0.5, b[3] - 1 * S), fill=darker(color, 80) + (128,), width=S)
    capsule_outline(d, x, y, x + W_BAR * S, y + H_BAR * S, 2)

def line(img, x, y, ratio, color):
    d = ImageDraw.Draw(img, 'RGBA')
    cy = y + H_BAR * S / 2
    t1, t2 = cy - 1.5 * S, cy + 1.5 * S
    w = W_BAR * S * ratio
    if ratio > 0.015:
        if w < 2 * S: w = 2 * S
        b = (x, t1, x + w, t2)
        capsule_fill(d, *b, color, 1)
        if 0.02 < ratio < 0.99:
            d.rectangle((b[2] - 0.5 * S, t1 - 1 * S, b[2] + 0.5 * S, t2 + 1 * S), fill=(255, 255, 255, 217))
    capsule_outline(d, x, t1, x + W_BAR * S, t2, 2)

STYLES = [('1. КАПСУЛА', capsule), ('2. СТЕКЛО', glass), ('3. СЕГМЕНТЫ', segmented),
          ('4. НЕОН', neon), ('5. МЕТАЛЛ', metal), ('6. ЛИНИЯ', line)]

font_big = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', 22)
font_small = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', 17)

ROW_H = 130
img = Image.new('RGB', (1000, ROW_H * 6 + 40), (32, 34, 40))
d = ImageDraw.Draw(img)
d.rectangle((620, 0, 1000, img.size[1]), fill=(214, 205, 186))
d.text((24, 8), 'ПАКЕТ №339 · ТОРЦЫ — КОЛЬЦА ИЗ ЗАЛИТЫХ КРУГОВ · сплошная обводка', font=font_small, fill=(150, 155, 165))

for i, (name, fn) in enumerate(STYLES):
    y0 = 40 + i * ROW_H
    ratio = 1 - i * 0.16
    color = list(PAL.values())[i]
    x = 560 - (W_BAR * S) // 2
    y = y0 + 40
    fn(img, x, y, ratio, color)
    d = ImageDraw.Draw(img)
    d.text((24, y0 + 14), name, font=font_big, fill=(240, 240, 245))
    d.text((24, y0 + 44), f'{int(ratio * 100)}% · WAIT_BAR_STYLE = {i + 1}', font=font_small, fill=(160, 165, 175))
    key = list(PAL.keys())[i]
    d.rectangle((24, y0 + 74, 44, y0 + 94), fill=color, outline=(20, 20, 20))
    d.text((52, y0 + 74), key, font=font_small, fill=(225, 225, 230))

img.save('/home/user/VetSim/00_LATEST_339_kolca_iz_krugov/PREVIEW_STYLES.png')
print('PREVIEW_STYLES.png', img.size)

img2 = Image.new('RGB', (1000, 60 * 7 + 60), (32, 34, 40))
d2 = ImageDraw.Draw(img2)
d2.rectangle((700, 0, 1000, img2.size[1]), fill=(214, 205, 186))
d2.text((24, 10), 'ЦВЕТ ПО ПРИЧИНЕ ОЖИДАНИЯ · стиль 2 «СТЕКЛО» (выбран)', font=font_small, fill=(150, 155, 165))
for i, (key, c) in enumerate(PAL.items()):
    y = 48 + i * 60
    glass(img2, 560 - (W_BAR * S) // 2, y, 0.8, c)
    d2 = ImageDraw.Draw(img2)
    d2.text((24, y - 14), key.upper(), font=font_big, fill=(240, 240, 245))
img2.save('/home/user/VetSim/00_LATEST_339_kolca_iz_krugov/PREVIEW_COLORS.png')
print('PREVIEW_COLORS.png', img2.size)
