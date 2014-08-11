library mandelbrot;

import 'package:tagtree/browser.dart';
import 'dart:html';
import 'dart:math';

part "color.dart";
part "geometry.dart";
part "render.dart";

//
// Views
//

typedef CameraChangeHandler(Camera next);

class MandelbrotApp extends AnimatedTag {
  final Camera startCamera;
  final CameraChangeHandler onCameraChange;

  const MandelbrotApp({this.startCamera: Camera.start, this.onCameraChange});

  @override
  Place start() => new Place(startCamera);

  @override
  bool shouldRestart(Place<Camera> p, AnimatedTag prev) {
    return startCamera != p.nextState;
  }

  @override
  Tag renderAt(Place<Camera> p) {

    void step(Camera next) {
      if (onCameraChange != null) {
        onCameraChange(next);
      }
      p.nextState = next;
    }

    void onClick(Point newCenter) => step(p.nextState.pan(newCenter));

    void zoom(num scaleAmount) => step(p.nextState.zoom(scaleAmount));

    return $.Div(inner: [
      new MandelbrotView(grid: new Grid(p.state), onClick: onClick),
      $.Div(inner: [
        $.Button(onClick: (_) => zoom(0.5), inner: "Zoom In"),
        $.Button(onClick: (_) => zoom(2.0), inner: "Zoom Out"),
      ]),
      $.Div(inner: "Click image to recenter")
    ]);
  }
}

typedef ClickHandler(Point point);

class MandelbrotView extends AnimatedTag {
  final Grid grid;
  final List<Color> colors;
  final ClickHandler onClick;

  MandelbrotView({
    this.grid,
    List<Color> colors,
    this.onClick
  }) : this.colors = (colors == null) ? defaultColors : colors;

  @override
  bool operator==(Object other) {
    if (other is MandelbrotView) {
      bool result = grid == other.grid &&
          colors == other.colors &&
          onClick == other.onClick;
      return result;
    }
    return false;
  }

  @override
  int get hashCode => grid.hashCode;

  @override
  start() => new Place(false);

  @override
  bool shouldRestart(Place<MandelbrotView> p, MandelbrotView prev) => prev != this;

  @override
  Tag renderAt(Place p) {

    // Ask for a callback when the DOM is ready.
    var canvas = new Ref<CanvasElement>();
    p.onRendered = (_) => renderFull(canvas.elt.context2D, grid, colors);

    var convertOnClick = null;
    if (onClick != null) {
      convertOnClick = (HandlerEvent e) {
        MousePosition m = e.value;
        onClick(grid.pixelToPoint(m.x,  m.y));
      };
    }

    return $.Canvas(width: grid.width, height: grid.height, clazz: "center", ref: canvas,
      onClick: convertOnClick);
  }

  // A list of 1000 colors that wraps around the color spectrum and fades to black.
  static final List<Color> defaultColors = colorRange(
      new HslColor(0, 80, 70),
      new HslColor(360 * 3, 100, 0),
      1000, _ramp);

  static num _ramp(num x) => sqrt(x);

  static _makeCssColors(List<Color> input) =>
      input.map((c) => c.toCss()).toList()..add("#000");
}

//
// Persistence (in the URL)
//

Camera loadCamera() {
  var params = <String, double>{};
  if (window.location.hash.isNotEmpty) {
    for (String segment in window.location.hash.substring(1).split("&")) {
      List parts = segment.split("=");
      if (parts.length == 2) {
        var value = double.parse(parts[1], (_) => null);
        if (value != null) {
          params[parts[0]] = value;
        }
      }
    }
  }

  if (params.containsKey("x") && params.containsKey("y") && params.containsKey("r")) {
    return new Camera(new Point(params["x"], params["y"]), params["r"]);
  } else {
    return Camera.start;
  }
}

Camera lastSaved;

updateCamera(Camera next) {
  var newHash = "#x=${next.center.x}&y=${next.center.y}&r=${next.radius}";
  var url = window.location.href;
  if (url.contains("#")) {
    url = url.substring(0, url.indexOf("#"));
  }
  url += newHash;
  if (lastSaved != null && lastSaved.radius == next.radius) {
    window.history.replaceState(null,  "", url);
  } else {
    window.history.pushState(null,  "", url);
  }
  lastSaved = next;
}

render() {
  var camera = loadCamera();
  getRoot("#container")
    .mount(new MandelbrotApp(startCamera: camera, onCameraChange: updateCamera));
}

main() {
  render();
  window.onHashChange.listen((_) {
    lastSaved = null;
    render();
  });
}
