library mandelbrot;

import 'package:tagtree/browser.dart';
import 'dart:html';

part "color.dart";

//
// Views
//

typedef SaveCameraHandler(Camera next);

class MandelbrotApp extends AnimatedTag {
  final Camera startCamera;
  final SaveCameraHandler save;

  const MandelbrotApp({this.startCamera: Camera.start, this.save});

  @override
  Place start() => new Place(startCamera);

  @override
  bool shouldRestart(Place p, AnimatedTag prev) {
    if (prev is MandelbrotApp) {
      return prev.startCamera != startCamera;
    } else {
      return true;
    }
  }

  @override
  Tag renderAt(Place<Camera> p) {

    void onClick(Complex newCenter) {
      p.nextState = p.nextState.pan(newCenter);
    }

    void zoom(num scaleAmount) {
      p.nextState = p.nextState.zoom(scaleAmount);
      if (save != null) {
        save(p.nextState);
      }
    }

    var camera = p.state;
    return $.Div(inner: [
      new MandelbrotView(center: camera.center, radius: camera.radius, onClick: onClick),
      $.Div(inner: [
        $.Button(onClick: (_) => zoom(0.5), inner: "Zoom In"),
        $.Button(onClick: (_) => zoom(2.0), inner: "Zoom Out"),
      ]),
      $.Div(inner: [
        "Center: ${camera.center} Radius: ${camera.radius}"
      ]),
      $.Div(inner: "Click image to recenter")
    ]);
  }
}

typedef ClickHandler(Complex point);

class MandelbrotView extends AnimatedTag {
  final Complex center;
  final num radius;

  final int width;
  final int height;
  final ClickHandler onClick;
  final List<Color> colors;
  double scalePixel;

  MandelbrotView({
    this.center: const Complex(0, 0),
    this.radius: 2.0,

    this.width: 400,
    this.height: 400,
    List<Color> colors,
    this.onClick}) :
      this.colors = (colors == null) ? defaultColors : colors
  {
    var radiusPixels = width < height ? width/2.0 : height/2.0;
    scalePixel = radius / radiusPixels;
  }

  @override
  bool operator==(Object other) {
    if (other is MandelbrotView) {
      bool result = center==other.center && radius == other.radius &&
          width == other.width && height == other.height &&
          colors == other.colors &&
          onClick == other.onClick;
      return result;
    }
    return false;
  }

  @override
  int get hashCode => center.hashCode ^ radius.hashCode ^ width ^ height;

  @override
  start() => new Place(false);

  @override
  bool shouldRestart(Place<MandelbrotView> p, MandelbrotView prev) => prev != this;

  @override
  Tag renderAt(Place p) {

    // Ask for a callback when the DOM is ready.
    var canvas = new Ref<CanvasElement>();
    p.onRendered = (_) => draw(canvas.elt.context2D);

    var convertOnClick = null;
    if (onClick != null) {
      convertOnClick = (HandlerEvent e) {
        MousePosition m = e.value;
        onClick(new Complex(pixelToCoordX(m.x), pixelToCoordY(m.y)));
      };
    }

    return $.Canvas(width: width, height: height, clazz: "center", ref: canvas,
      onClick: convertOnClick);
  }

  void draw(CanvasRenderingContext2D context) {
    var startTime = window.performance.now();
//    window.console.profile("draw");

    var pixels = context.createImageData(width, height);
    for (int y = 0; y < height; y++) {
      drawLine(pixels, y);
    }
    context.putImageData(pixels, 0,  0);

//    window.console.profileEnd("draw");
    var elapsedTime = window.performance.now() - startTime;
    print("draw time: ${elapsedTime} ms");
  }

  void drawLine(ImageData pixels, int y) {
    num imag = - pixelToCoordY(y);
    int maxIterations = colors.length - 1;
    int width = pixels.width;

    var data = pixels.data;
    int pixelIndex = y * width * 4;

    for (int x = 0; x < width; x++) {
      num real = pixelToCoordX(x);
      int iterations = probe(real, imag, maxIterations);
      Color color = colors[iterations];
      data[pixelIndex++] = color.r;
      data[pixelIndex++] = color.g;
      data[pixelIndex++] = color.b;
      data[pixelIndex++] = 255;
    }
  }

