part of mandelbrot;

class RenderRequest implements Cloneable {
  final Grid grid;
  final List<Color> colors;
  final bool fast;
  RenderRequest(this.grid, this.colors, {this.fast: false});
  RenderRequest clone() => this;

  void render(CanvasRenderingContext2D context) {
    if (fast) {
      renderFast(context, grid, colors);
    } else {
      renderFull(context, grid, colors);
    }
  }
}

/// Renders each pixel in the given grid to the mandelbrot color.
void renderFull(CanvasRenderingContext2D context, Grid grid, List<Color> colors, {bool fast}) {
  var startTime = window.performance.now();
//    window.console.profile("draw");

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

  for (int y = 0; y < grid.height; y++) {
    drawLine(y);
  }

  context.putImageData(pixels, 0,  0);

//    window.console.profileEnd("draw");
  var elapsedTime = window.performance.now() - startTime;
  print("full render time: ${elapsedTime} ms");
}

void renderFast(CanvasRenderingContext2D context, Grid grid, List<Color> colors) {
  var startTime = window.performance.now();

  num pixelsPerCell = 10;
  num cellSize = grid.pixelSize * pixelsPerCell;

  // Find the bounds of a grid on the complex plane (so that cells don't move when we scroll)
  num top = ((grid.pixelToImag(0) / cellSize).floorToDouble() + 1) * cellSize;
  num left = ((grid.pixelToReal(0) / cellSize).floorToDouble()) * cellSize;
  num bottom = ((grid.pixelToImag(grid.height) / cellSize).floorToDouble()) * cellSize;
  num right = ((grid.pixelToReal(grid.width) / cellSize).floorToDouble() + 1) * cellSize;

  int maxIterations = colors.length;

  for (num imag = top; imag > bottom; imag -= cellSize) {
    int y = grid.imagToY(imag);
    int nextY = grid.imagToY(imag - cellSize);
    for (num real = left; real < right; real += cellSize) {
      int x  = grid.realToX(real);
      int nextX = grid.realToX(real + cellSize);
      int iterations = findMandelbrot(real, imag, maxIterations);
      Color color = colors[iterations - 1];
      context.fillStyle = color.toCss();
      context.fillRect(x, y, nextX - x, nextY - y);
    }
  }

  var elapsedTime = window.performance.now() - startTime;
  print("fast render time: ${elapsedTime} ms");
}
