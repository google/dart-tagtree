import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new AppTags();

main() {
  root("#container").mount($.PixelPaint(width: 50, height: 50, palette: ["black", "white"]));
}

abstract class CustomTags {
  /// Creates a black and white image editor with the given width and height in fat pixels.
  PixelPaint({width, height, palette});

  /// Shows the grid and reports paint events when the user paints a pixel.
  GridView({grid, palette, onPaint});

  /// Shows a single row in the grid and reports mouse events on each pixel in the row.
  RowView({y, row, palette, onMouseDown, onMouseOver, onMouseUp});
}

class AppTags extends TagMaker implements CustomTags {
  AppTags() {
    defineWidget(method: #PixelPaint, create: () => new _PixelPaint());

    defineWidget(method: #GridView, create: () => new _GridView());

    defineTemplate(method: #RowView,
      shouldUpdate: (props, next) => !props.row.equals(next.row),
      render: ({int y, Row row, Map<int, String> palette,
               PixelHandler onMouseDown, PixelHandler onMouseOver, Function onMouseUp}) {
        var cells = [];
        for (int x = 0; x < row.width; x++) {
          int pixel = row[x];
          cells.add($.Td(clazz: palette[pixel],
              onMouseDown: (_) => onMouseDown(x, y),
              onMouseOver: (_) => onMouseOver(x, y),
              onMouseUp: (_) => onMouseUp()));
        }
        return $.Tr(inner: cells);
      });
  }

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

/// Updates the model and re-renders whenever the user paints a pixel.
class _PixelPaint extends Widget<Grid> {
  int width;
  int height;

  // A list of CSS styles to use for the pixels.
  List<String> palette;

  onPropsChange({width, height, palette}) {
    this.width = width;
    this.height = height;
    this.palette = palette;
  }

  @override
  Grid createFirstState() => new Grid(width, height);

  void onPaint(int x, int y) => nextState.set(x, y, 1);

  Tag render() => $.GridView(grid: state, palette: palette.asMap(), onPaint: onPaint);

  Grid cloneState(Grid prev) => new Grid.from(prev);
}

/// A handler that receives the coordinates of a pixel.
typedef PixelHandler(int x, int y);

/// The GridView draws the grid and also converts mouse events into pixel paint events.
/// (The DOM's event API makes it tricky to reliably determine when the mouse is down.
/// This implementation usually works but could be improved.)
class _GridView extends Widget<bool> {
  Grid grid;
  Map<int, String> palette;
  PixelHandler onPaint;

  onPropsChange({grid, palette, onPaint}) {
    this.grid = grid;
    this.palette = palette;
    this.onPaint = onPaint;
  }

  @override
  bool createFirstState() => false; // assume mouse is up

  bool get mouseDown => nextState;
  set mouseDown(bool next) => nextState = next;

  void onMouseDown(int x, int y) {
    onPaint(x, y);
    mouseDown = true;
  }

  void onMouseOver(int x, int y) {
    if (mouseDown) {
      onPaint(x, y);
    }
  }

  void onMouseUp() {
    mouseDown = false;
  }

  @override
  Tag render() {
    var rows = [];
    for (int y = 0; y < grid.height; y++) {
      rows.add($.RowView(y: y, row: grid.rows[y], palette: palette,
        onMouseDown: onMouseDown, onMouseOver: onMouseOver, onMouseUp: onMouseUp));
    }
    return $.Table(clazz: "grid", inner: rows,
        onMouseUp: (_) => onMouseUp(),
        // Try to avoid a "stuck" mouse button due to not detecting a mouseUp outside the grid.
        onMouseOut: (_) => onMouseUp());
  }
}

/// A Grid of ints that can be mutated and efficiently cloned.
class Grid {
  final List<Row> rows;

  Grid._raw(this.rows);

  /// Clone the grid.
  Grid.from(Grid prev) : rows = prev.rows.map((Row r) => new Row.from(r)).toList(growable: false);

  /// Creates an empty grid of zeros.
  factory Grid(int width, int height) {
    var rows = new List<Row>(height);
    for (int i = 0; i < height; i++) {
      rows[i] = new Row(width);
    }
    return new Grid._raw(rows);
  }

  int get width => rows[0].width;
  int get height => rows.length;

  void set(int x, int y, int pixel) {
    rows[y][x] = pixel;
  }
}

/// A row of ints that can be mutated and efficiently cloned.
/// (We use copy-on-write to make cloning faster.)
class Row {
  List<int> pixels;
  bool dirty; // If dirty is false, we must clone before mutating.

  Row(int width) {
    pixels = new List<int>.filled(width, 0);
    dirty = true;
  }

  Row.from(Row prev) {
    pixels = prev.pixels;
    dirty = false;
  }

  bool equals(Row next) {
    if (pixels == next.pixels) {
      return true;
    }
    if (pixels.length != next.pixels.length){
      return false;
    }
    for (int i = 0; i < pixels.length; i++) {
      if (pixels[i] != next.pixels[i]) {
        return false;
      }
    }
    return true;
  }

  int get width => pixels.length;

  int operator[](int index) => pixels[index];

  void operator[]=(int index, int pixel) {
    if (!dirty) {
      pixels = new List.from(pixels, growable: false);
      dirty = true;
    }
    pixels[index] = pixel;
  }
}
