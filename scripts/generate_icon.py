#!/usr/bin/env python3
"""Generate Refraction app icons programmatically.

Creates a prism/light-diffraction icon at all required macOS sizes.
Uses Core Graphics via Python's Pillow library (if available) or
outputs a simple SVG that can be converted.

Usage:
    python3 scripts/generate_icon.py
"""
import math
import os
import struct
import zlib

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
ICON_DIR = os.path.join(
    PROJECT_ROOT,
    "RefractionApp", "Refraction", "Assets.xcassets",
    "AppIcon.appiconset"
)

# macOS icon sizes: (points, scale, pixel_size)
SIZES = [
    (16, 1, 16),
    (16, 2, 32),
    (32, 1, 32),
    (32, 2, 64),
    (128, 1, 128),
    (128, 2, 256),
    (256, 1, 256),
    (256, 2, 512),
    (512, 1, 512),
    (512, 2, 1024),
]


def create_png(width: int, height: int, pixels: list[list[tuple[int, int, int, int]]]) -> bytes:
    """Create a minimal PNG file from RGBA pixel data."""
    def chunk(chunk_type: bytes, data: bytes) -> bytes:
        c = chunk_type + data
        return struct.pack(">I", len(data)) + c + struct.pack(">I", zlib.crc32(c) & 0xFFFFFFFF)

    header = b"\x89PNG\r\n\x1a\n"
    ihdr = chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))

    raw = b""
    for row in pixels:
        raw += b"\x00"  # filter byte
        for r, g, b, a in row:
            raw += struct.pack("BBBB", r, g, b, a)

    idat = chunk(b"IDAT", zlib.compress(raw, 9))
    iend = chunk(b"IEND", b"")

    return header + ihdr + idat + iend


def draw_icon(size: int) -> list[list[tuple[int, int, int, int]]]:
    """Draw the Refraction prism icon at the given pixel size."""
    pixels: list[list[tuple[int, int, int, int]]] = []

    # Background gradient: dark navy to deep blue
    bg_top = (20, 25, 50)
    bg_bot = (30, 40, 80)

    # Prism triangle vertices (centered, pointing up)
    cx, cy = size / 2, size / 2
    s = size * 0.32  # prism half-size
    # Equilateral triangle
    tri_top = (cx, cy - s * 0.9)
    tri_bl = (cx - s * 0.85, cy + s * 0.6)
    tri_br = (cx + s * 0.85, cy + s * 0.6)

    # Rainbow colors for diffracted light beams
    rainbow = [
        (232, 69, 60),   # red
        (241, 143, 1),   # orange
        (212, 172, 13),  # yellow
        (50, 147, 111),  # green
        (34, 116, 165),  # blue
        (168, 70, 160),  # violet
    ]

    for y in range(size):
        row = []
        for x in range(size):
            # Background gradient
            t = y / max(size - 1, 1)
            bg_r = int(bg_top[0] + (bg_bot[0] - bg_top[0]) * t)
            bg_g = int(bg_top[1] + (bg_bot[1] - bg_top[1]) * t)
            bg_b = int(bg_top[2] + (bg_bot[2] - bg_top[2]) * t)

            r, g, b, a = bg_r, bg_g, bg_b, 255

            # Incoming white light beam (left side, hitting prism)
            beam_y = cy - s * 0.15
            beam_width = size * 0.025
            if x < tri_bl[0] + s * 0.15 and abs(y - beam_y) < beam_width:
                # White beam with slight glow
                intensity = 1.0 - abs(y - beam_y) / beam_width
                r = int(r + (255 - r) * intensity * 0.9)
                g = int(g + (255 - g) * intensity * 0.9)
                b = int(b + (255 - b) * intensity * 0.9)

            # Diffracted rainbow beams (right side of prism)
            prism_exit_x = tri_br[0] - s * 0.15
            prism_exit_y = cy - s * 0.15
            if x > prism_exit_x:
                dx = x - prism_exit_x
                for i, color in enumerate(rainbow):
                    # Each beam diverges at a slightly different angle
                    angle = math.radians(-15 + i * 6)
                    beam_center_y = prism_exit_y + dx * math.tan(angle)
                    dist = abs(y - beam_center_y)
                    bw = size * 0.018
                    if dist < bw:
                        intensity = (1.0 - dist / bw) * min(1.0, dx / (size * 0.05))
                        # Fade out at the edge
                        fade = max(0, 1.0 - dx / (size * 0.45))
                        intensity *= fade
                        r = int(r + (color[0] - r) * intensity)
                        g = int(g + (color[1] - g) * intensity)
                        b = int(b + (color[2] - b) * intensity)

            # Draw prism triangle (translucent white/glass)
            if point_in_triangle(x, y, tri_top, tri_bl, tri_br):
                # Glass-like appearance
                edge_dist = min(
                    point_line_dist(x, y, tri_top, tri_bl),
                    point_line_dist(x, y, tri_bl, tri_br),
                    point_line_dist(x, y, tri_br, tri_top),
                )
                edge_glow = max(0, 1.0 - edge_dist / (size * 0.08))

                # Prism fill: translucent light blue-white
                prism_alpha = 0.15 + edge_glow * 0.4
                pr, pg, pb = 200, 210, 230
                r = int(r + (pr - r) * prism_alpha)
                g = int(g + (pg - g) * prism_alpha)
                b = int(b + (pb - b) * prism_alpha)

            # Round corners (mask)
            corner_r = size * 0.18
            corners = [(0, 0), (size, 0), (0, size), (size, size)]
            for cx2, cy2 in corners:
                dx2 = abs(x - cx2)
                dy2 = abs(y - cy2)
                if dx2 < corner_r and dy2 < corner_r:
                    dist = math.sqrt((dx2 - corner_r) ** 2 + (dy2 - corner_r) ** 2) if dx2 + dy2 > corner_r else 0
                    # Check if outside the rounded corner
                    in_corner_square = dx2 < corner_r and dy2 < corner_r
                    corner_dist = math.sqrt(dx2 ** 2 + dy2 ** 2)
                    if in_corner_square and corner_dist > corner_r:
                        # Anti-alias the edge
                        aa = max(0, min(1, corner_r - corner_dist + 1))
                        a = int(255 * aa)

            row.append((min(255, max(0, r)), min(255, max(0, g)), min(255, max(0, b)), a))
        pixels.append(row)

    return pixels


