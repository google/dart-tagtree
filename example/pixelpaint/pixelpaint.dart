library pixelpaint;

import 'package:tagtree/common.dart';
import 'package:tagtree/core.dart';
import 'package:tagtree/html.dart';

final $ = new HtmlTagSet();

/// A paint app implemented on top of an HTML table.
///
/// Demonstrates how to split up a TagTree app between client and server.
/// (There is no reason to do this for a paint app, but it can be used to test
/// performance.)
///
/// Also demonstrates how to get decent performance using a mostly functional style
/// (when not running client-server).

//
// Views
//

/// A tag that requests that the PixelPaintApp should run.
/// (Can be sent from client to server to start up the app.)
class PixelPaintApp extends Tag implements Jsonable {
  final int width; // in fat pixels
  final int height; // in fat pixels
  final List<String> palette; // The CSS style for each color

  const PixelPaintApp({
    this.width: 50,
    this.height: 50,
    this.palette: const ["pix-black", "pix-white"]
  });

  @override
  bool checked() => palette.length == 2;

  /// This is used when not running client-server.
  @override
  Animator get animator => const PixelPaintAnimator();

  @override
  get jsonType => $jsonType;
  static const $jsonType = const JsonType("PixelPaintApp", toMap, fromMap);

  static toMap(PixelPaintApp app) => {
    "width": app.width,
    "height": app.height,
    "palette": app.palette
  };

  static fromMap(Map m) => new PixelPaintApp(
      width: m["width"],
      height: m["height"],
      palette: m["palette"]
  );
}

/// Runs the main loop of the PixelPaint app.
/// (This animator can run on the server.)
class PixelPaintAnimator extends Animator<PixelPaintApp, Grid> {
  const PixelPaintAnimator();

  @override
  start(PixelPaintApp input) => new Place(new Grid(input.width, input.height));

  @override
  renderAt(Place<Grid> p, PixelPaintApp input) {

    onPaint(int x, int y) {
      p.nextState = new Grid.withChangedPixel(p.nextState, x, y, 1);
    }

    return new GridView(grid: p.state, palette: input.palette, onPaint: onPaint);
  }
}

typedef PaintHandler(int x, int y);

/// A single animation frame that renders the PixelPaint app's UI.
/// (When running client-server, these frames are streamed from from server to client.)
class GridView extends Tag implements Jsonable {
  final Grid grid;
  final List<String> palette;
  final PaintHandler onPaint;
  const GridView({this.grid, this.palette, this.onPaint});

  @override
  Animator get animator => const GridAnimator();

  @override
  JsonType get jsonType => $jsonType;
  static const $jsonType = const JsonType("GridView", toMap, fromMap);

  static Map toMap(GridView v) => {
    "grid": v.grid,
    "palette": v.palette,
    "onPaint": v.onPaint,
  };

  static GridView fromMap(Map<String, dynamic> map) {
    // onPaint is a RemoteFunction and must be wrapped in an actual function
    var onPaint = map["onPaint"];
    return new GridView(
          grid: map["grid"],
          palette: map["palette"],
          onPaint: (x, y) => onPaint(x, y));
  }
}

/// Renders a stream of [GridView] into a <table> and converts mouse events into onPaint calls.
/// (This could be a template, except that we need to remember whether the mouse
/// button is down.)
class GridAnimator extends Animator<GridView, bool> {
  const GridAnimator();

  @override
  start(_) => new MousePlace();

  @override
  Tag renderAt(MousePlace p, GridView input) {

    // HTML5 makes keeping track of the mouse button surprisingly tricky!
    // This implementation usually works, but could be improved.

    onMouseDown(int x, int y) {
      input.onPaint(x, y);
      p.isMouseDown = true;
    }

    onMouseOver(int x, int y) {
      if (p.isMouseDown) {
        input.onPaint(x, y);
      }
    }

    onMouseUp() {
      p.isMouseDown = false;
    }

    var paletteMap = input.palette.asMap();
    var rows = [];
    for (int y = 0; y < input.grid.height; y++) {
      rows.add(new RowView(y: y, row: input.grid.rows[y], palette: paletteMap,
                           onMouseDown: onMouseDown, onMouseOver: onMouseOver,
                           onMouseUp: onMouseUp));
    }
    return $.Div(inner: [
      $.H2(inner: "PixelPaint Demo"),
      $.Table(clazz: "pix-grid", inner: rows,
          onMouseUp: (_) => onMouseUp(),
          onMouseOut: (_) => onMouseUp() // Try to avoid a "stuck" mouse button
      )
    ]);
  }
}

class MousePlace extends Place {
  // This variable isn't used when rendering, so it shouldn't be stored as [state].
  // TODO: it might be nice if Dart or TagTree provided mouse button tracking.
  bool isMouseDown = false;
  MousePlace() : super(false); // state is unused
}

/// An animation frame for one row of the grid.
/// Expands to a <tr> tag.
class RowView extends TemplateTag {
  final int y;
  final Row row;
  final Map<int, String> palette;
  final Function onMouseDown;
  final Function onMouseOver;
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

/// An immutable rectangle of pixels.
class Grid implements Cloneable, Jsonable {
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
  checked() {
    if (rows.isEmpty) {
      return true;
    }
    int width = rows.first.width;
    for (Row row in rows) {
      if (row.width != width) {
        throw "grid isn't rectangular";
      }
    }
    return true;
  }

  @override
  clone() => this;

  @override
  get jsonType => $jsonType;

  static const $jsonType = const JsonType("Grid", toJson, fromJson);

  static toJson(Grid g) => g.rows.map((Row r) => r.pixels).toList();

  static fromJson(List<List<int>> pixels) {
    var rows = pixels.map((pix) => new Row._raw(pix)).toList();
    return new Grid._raw(rows);
  }
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



