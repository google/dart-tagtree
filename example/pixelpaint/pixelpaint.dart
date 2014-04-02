import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

void main() {
  root("#container").mount(PixelPaint(width: 50, height: 50));
}

final $ = new Tags();

final PixelPaint = defineWidget(
    props: ({int width, int height}) => true,
    state: (p) => new Grid(p.width, p.height),
    widget: () => new PixelPaintWidget()
);

typedef PixelHandler(int x, int y);

final GridView = defineWidget(
    props: ({Grid grid, PixelHandler onPaint}) => true,
    state: (_) => false, // mouse not down
    widget: () => new GridViewWidget()
);

final RowView = defineTemplate(
  shouldUpdate: (props, next) => !props.row.equals(next.row),
  render: ({int y, Row row,
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
  }
);

class PixelPaintWidget extends Widget<Grid> {

  void onPaint(int x, int y) {
    nextState.set(x, y, 1);
  }

  Tag render() => GridView(grid: state, onPaint: onPaint);

  Grid cloneState(Grid prev) => new Grid.from(prev);
}

class GridViewWidget extends Widget<bool> {

  bool get mouseDown => nextState;

  PixelHandler get onPaint => props.onPaint;

  void onMouseDown(int x, int y) {
    onPaint(x, y);
    nextState = true;
  }

  void onMouseOver(int x, int y) {
    if (mouseDown) {
      onPaint(x, y);
    }
  }

  void onMouseUp() {
    nextState = false;
  }

  @override
  Tag render() {
    Grid grid = props.grid;
    var rows = [];
    for (int y = 0; y < grid.height; y++) {
      rows.add(RowView(y: y, row: grid.rows[y],
        onMouseDown: onMouseDown, onMouseOver: onMouseOver, onMouseUp: onMouseUp));
    }
    return $.Table(clazz: "grid", inner: rows,
        onMouseUp: (_) => onMouseUp(),
        onMouseOut: (_) => onMouseUp());
  }
}

final palette = <int, String>{0: "black", 1: "white"};

class Grid {
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