def sign(x1, y1, x2, y2, x3, y3):
    return (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3)


def point_in_triangle(px, py, v1, v2, v3):
    d1 = sign(px, py, v1[0], v1[1], v2[0], v2[1])
    d2 = sign(px, py, v2[0], v2[1], v3[0], v3[1])
    d3 = sign(px, py, v3[0], v3[1], v1[0], v1[1])
    has_neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    has_pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    return not (has_neg and has_pos)


def point_line_dist(px, py, p1, p2):
    x1, y1 = p1
    x2, y2 = p2
    num = abs((y2 - y1) * px - (x2 - x1) * py + x2 * y1 - y2 * x1)
    den = math.sqrt((y2 - y1) ** 2 + (x2 - x1) ** 2)
    return num / max(den, 0.001)


def main():
    os.makedirs(ICON_DIR, exist_ok=True)

    # Update Contents.json with filenames
    import json
    images = []
    for points, scale, pixel_size in SIZES:
        filename = f"icon_{pixel_size}x{pixel_size}.png"
        filepath = os.path.join(ICON_DIR, filename)

        print(f"Generating {filename} ({pixel_size}x{pixel_size})...")
        pixels = draw_icon(pixel_size)
        png_data = create_png(pixel_size, pixel_size, pixels)

        with open(filepath, "wb") as f:
            f.write(png_data)

        images.append({
            "filename": filename,
            "idiom": "mac",
            "scale": f"{scale}x",
            "size": f"{points}x{points}",
        })

    contents = {
        "images": images,
        "info": {
            "author": "xcode",
            "version": 1,
        },
    }

    contents_path = os.path.join(ICON_DIR, "Contents.json")
    with open(contents_path, "w") as f:
        json.dump(contents, f, indent=2)

    print(f"\nGenerated {len(SIZES)} icons in {ICON_DIR}")
    print("Contents.json updated with filenames.")


if __name__ == "__main__":
    main()
