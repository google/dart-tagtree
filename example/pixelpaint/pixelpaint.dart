import 'package:tagtree/browser.dart';
import 'package:tagtree/core.dart';

/// A paint app implemented on top of an HTML table.
///
/// Demonstrates how to get decent performance using a mostly functional style,
/// assuming that most pixels don't actually change in a single animation frame.
/// The paint document is modelled as an immutable [Grid]. A top-level state
/// machine in [PixelPaintApp] reacts to document updates. We avoid unnecessary
/// renders by dividing up the Grid and [GridView] by row and only rendering a
/// [RowView] if there is a change to the underlying [Row]. (A more sophisticated
/// paint program would probably divide up the grid into tiles.)

//
// Views
//

class PixelPaintApp extends AnimatedView<Grid> {
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
  get firstState => new Grid(width, height);

  @override
  renderFrame(Place p) {

    onPaint(int x, int y) {
      p.nextState = new Grid.withChangedPixel(p.nextState, x, y, 1);
    }

    return new GridView(grid: p.state, palette: p.view.palette, onPaint: onPaint);
  }
}

/// A handler that's called when the user paints a pixel.
typedef PixelHandler(int x, int y);

/// The specification of a single animation frame that displays the grid of pixels.
/// It expands to a <table> element.
class GridView extends View {
  final Grid grid;
  final List<String> palette;
  final PixelHandler onPaint;

  const GridView({this.grid, this.palette, this.onPaint});

  @override
  get animator => const _GridView();
}

/// Renders a stream of GridViews and converts mouse events into paint events.
/// (This could be a template, except that we need to remember whether the mouse
/// button is down. TODO: it might be nice if Dart or TagTree provided this.)
class _GridView extends Animator<GridView, bool> {

  // HTML5 makes keeping track of the mouse button surprisingly tricky!
  // This implementation usually works, but could be improved.

  const _GridView();

  @override
  makePlace(PlaceImpl impl, _) => new MousePlace(impl);

  @override
  firstState(_) => throw "not used";

  @override
  View renderFrame(MousePlace p) {

    onMouseDown(int x, int y) {
      p.view.onPaint(x, y);
      p.isMouseDown = true;
    }

    onMouseOver(int x, int y) {
      if (p.isMouseDown) {
        p.view.onPaint(x, y);
      }
    }

    onMouseUp() {
      p.isMouseDown = false;
    }

    var palette = p.view.palette.asMap();
    var rows = [];
    for (int y = 0; y < p.view.grid.height; y++) {
      rows.add(new RowView(y: y, row: p.view.grid.rows[y], palette: palette,
                           onMouseDown: onMouseDown, onMouseOver: onMouseOver,
                           onMouseUp: onMouseUp));
    }
    return $.Table(clazz: "grid", inner: rows,
        onMouseUp: (_) => onMouseUp(),
        onMouseOut: (_) => onMouseUp() // Try to avoid a "stuck" mouse button
    );
  }
}

class MousePlace extends Place {
  // This variable is unused when rendering, so it shouldn't be stored as state.
  bool isMouseDown = false;
  MousePlace(PlaceImpl impl) : super(impl, false);
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
class Grid implements Cloneable {
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

  @override
  clone() => this;
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