  num pixelToCoordX(int x) => scalePixel * (x - width / 2) + center.real;
  num pixelToCoordY(int y) => -scalePixel * (y - height / 2) + center.imag;

  static final List<Color> defaultColors = colorRange(
      new HslColor(1, 80, 70),
      new HslColor(360 * 20, 100, 0),
      1000);

  static _makeCssColors(List<Color> input) =>
      input.map((c) => c.toCss()).toList()..add("#000");
}

//
// Models
//

class Complex {
  final num real;
  final num imag;
  const Complex(this.real, this.imag);

  @override
  bool operator==(other) =>
    other is Complex && real==other.real && imag==other.imag;

  @override
  int get hashCode => real.hashCode ^ imag.hashCode;

  @override
  toString() => imag >= 0 ? "${real}+${imag}i" : "${real}${imag}i";
}

/// The area of the complex plane to display in the view.
class Camera implements Cloneable {
  final Complex center;
  final num radius; // distance to shorter of width and height
  const Camera(this.center, this.radius);

  Camera pan(Complex newCenter) => new Camera(newCenter, radius);

  // Below 1.0 means zoom in, above means zoom out.
  Camera zoom(num scaleFactor) => new Camera(center, radius * scaleFactor);

  @override
  clone() => this;

  @override
  operator==(other) => (other is Camera) && center == other.center && radius == other.radius;

  @override
  get hashCode => center.hashCode ^ radius.hashCode;

  @override
  toString() => "Camera(${center}, ${radius})";

  static const start = const Camera(const Complex(0, 0), 2.0);
}

const period2RadiusSquared = (1/16);

/// Calculates the value of the Mandelbrot image at one point.
///
/// Returns a number between 0 and maxIterations that indicates the number of iterations
/// it takes for the Mandelbrot sequence to go outside the circle with radius 2.
/// Returns maxIterations if it doesn't escape within that many iterations.
int probe(double x, double y, int maxIterations) {
  // Return early if the point is within the central bulb (a cartoid).
  double xMinus = x - 0.25;
  double ySquared = y * y;
  double q = xMinus * xMinus + ySquared;
  if (q * (q + xMinus) < 0.25 * ySquared) {
    return maxIterations;
  }

  // Return early if the point is within the period-2 bulb (a circle)
  if ((x + 1) * (x + 1) + ySquared < period2RadiusSquared) {
    return maxIterations;
  }

  double a = 0.0;
  double b = 0.0;

  // cycle detection: follow the same path but at half speed
  double pastA = 0.0;
  double pastB = 0.0;

  for (int count = 0; count < maxIterations; count++) {
    num aSquared = a * a;
    num bSquared = b * b;
    if (aSquared + bSquared > 4.0) {
      return count; // escaped
    }
    num nextA = aSquared - bSquared + x;
    num nextB = 2.0 * a * b + y;
    a = nextA;
    b = nextB;

    if (a == pastA && b == pastB) {
      return maxIterations; // cycle found
    }

    if (count % 2 == 0) {
      // move previous point used for detecting cycles
      num nextPastA = pastA * pastA - pastB * pastB + x;
      num nextPastB = 2.0 * pastA * pastB + y;
      pastA = nextPastA;
      pastB = nextPastB;
    }
  }

  // didn't escape
  return maxIterations;
}

//
// Persistence (in the URL)
//

Camera loadCamera() {
  var params = <String, double>{};
  if (window.location.hash.isNotEmpty) {
    for (String segment in window.location.hash.substring(1).split("&")) {
      List parts = segment.split("=");
      if (parts.length == 2) {
        var value = double.parse(parts[1], (_) => null);
        if (value != null) {
          params[parts[0]] = value;
        }
      }
    }
  }

  if (params.containsKey("x") && params.containsKey("y") && params.containsKey("r")) {
   return new Camera(new Complex(params["x"], params["y"]), params["r"]);
  } else {
    return Camera.start;
  }
}

saveCamera(Camera next) {
  var state = "#x=${next.center.real}&y=${next.center.imag}&r=${next.radius}";
  window.location.hash = state;
}

render() {
  var camera = loadCamera();
  getRoot("#container")
    .mount(new MandelbrotApp(startCamera: camera, save: saveCamera));
}

main() {
  render();
  window.onHashChange.listen((_) {
    render();
  });
}
