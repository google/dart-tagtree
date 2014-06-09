import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

/// A simple paint widget implemented on an HTML table.
/// Demonstrates how to get good performance using a (somewhat) functional style,
/// with an immutable grid model at the top level of the app.
/// (There is one view per row of pixels, but they are mostly not updated.)

//
// View (and controller)
//

/// Embeds a paint program. (Two colors only, with fat pixels.)
class PixelPaintApp extends View {
  final int width; // in fat pixels
  final int height; // in fat pixels
  final List<String> palette; // The CSS style for each color
  const PixelPaintApp({this.width, this.height, this.palette});
  bool check() => palette.length == 2;
}

/// Implements the top-level state machine.
/// (Updates the model and renders the view when something happens.)
class _PixelPaint extends Widget<PixelPaintApp, Grid> {

  @override
  createFirstState() => new Grid(props.width, props.height);

  onPaint(int x, int y) {
    nextState = new Grid.withChangedPixel(state, x, y, 1);
  }

  @override
  render() => new GridView(grid: state, palette: props.palette, onPaint: onPaint);
}

/// One animation frame showing the paint widget's grid of pixels.
/// Expands to a <table> tag.
/// (The implementation has state, but it's just for event handling.)
class GridView extends View {
  final Grid grid;
  final List<String> palette;
  final PixelHandler onPaint;
  const GridView({this.grid, this.palette, this.onPaint});
}

/// A handler that's called when the user paints a pixel.
typedef PixelHandler(int x, int y);

/// Draws the grid and converts mouse events.
class _GridView extends Widget<GridView, bool> {

  // Keep track of whether the mouse is down and report paint events.
  // (The DOM makes this tricky!)
  // This implementation usually works, but could be improved.

  @override
  createFirstState() => false; // assume mouse is up

  get mouseDown => nextState;
  set mouseDown(bool next) => nextState = next;

  onMouseDown(int x, int y) {
    props.onPaint(x, y);
    mouseDown = true;
  }

  onMouseOver(int x, int y) {
    if (mouseDown) {
      props.onPaint(x, y);
    }
  }

  onMouseUp() {
    mouseDown = false;
  }

  @override
  View render() {
    var palette = props.palette.asMap();
    var rows = [];
    for (int y = 0; y < props.grid.height; y++) {
      rows.add(new RowView(y: y, row: props.grid.rows[y], palette: palette,
                           onMouseDown: onMouseDown, onMouseOver: onMouseOver,
                           onMouseUp: onMouseUp));
    }
    return $.Table(clazz: "grid", inner: rows,
        onMouseUp: (_) => onMouseUp(),
        onMouseOut: (_) => onMouseUp() // Try to avoid a "stuck" mouse button
    );
  }
}

/// An animation frame for one row of the grid.
/// Expands to a <tr> tag.
class RowView extends View {
  final int y;
  final Row row;
  final Map<int, String> palette;
  final PixelHandler onMouseDown;
  final PixelHandler onMouseOver;
  final Function onMouseUp;

  const RowView({this.y, this.row, this.palette,
    this.onMouseOver, this.onMouseDown, this.onMouseUp});
}

final rowViewTemplate = new Template((RowView rv) {
    var cells = [];
    for (int x = 0; x < rv.row.width; x++) {
      int pixel = rv.row[x];
      cells.add($.Td(clazz: rv.palette[pixel],
          onMouseDown: (_) => rv.onMouseDown(x, rv.y),
          onMouseOver: (_) => rv.onMouseOver(x, rv.y),
          onMouseUp: (_) => rv.onMouseUp()));
    }
    return $.Tr(inner: cells);
  },
  /// Avoid redrawing a row that hasn't changed. (The key to good performance!)
  shouldRender: (RowView before, RowView after) => !before.row.equals(after.row)
);

//
// Model
//

/// A immutable rectangle of integers.
class Grid {
  final List<Row> rows;
  Grid._raw(this.rows);

  /// Creates an empty grid of zeros.
  factory Grid(int width, int height) {
    var rows = new List<Row>(height);
    for (int i = 0; i < height; i++) {
      rows[i] = new Row(width);
    }
    return new Grid._raw(rows);
  }

  /// Creates a new grid with the given pixel changed.
  /// (We only create new rows when they have changed.)
  factory Grid.withChangedPixel(Grid prev, int x, int y, int pixel) {
    Row toChange = prev.rows[y];
    if (toChange[x] == pixel) {
      return prev; // nothing to do
    }
    var rows =
        prev.rows.map((r) => r==toChange ? new Row.withChangedPixel(r, x, pixel) : r)
        .toList(growable: false);
    return new Grid._raw(rows);
  }

  int get width => rows[0].width;
  int get height => rows.length;
}

/// An immutable array of integers, representing a row of pixels.
class Row {
  final List<int> pixels;
  Row._raw(this.pixels);

  Row(int width) : pixels = new List<int>.filled(width, 0);

  /// Creates a new row with the given pixel changed.
  factory Row.withChangedPixel(Row prev, int x, int pixel) {
    var pixels = new List.from(prev.pixels, growable: false);
    pixels[x] = pixel;
    return new Row._raw(pixels);
  }

  /// Checks whether any pixels have changed.
  /// (This needs to be fast when the Row hasn't changed.)
  bool equals(Row other) {
    if (this == other) {
      return true;
    }
    if (pixels.length != other.pixels.length) {
      return false;
    }
    for (int i = 0; i < pixels.length; i++) {
      if (pixels[i] != other.pixels[i]) {
        return false;
      }
    }
    return true;
  }

  int get width => pixels.length;

  int operator [](int index) => pixels[index];
}

//
// Put it all together.
//

final app = const PixelPaintApp(
    width: 50,
    height: 50,
    palette: const ["black", "white"]);

final theme = new Theme($)
    ..define(PixelPaintApp, () => new _PixelPaint())
    ..define(GridView, () => new _GridView())
    ..define(RowView, () => rowViewTemplate);

main() => getRoot("#container").mount(app, theme);


