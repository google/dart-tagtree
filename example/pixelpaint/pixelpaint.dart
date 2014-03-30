import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

final $ = new Tags();

void main() {
  root("#container").mount(new PixelPaint(50, 50));
}

class PixelPaint extends Widget<Grid> {
  PixelPaint(int width, int height) : super({#width: width, #height: height});

  get firstState => new Grid(props.width, props.height);

  void onPaint(int x, int y) {
    nextState.set(x, y, 1);
  }

  View render() => new GridView(state, onPaint);
}

typedef PixelHandler(int x, int y);

class GridView extends Widget<ViewState> {
  GridView(Grid g, PixelHandler onPaint) : super({#grid: g, #onPaint: onPaint}) {
    assert(g != null);
    assert(onPaint != null);
  }

  get firstState => new ViewState();

  PixelHandler get onPaint => props.onPaint;

  void onMouseDown(int x, int y) {
    onPaint(x, y);
    nextState.mouseDown = true;
  }

  void onMouseOver(int x, int y) {
    if (nextState.mouseDown) {
      onPaint(x, y);
    }
  }

  void onMouseUp() {
    nextState.mouseDown = false;
  }

  @override
  View render() {
    Grid grid = props.grid;
    var rows = [];
    for (int y = 0; y < grid.height; y++) {
      rows.add(new RowView(y, grid.rows[y], onMouseDown, onMouseOver, onMouseUp));
    }
    return $.Table(clazz: "grid", inner: rows,
        onMouseUp: (_) => onMouseUp(),
        onMouseOut: (_) => onMouseUp());
  }
}

class RowView extends Widget {
  RowView(int y, Row row,
      PixelHandler onMouseDown, PixelHandler onMouseOver, Function onMouseUp):
    super({#y: y, #row: row,
      #onMouseDown: onMouseDown, #onMouseOver: onMouseOver, #onMouseUp: onMouseUp});

  @override
  bool shouldUpdate(Widget next) {
    return !props.row.equals(next.props.row);
  }

  @override
  View render() {
    Row row = props.row;
    PixelHandler onMouseDown = props.onMouseDown;
    PixelHandler onMouseOver = props.onMouseOver;
    Function onMouseUp = props.onMouseUp;
    var cells = [];
    for (int x = 0; x < row.width; x++) {
      int pixel = row[x];
      cells.add($.Td(clazz: palette[pixel],
          onMouseDown: (_) => onMouseDown(x, props.y),
          onMouseOver: (_) => onMouseOver(x, props.y),
          onMouseUp: (_) => onMouseUp()));
    }
    return $.Tr(inner: cells);
  }
}

class ViewState extends State {
  bool mouseDown = false;
  @override
  ViewState clone() => new ViewState()..mouseDown = mouseDown;
}

final palette = <int, String>{0: "black", 1: "white"};

class Grid extends State {
  final List<Row> rows;

  Grid._raw(this.rows);

  Grid.from(Grid prev) : rows = prev.rows.map((Row r) => new Row.from(r)).toList(growable: false);

  factory Grid(int width, int height) {
    var rows = new List<Row>(height);
    for (int i = 0; i < height; i++) {
      rows[i] = new Row(width);
    }
    return new Grid._raw(rows);
  }

  int get width => rows[0].width;

  int get height => rows.length;

  int get(int x, int y) => rows[y][x];

  void set(int x, int y, int pixel) {
    rows[y][x] = pixel;
  }

  @override
  State clone() => new Grid.from(this);
}

class Row {
  List<int> pixels;
  bool dirty;

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

  Iterable map(Function f) => pixels.map(f);
}
