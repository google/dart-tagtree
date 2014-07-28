part of mandelbrot;

class Color {
  final int r;
  final int g;
  final int b;
  String _rgbString;

  /// Each argument has range 0 to 255.
  Color.rgb(this.r, this.g, this.b) {
    _rgbString = "rgb(${r},${g},${b})";
  }

  /// Calculates an rgb color from hue, saturation, and lightness. Each argument has range 0 to 1.
  factory Color.hsl(double h, double s, double l) {
    assert(h >= 0 && h <= 1);
    assert(s >= 0 && s <= 1);
    assert(l >= 0 && l <= 1);

    // Normalize hue to a number from 0 to 6 (exclusive).
    // This is so we can divide the circle into 6 60-degree pieces.
    h = (h - h.floor()) * 6.0;

    // The distance from the previous 60-degree axis on the hue's circle. (Range 0 to 1 exclusive.)
    num d = h - h.floor();

    // The chroma for HSL is a double cone shape, with points at l == 0 (black)
    // and l == 1.0 (white). Maximum chroma is halfway between at l == 0.5,
    // with s == 1.0 for the outer surface of the cones.
    num c;
    if (l < 0.5) {
      c = (l * 2) * s; // lower cone
    } else {
      c = (2 - (l * 2)) * s; // upper cone
    }

    // The two unchanging components in each piece. (Range 0 to 255.)
    int min = ((l - 0.5 * c) * 255.0).floor();
    int max = min + (c * 255.0).floor();

    // Distance from starting point for the changing component. (Range 0 to 254.)
    num ramp = (d * c * 255.0).floor();

    // Use a separate case for each piece.
    switch (h.floor()) {
      case 0:
        // red to yellow
        return new Color.rgb(max, min + ramp, min);
      case 1:
        // yellow to green
        return new Color.rgb(max - ramp, max, min);
      case 2:
        // green to cyan
        return new Color.rgb(min, max, min + ramp);
      case 3:
        // cyan to blue
        return new Color.rgb(min, max - ramp, max);
      case 4: // blue to magenta
        return new Color.rgb(min + ramp, min, max);
      case 5: // magenta to red
        return new Color.rgb(max, min, max - ramp);
    }

    throw new Exception("shouldn't get here");
  }

  String toCss() {
    return _rgbString;
  }
}

class HslColor {
  final int h; // 0 - 360 (wraps)
  final int s; // 0 - 100 (percent)
  final int l; // 0 - 100 (percent)
  HslColor(this.h, this.s, this.l);

  String toCss() => "hsl(${h%360},${s}%,${l}%)";

  Color toRgb() => new Color.hsl(h/360, s/100, l/100);
}

/// Generates a list of colors by interpolating between two points in HSL
/// color space. The hue may be denormalized (below 0 or above 360 degrees)
/// to wrap around the color spectrum multiple times along a corkscrew or
/// spiral path.
List<Color> colorRange(HslColor start, HslColor end, int count) {
  var interpolate = (int start, int end, num scale) =>
      ((end - start) * scale + start).round();

  var result = new List<Color>();

  for (double i = 0.0; i < count; i++) {
    num scale = i / (count - 1);
    int h = interpolate(start.h, end.h, scale) % 360;
    int s = interpolate(start.s, end.s, scale);
    int l = interpolate(start.l, end.l, scale);
    result.add(new HslColor(h, s, l).toRgb());
  }

  return result;
}
