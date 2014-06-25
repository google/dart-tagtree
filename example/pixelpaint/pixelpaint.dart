import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

/// A paint app implemented on top of an HTML table.
///
/// Demonstrates how to get decent performance using a somewhat functional style,
/// assuming that most pixels don't actually change in a single animation frame.
/// The paint document is modelled as an immutable [Grid]. A top-level state
/// machine in [_PixelPaintApp] reacts to document updates. We avoid unnecessary
/// renders by dividing up the Grid and [GridView] by row and only rendering a
/// [RowView] if there is a change to the underlying [Row]. (A more sophisticated
/// paint program would probably divide up the grid into tiles.)

//
// Views (which are also controllers)
//

/// The configuration properties of the app ("props").
/// It displays only two colors and displays fat pixels.
class PixelPaintApp extends View {
  final int width; // in fat pixels
  final int height; // in fat pixels
  final List<String> palette; // The CSS style for each color

  const PixelPaintApp({
    this.width: 50,
    this.height: 50,
    this.palette: const ["black", "white"]
  });

  @override
  bool checked() => palette.length == 2;

  @override
  get animation => new _PixelPaintApp();
}

/// The top-level state machine.
/// There is state transition whenever a pixel changes, causing a re-render.
class _PixelPaintApp extends Widget<PixelPaintApp, Grid> {

  @override
  firstState(PixelPaintApp view) => new Grid(view.width, view.height);

  onPaint(int x, int y) {
    var nextGrid = new Grid.withChangedPixel(state, x, y, 1);
    if (nextGrid == state) {
      return; // unchanged; don't need to render.
    }
    nextState = nextGrid; // This triggers a render.
  }

  @override
  render() => new GridView(grid: state, palette: view.palette, onPaint: onPaint);
}

/// The specification of a single animation frame that displays the grid of pixels.
/// It expands to a <table> element.
class GridView extends View {
  final Grid grid;
  final List<String> palette;
  final PixelHandler onPaint;

  const GridView({this.grid, this.palette, this.onPaint});

  @override
  get animation => new _GridView();
}

/// A handler that's called when the user paints a pixel.
typedef PixelHandler(int x, int y);

/// Renders a stream of GridViews and converts mouse events into paint events.
/// (This could be a template, except that we need to remember whether the mouse
/// button is down. TODO: it might be nice if Dart or TagTree provided this.)
class _GridView extends Widget<GridView, bool> {

  // HTML5 makes keeping track of the mouse button surprisingly tricky!
  // This implementation usually works, but could be improved.

  @override
  firstState(_) => false; // assume mouse is up

  get mouseDown => nextState;
  set mouseDown(bool pressed) => nextState = pressed;

  onMouseDown(int x, int y) {
    view.onPaint(x, y);
    mouseDown = true;
  }

  onMouseOver(int x, int y) {
    if (mouseDown) {
      view.onPaint(x, y);
    }
  }

  onMouseUp() {
    mouseDown = false;
  }

  @override
  View render() {
    var palette = view.palette.asMap();
    var rows = [];
    for (int y = 0; y < view.grid.height; y++) {
      rows.add(new RowView(y: y, row: view.grid.rows[y], palette: palette,
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
class RowView extends TemplateView {
  final int y;
  final Row row;
  final Map<int, String> palette;
  final PixelHandler onMouseDown;
  final PixelHandler onMouseOver;
  final Function onMouseUp;

  const RowView({this.y, this.row, this.palette,
    this.onMouseOver, this.onMouseDown, this.onMouseUp});

  /// Avoid redrawing a row that hasn't changed. (The key to good performance!)
  @override
  shouldRender(RowView prev) => !prev.row.equals(row);

  @override
  render() {
    var cells = [];
    for (int x = 0; x < row.width; x++) {
      int pixel = row[x];
      cells.add($.Td(clazz: palette[pixel],
          onMouseDown: (_) => onMouseDown(x, y),
          onMouseOver: (_) => onMouseOver(x, y),
          onMouseUp: (_) => onMouseUp()));
    }
    return $.Tr(inner: cells);
  }
}

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
// Startup.
//

main() =>
    getRoot("#container")
      .mount(const PixelPaintApp());


