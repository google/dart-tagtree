part of mandelbrot;

/// A request to render part of the Given grid as a Mandelbrot set.
class RenderRequest implements Cloneable {
  final Grid grid;
  final List<Color> colors;
  final bool fast;
  final int yStart;
  final num maxMillis;
  RenderRequest(this.grid, this.colors, {this.fast: true, this.yStart: 0, this.maxMillis: 15});
  RenderRequest clone() => this;

  /// Renders as much as possible within 15 ms. Returns a RenderRequest if there is more to be done.
  RenderRequest render(CanvasRenderingContext2D context) {
    if (fast) {
      renderFast(context, grid, colors);
      return new RenderRequest(grid, colors, fast: false);
    } else {
      num nextYStart = renderStrip(context, grid, colors, yStart, maxMillis);
      return nextYStart == null ? null : new RenderRequest(grid, colors, fast: false, yStart: nextYStart);
    }
  }
}

/// Renders each pixel in the given grid, starting at yStart and downward.
/// Stops after the given number of milliseconds. Returns the yStart for the next strip or null if finished.
int renderStrip(CanvasRenderingContext2D context, Grid grid, List<Color> colors, int yStart, num maxMillis) {
  num startTime = window.performance.now();

  var pixels = context.createImageData(grid.width, grid.height);
  var data = pixels.data;

  int width = pixels.width;
  int maxIterations = colors.length;

  void drawLine(int y) {
    num imag = - grid.pixelToImag(y);
    int pixelIndex = y * width * 4;

    for (int x = 0; x < width; x++) {
      num real = grid.pixelToReal(x);
      int iterations = findMandelbrot(real, imag, maxIterations);
      Color color = colors[iterations - 1];
      data[pixelIndex++] = color.r;
      data[pixelIndex++] = color.g;
      data[pixelIndex++] = color.b;
      data[pixelIndex++] = 255;
    }
  }

  num deadline = startTime + maxMillis;
  num y = yStart;
  while (true) {
    drawLine(y);
    y++;
    if (y >= grid.height || window.performance.now() > deadline) {
      break;
    }
  }

  context.putImageData(pixels, 0,  0, 0, yStart, grid.width, y - yStart);
  return y < grid.height ? y : null;
}

/// Renders a low-resolution preview image.
void renderFast(CanvasRenderingContext2D context, Grid grid, List<Color> colors, {cellSizePixels: 20}) {
  var startTime = window.performance.now();

  num cellSize = grid.pixelSize * cellSizePixels;

  // Find the bounds of a grid on the complex plane (so that cells don't move when we scroll)
  num top = ((grid.pixelToImag(0) / cellSize).floorToDouble() + 1) * cellSize;
  num left = ((grid.pixelToReal(0) / cellSize).floorToDouble()) * cellSize;
  num bottom = ((grid.pixelToImag(grid.height) / cellSize).floorToDouble()) * cellSize;
  num right = ((grid.pixelToReal(grid.width) / cellSize).floorToDouble() + 1) * cellSize;

  int maxIterations = colors.length;

  for (num imag = top + grid.pixelSize / 2; imag > bottom; imag -= cellSize) {
    int y = grid.imagToY(imag);
    int nextY = grid.imagToY(imag - cellSize);
    for (num real = left + grid.pixelSize / 2; real < right; real += cellSize) {
      int x  = grid.realToX(real);
      int nextX = grid.realToX(real + cellSize);
      int iterations = findMandelbrot(real, imag, maxIterations);
      Color color = colors[iterations - 1];
      context.fillStyle = color.toCss();
      context.fillRect(x, y, nextX - x, nextY - y);
    }
  }

  var elapsedTime = window.performance.now() - startTime;
  //print("fast render time: ${elapsedTime} ms");
}
