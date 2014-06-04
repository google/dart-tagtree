import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

final $ = new HtmlTagSet();

class PixelPaint extends View {
  @override
  get tag => "PixelPaint";

  final int width;
  final int height;
  final List<String> palette;
  const PixelPaint({this.width, this.height, this.palette});
}

class GridView extends View {
  @override
  get tag => "GridView";

  final Grid grid;
  final Map<int, String> palette;
  final PixelHandler onPaint;
  const GridView({this.grid, this.palette, this.onPaint});
}

class RowView extends View {
  @override
  get tag => "RowView";

  final int y;
  final Row row;
  final Map<int, String> palette;
  final PixelHandler onMouseDown;
  final PixelHandler onMouseOver;
  final Function onMouseUp;
  const RowView({this.y, this.row, this.palette,
    this.onMouseOver, this.onMouseDown, this.onMouseUp});
}

main() => root("#container")
    ..theme = theme
    ..mount(const PixelPaint(width: 50, height: 50, palette: const ["black", "white"]));

final theme = new Theme($)
    ..defineWidget("PixelPaint", () => new _PixelPaint())
    ..defineWidget("GridView", () => new _GridView())
    ..defineTemplate("RowView", renderRowView,
        shouldRender: (RowView before, RowView after) => !before.row.equals(after.row));

/// Updates the model and re-renders whenever the user paints a pixel.
class _PixelPaint extends Widget<PixelPaint, Grid> {
  PixelPaint view;

  @override
  setProps(PixelPaint view) {
    this.view = view;
  }

  @override
  Grid createFirstState() => new Grid(view.width, view.height);

  void onPaint(int x, int y) => nextState.set(x, y, 1);

  @override
  View render() => new GridView(grid: state, palette: view.palette.asMap(), onPaint: onPaint);

  @override
  Grid cloneState(Grid prev) => new Grid.from(prev);
}

/// A handler that receives the coordinates of a pixel.
typedef PixelHandler(int x, int y);

/// The GridView draws the grid and also converts mouse events into pixel paint events.
/// (The DOM's event API makes it tricky to reliably determine when the mouse is down.
/// This implementation usually works but could be improved.)
class _GridView extends Widget<GridView, bool> {
  GridView view;

  @override
  setProps(GridView view) {
    this.view = view;
  }

  @override
  bool createFirstState() => false; // assume mouse is up

  bool get mouseDown => nextState;
  set mouseDown(bool next) => nextState = next;

  void onMouseDown(int x, int y) {
    view.onPaint(x, y);
    mouseDown = true;
  }

  void onMouseOver(int x, int y) {
    if (mouseDown) {
      view.onPaint(x, y);
    }
  }

  void onMouseUp() {
    mouseDown = false;
  }

  @override
  View render() {
    var rows = [];
    for (int y = 0; y < view.grid.height; y++) {
      rows.add(new RowView(y: y, row: view.grid.rows[y], palette: view.palette,
                           onMouseDown: onMouseDown, onMouseOver: onMouseOver,
                           onMouseUp: onMouseUp));
    }
    return $.Table(clazz: "grid", inner: rows, onMouseUp: (_) => onMouseUp(),
        // Try to avoid a "stuck" mouse button due to not detecting a mouseUp outside the grid.
    onMouseOut: (_) => onMouseUp());
  }
}

View renderRowView(RowView rv) {
  var cells = [];
  for (int x = 0; x < rv.row.width; x++) {
    int pixel = rv.row[x];
    cells.add($.Td(clazz: rv.palette[pixel],
        onMouseDown: (_) => rv.onMouseDown(x, rv.y),
        onMouseOver: (_) => rv.onMouseOver(x, rv.y),
        onMouseUp: (_) => rv.onMouseUp()));
  }
  return $.Tr(inner: cells);
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
    if (pixels.length != next.pixels.length) {
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

  int operator [](int index) => pixels[index];

  void operator []=(int index, int pixel) {
    if (!dirty) {
      pixels = new List.from(pixels, growable: false);
      dirty = true;
    }
    pixels[index] = pixel;
  }
}
