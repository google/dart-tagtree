import 'package:tagtree/browser.dart';
import 'dart:html';

class Complex {
  final num real;
  final num imag;
  const Complex(this.real, this.imag);

  @override
  bool operator==(other) =>
    other is Complex && real==other.real && imag==other.imag;

  @override
  toString() => imag >= 0 ? "${real}+${imag}i" : "${real}${imag}i";
}

/// The area of the complex plane to display in the view.
class Camera implements Cloneable {
  final Complex center;
  final num radius;
  const Camera(this.center, this.radius);

  Camera pan(Complex newCenter) => new Camera(newCenter, radius);

  // Below 1.0 means zoom in, above means zoom out.
  Camera zoom(num scaleFactor) => new Camera(center, radius * scaleFactor);

  @override
  clone() => this;
}

class MandelbrotApp extends AnimatedTag {
  const MandelbrotApp();

  start() => new Place<Camera>(const Camera(const Complex(0, 0), 2.0));

  Tag renderAt(Place<Camera> p) {
    void onClick(Complex newCenter) {
      p.nextState = p.nextState.pan(newCenter);
    }
    void zoom(num scaleAmount) {
      p.nextState = p.nextState.zoom(scaleAmount);
    }
    var center = p.state.center;
    return $.Div(inner: [
      new MandelbrotView(center: center, radius: p.state.radius, onClick: onClick),
      $.Div(inner: [
        $.Button(onClick: (_) => zoom(0.5), inner: "Zoom In"),
        $.Button(onClick: (_) => zoom(2.0), inner: "Zoom Out"),
      ]),
      $.Div(inner: [
        "Center: ${center} Radius: ${p.state.radius}"
      ]),
      $.Div(inner: "Click image to recenter")
    ]);
  }
}

typedef ClickHandler(Complex point);

class RenderState implements Cloneable {
  final MandelbrotView view;
  final int linesRendered;
  RenderState(this.view, this.linesRendered);

  @override
  clone() => this;
}

class MandelbrotView extends AnimatedTag {
  final Complex center;
  final num radius;
  final int maxIterations;

  final int width;
  final int height;
  final List<String> colors;
  final ClickHandler onClick;

  const MandelbrotView({
    this.center: const Complex(0, 0),
    this.radius: 2.0,
    this.maxIterations: 1000,

    this.width: 400,
    this.height: 400,
    this.colors: const [
      "#f10","#e20","#d30","#c40","#b50","#a60","#970",
      "#880","#790","#6a0","#5b0","#4c0","#3d","#2e0","1f0"],
    this.onClick
  });

  @override
  bool operator==(Object other) {
    if (other is MandelbrotView) {
      bool result = center==other.center && radius == other.radius &&
          maxIterations == other.maxIterations &&
          width == other.width && height == other.height &&
          colors == other.colors &&
          onClick == other.onClick;
      return result;
    }
    return false;
  }

  @override
  start() => new Place<RenderState>(new RenderState(this, 0));

  @override
  bool shouldRestart(Place<RenderState> p) => p.state.view != this;

  @override
  Tag renderAt(Place<RenderState> p) {

    // Ask for a callback when the DOM is ready.
    var canvas = new Ref<CanvasElement>();
    p.onRendered = (_) => drawStrip(canvas.elt.context2D, p);

    var convertOnClick = null;
    if (onClick != null) {
      convertOnClick = (HandlerEvent e) {
        MousePosition m = e.value;
        onClick(new Complex(pixelToReal(m.x), pixelToImag(m.y)));
      };
    }

    return $.Canvas(width: width, height: height, clazz: "center", ref: canvas,
      onClick: convertOnClick);
  }

  void drawStrip(CanvasRenderingContext2D context, Place<RenderState> p) {
    int y = p.state.linesRendered;

    num startTime = window.performance.now();
    num stopTime = startTime + 25;
    while (window.performance.now() < stopTime) {
      if (y == height) {
        return;
      }
      drawLine(context, y);
      y++;
    }
    p.nextState = new RenderState(p.nextState.view, y);
  }

  void drawLine(CanvasRenderingContext2D context, int y) {
    num imag = - pixelToImag(y);
    for (int x = 0; x < width; x++) {
      num real = pixelToReal(x);

      int count = probe(real, imag, 10.0, maxIterations);

      String color;
      if (count == maxIterations) {
        color = "#000";
      } else {
        color = colors[count % colors.length];
      }
      context.fillStyle = color;
      context.fillRect(x, y, 1, 1);
    }
  }

  num get radiusPixels => width < height ? width/2.0 : height/2.0;
  num scalePixel(num pix) => pix * radius / radiusPixels;

  num pixelToReal(int x) => scalePixel(x - width / 2) + center.real;
  num pixelToImag(int y) => -scalePixel(y - height / 2) + center.imag;
}

/// Returns the number of iterations it takes for the Mandelbrot sequence to
/// go outside the circle with the given radius squared. Returns maxIterations
/// if doesn't escape (is in the set).
int probe(double real, double imag, double radiusSquared, int maxIterations) {
  double a = 0.0;
  double b = 0.0;
  int count = 0;

  while (true) {
    num aSquared = a * a;
    num bSquared = b * b;
    if (aSquared + bSquared > radiusSquared || count >= maxIterations) {
      break;
    }
    b = 2.0 * a * b + imag;
    a = aSquared - bSquared + real;
    count++;
  }

  return count;
}

main() =>
    getRoot("#container")
      .mount(const MandelbrotApp());
