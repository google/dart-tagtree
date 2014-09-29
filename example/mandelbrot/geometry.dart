part of mandelbrot;

/// The area of the complex plane to display in the view.
/// (X is used for the real axis and y for the imaginary axis.)
class Camera implements Cloneable {
  final Point center;
  final num radius; // half of the view's width and height, whichever is shorter
  const Camera(this.center, this.radius);

  Camera pan(Point newCenter) => new Camera(newCenter, radius);

  // Below 1.0 means zoom in, above means zoom out.
  Camera zoom(num scaleFactor) => new Camera(center, radius * scaleFactor);

  // Computes the width (and height) of each pixel in the complex plane,
  // for a view with the given width and height.
  // (Assumes square pixels.)
  num pixelSize(int width, int height) {
    var radiusInPixels = width < height ? width/2.0 : height/2.0;
    return radius / radiusInPixels;
  }

  @override
  operator==(other) => (other is Camera) && center == other.center && radius == other.radius;

  @override
  get hashCode => center.hashCode ^ radius.hashCode;

  @override
  toString() => "Camera(${center}, ${radius})";

  @override
  clone() => this;

  /// A camera view that shows the full Mandelbrot set.
  static const start = const Camera(const Point(0.0, 0.0), 2.0);
}

/// Projects a rectangular grid of square pixels onto the complex plane.
/// Converts from pixel coordinates to complex numbers.
/// For the pixel grid, (0,0) is in the upper left and +y is down.
/// For the complex plane, positive real is right and positive imaginary is up.
class Grid implements Cloneable {
  final Point center; // center of the grid in the complex plane. (x is real, y is imaginary)
  final num radius;
  final int width; // width of the grid in pixels
  final int height; // height of the grid in pixels
  final num pixelSize; // size of a pixel in the complex plane

  Grid.raw(this.center, this.radius, this.width, this.height, this.pixelSize);

  Grid(Camera camera, [int width = 800, int height = 800]) :
    this.center = camera.center,
    this.radius = camera.radius,
    this.width = width,
    this.height = height,
    this.pixelSize = camera.pixelSize(width, height);

  Grid resize(int width, int height) => new Grid(new Camera(center, radius), width, height);

  // The real component for a pixel with the given x coordinate.
  num pixelToReal(int x) => pixelSize * (x - width / 2) + center.x;

  // The imaginary component for a pixel with the given y coordinate.
  num pixelToImag(int y) => -pixelSize * (y - height / 2) + center.y;

  // The complex number corresponding to a pixel.
  Point pixelToPoint(int x, int y) => new Point(pixelToReal(x), pixelToImag(y));

  int realToX(num real) => ((real - center.x) / pixelSize + (width / 2)).floor();

  int imagToY(num imag) => ((imag - center.y) / -pixelSize + (height / 2)).floor();

  Grid drag(num dReal, dImag) => new Grid.raw(
      new Point(center.x - dReal, center.y - dImag), radius, width, height, pixelSize);

  @override
  operator==(other) =>
      (other is Grid) &&
      center == other.center &&
      width == other.width &&
      height == other.height &&
      pixelSize == other.pixelSize;

  @override
  get hashCode => center.hashCode ^ width.hashCode ^ height.hashCode ^ pixelSize.hashCode;

  @override
  Grid clone() => this;
}

const period2RadiusSquared = (1/16);

/// Calculates the value of the Mandelbrot image at one point.
///
/// Returns a number between 1 and maxIterations that indicates the number of iterations
/// it takes for the Mandelbrot sequence to go outside the circle with radius 2.
/// Returns maxIterations if it doesn't escape within that many iterations.
int findMandelbrot(double x, double y, int maxIterations) {
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