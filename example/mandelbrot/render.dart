part of mandelbrot;

/**
 * Renders each pixel in the given grid.
 */
void renderFull(CanvasRenderingContext2D context, Grid grid, List<Color> colors) {

  var startTime = window.performance.now();
//    window.console.profile("draw");

  var pixels = context.createImageData(grid.width, grid.height);
  var data = pixels.data;

  void drawLine(int y) {
    num imag = - grid.pixelToImag(y);
    int maxIterations = colors.length;
    int width = pixels.width;

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
  print("draw time: ${elapsedTime} ms");
}
