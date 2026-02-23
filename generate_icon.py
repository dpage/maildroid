#!/usr/bin/env python3
"""Generate macOS app icon for Maildroid at all required sizes.

Produces a modern flat-design envelope with gold AI sparkle accents
on a near-black-to-green gradient background matching the app's
notification popup colours. The canvas is a full square (macOS applies
the rounded-rect mask automatically).
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

OUTPUT_DIR = Path(__file__).parent / "MailDroid" / "Assets.xcassets" / "AppIcon.appiconset"
CANVAS = 1024  # Master size; everything is drawn relative to this.

# Gradient colours (top-left to bottom-right, near-black to green).
GRAD_TOP = (26, 26, 28)        # Near black (popup background)
GRAD_BOTTOM = (90, 158, 114)   # Popup green accent


# ---------------------------------------------------------------------------
# Drawing helpers
# ---------------------------------------------------------------------------

def _lerp_colour(c1: tuple, c2: tuple, t: float) -> tuple:
    """Linearly interpolate between two RGB tuples."""
    return tuple(int(a + (b - a) * t) for a, b in zip(c1, c2))


def _draw_gradient(img: Image.Image) -> None:
    """Fill *img* with a diagonal linear gradient."""
    w, h = img.size
    pixels = img.load()
    for y in range(h):
        for x in range(w):
            # Diagonal parameter: average of horizontal and vertical progress.
            t = ((x / w) + (y / h)) / 2.0
            pixels[x, y] = _lerp_colour(GRAD_TOP, GRAD_BOTTOM, t)


def _draw_envelope(draw: ImageDraw.ImageDraw, s: int) -> None:
    """Draw a stylised flat envelope centred on an *s* x *s* canvas.

    The envelope is white with a slight translucency effect achieved by
    using a very light grey for the body and pure white for the flap.
    """
    # Margins — the envelope sits in the centre ~60% of the canvas.
    margin_x = int(s * 0.18)
    margin_top = int(s * 0.28)
    margin_bot = int(s * 0.28)

    left = margin_x
    right = s - margin_x
    top = margin_top
    bottom = s - margin_bot

    env_w = right - left
    env_h = bottom - top

    # Envelope body (rounded-corner rectangle via simple rectangle — Pillow
    # rounded_rectangle is available in Pillow >= 8.2).
    body_colour = (255, 255, 255, 230)  # Slightly translucent white
    draw.rounded_rectangle(
        [left, top, right, bottom],
        radius=int(s * 0.03),
        fill=body_colour,
    )

    # Envelope flap — 45-degree lines from each top corner, transitioning
    # smoothly into a cubic bezier curve that dips to the centre.
    flap_colour = (235, 235, 245, 240)
    mid_x = s // 2
    line_colour = (200, 200, 220, 180)
    line_w = max(1, int(s * 0.004))

    # Inset flap start/end by the corner radius so the flap does not
    # extend past the rounded corners of the envelope body.
    corner_radius = int(s * 0.03)
    flap_left = left + corner_radius
    flap_right = right - corner_radius

    # At 45 degrees each pixel inward moves 1 pixel down.  The straight
    # portions descend ~20% of the envelope height before curving.
    straight_descent = int(env_h * 0.20)
    curve_bottom_y = top + int(env_h * 0.45)

    # Junction points where the 45-degree lines end and the curve begins.
    left_jx = flap_left + straight_descent
    left_jy = top + straight_descent
    right_jx = flap_right - straight_descent
    right_jy = top + straight_descent

    # Build the flap polygon.
    _STRAIGHT_PTS = 4
    _CURVE_SEG = 20  # Segments per half-curve (left and right).
    flap_points = [(flap_left, top)]

    # Left straight section at 45 degrees.
    for i in range(1, _STRAIGHT_PTS + 1):
        t = i / _STRAIGHT_PTS
        sx = int(flap_left + (left_jx - flap_left) * t)
        sy = int(top + (left_jy - top) * t)
        flap_points.append((sx, sy))

    # Cubic bezier — left half: (left_jx, left_jy) -> (mid_x, curve_bottom_y).
    # CP1 continues the 45-degree direction from the junction.
    # CP2 is horizontally left of mid_x at curve_bottom_y for a horizontal
    # tangent at the bottom centre.
    cp_extend = int(env_w * 0.15)
    l_cp1x = left_jx + cp_extend
    l_cp1y = left_jy + cp_extend
    l_cp2x = mid_x - int(env_w * 0.18)
    l_cp2y = curve_bottom_y

    for i in range(_CURVE_SEG + 1):
        t = i / _CURVE_SEG
        u = 1 - t
        bx = int(u**3 * left_jx + 3 * u**2 * t * l_cp1x
                 + 3 * u * t**2 * l_cp2x + t**3 * mid_x)
        by = int(u**3 * left_jy + 3 * u**2 * t * l_cp1y
                 + 3 * u * t**2 * l_cp2y + t**3 * curve_bottom_y)
        flap_points.append((bx, by))

    # Cubic bezier — right half: (mid_x, curve_bottom_y) -> (right_jx, right_jy).
    # Mirror of the left half.
    r_cp1x = mid_x + int(env_w * 0.18)
    r_cp1y = curve_bottom_y
    r_cp2x = right_jx - cp_extend
    r_cp2y = right_jy + cp_extend

    for i in range(1, _CURVE_SEG + 1):
        t = i / _CURVE_SEG
        u = 1 - t
        bx = int(u**3 * mid_x + 3 * u**2 * t * r_cp1x
                 + 3 * u * t**2 * r_cp2x + t**3 * right_jx)
        by = int(u**3 * curve_bottom_y + 3 * u**2 * t * r_cp1y
                 + 3 * u * t**2 * r_cp2y + t**3 * right_jy)
        flap_points.append((bx, by))

    # Right straight section back up to the top-right corner (reverse order).
    for i in range(_STRAIGHT_PTS - 1, -1, -1):
        t = i / _STRAIGHT_PTS
        sx = int(flap_right + (right_jx - flap_right) * t)
        sy = int(top + (right_jy - top) * t)
        flap_points.append((sx, sy))
    flap_points.append((flap_right, top))
    draw.polygon(flap_points, fill=flap_colour)

    # Thin lines along the flap edge for definition.
    # Walk the same points (skip the first which is the corner itself).
    edge_points = flap_points  # Include corners so lines reach the top edge
    for i in range(len(edge_points) - 1):
        draw.line([edge_points[i], edge_points[i + 1]],
                  fill=line_colour, width=line_w)

    # ------------------------------------------------------------------
    # Bottom "V" lines — clipped where they intersect the flap curve.
    # ------------------------------------------------------------------
    v_colour = (220, 220, 235, 100)
    v_target_y = top + int(env_h * 0.15)

    def _line_seg_intersect(p1, p2, p3, p4):
        """Return the intersection point of segments p1-p2 and p3-p4,
        or None if they do not intersect."""
        x1, y1 = p1
        x2, y2 = p2
        x3, y3 = p3
        x4, y4 = p4
        denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
        if abs(denom) < 1e-10:
            return None
        t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
        u = -((x1 - x2) * (y1 - y3) - (y1 - y2) * (x1 - x3)) / denom
        if 0.0 <= t <= 1.0 and 0.0 <= u <= 1.0:
            ix = x1 + t * (x2 - x1)
            iy = y1 + t * (y2 - y1)
            return (int(ix), int(iy))
        return None

    def _find_flap_intersection(start, end, flap_pts):
        """Find the first intersection of the line from *start* to *end*
        with the flap polygon edges, searching from *start* outward."""
        best = None
        best_t = 2.0  # Larger than any valid t
        sx, sy = start
        ex, ey = end
        dx = ex - sx
        dy = ey - sy
        for i in range(len(flap_pts) - 1):
            hit = _line_seg_intersect(start, end, flap_pts[i], flap_pts[i + 1])
            if hit is not None:
                # Parametric t along the V line.
                if abs(dx) > abs(dy):
                    t = (hit[0] - sx) / dx if dx != 0 else 0
                else:
                    t = (hit[1] - sy) / dy if dy != 0 else 0
                if 0.0 <= t <= 1.0 and t < best_t:
                    best_t = t
                    best = hit
        return best

    # The V lines go from bottom corners toward (mid_x, v_target_y).
    # Clip each one at the flap boundary.
    left_start = (left, bottom)
    right_start = (right, bottom)
    v_end = (mid_x, v_target_y)

    left_clip = _find_flap_intersection(left_start, v_end, flap_points)
    right_clip = _find_flap_intersection(right_start, v_end, flap_points)

    left_end = left_clip if left_clip else v_end
    right_end = right_clip if right_clip else v_end

    draw.line([left_start, left_end], fill=v_colour, width=line_w)
    draw.line([right_start, right_end], fill=v_colour, width=line_w)


def _draw_sparkle(draw: ImageDraw.ImageDraw, cx: int, cy: int,
                  size: int, colour: tuple) -> None:
    """Draw a four-pointed star (sparkle) centred at (*cx*, *cy*).

    *size* is the radius from centre to tip.
    """
    # A four-pointed star is drawn as two overlapping thin diamonds.
    inner = int(size * 0.28)
    points = [
        # Top
        (cx, cy - size),
        (cx + inner, cy),
        # Right
        (cx + size, cy),
        (cx, cy + inner),
        # Bottom
        (cx, cy + size),
        (cx - inner, cy),
        # Left
        (cx - size, cy),
        (cx, cy - inner),
    ]
    draw.polygon(points, fill=colour)


def generate_master(size: int = CANVAS) -> Image.Image:
    """Return the master icon as an RGBA PIL Image at *size* x *size*."""
    img = Image.new("RGB", (size, size))
    _draw_gradient(img)

    # Convert to RGBA so the envelope can use alpha.
    img = img.convert("RGBA")
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    _draw_envelope(draw, size)

    # Seven sparkles in the upper-right area, suggesting AI magic.
    sparkles = [
        # (x_frac, y_frac, radius_frac, colour)
        (0.78, 0.18, 0.075, (255, 215,  0, 255)),  # Primary (largest, bright gold)
        (0.88, 0.12, 0.045, (255, 215,  0, 250)),  # Upper-right
        (0.68, 0.12, 0.035, (255, 220, 40, 240)),  # Upper-left of cluster
        (0.85, 0.25, 0.030, (255, 210, 20, 235)),  # Mid-right
        (0.72, 0.08, 0.020, (255, 200, 50, 220)),  # Top accent
        (0.92, 0.19, 0.018, (255, 200, 50, 210)),  # Far right accent
        (0.82, 0.32, 0.015, (255, 190, 30, 200)),  # Lower accent
    ]
    for xf, yf, rf, col in sparkles:
        _draw_sparkle(draw, int(size * xf), int(size * yf),
                      int(size * rf), col)

    img = Image.alpha_composite(img, overlay)
    # Flatten to RGB (macOS icons are opaque squares).
    return img.convert("RGB")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

SIZES = [16, 32, 64, 128, 256, 512, 1024]


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    master = generate_master(CANVAS)

    for px in SIZES:
        out = master.resize((px, px), Image.LANCZOS)
        path = OUTPUT_DIR / f"icon_{px}x{px}.png"
        out.save(path, "PNG")
        print(f"  Saved {path.name}  ({path.stat().st_size:,} bytes)")

    print(f"\nAll icons written to {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
