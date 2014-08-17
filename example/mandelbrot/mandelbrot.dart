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
  final Camera startCam;
  final CameraChangeHandler onCameraChange;

  const MandelbrotApp({this.startCam: Camera.start, this.onCameraChange});

  @override
  Place start() => new Place(startCam);

  @override
  bool shouldRestart(Place<Camera> p, AnimatedTag prev) {
    return startCam != p.nextState;
  }

  @override
  Tag renderAt(Place<Camera> p) {

    void step(Camera next) {
      if (onCameraChange != null) {
        onCameraChange(next);
      }
      p.nextState = next;
    }

    void onDrag(Point newCenter) => step(p.nextState.pan(newCenter));

    void zoom(num scaleAmount) => step(p.nextState.zoom(scaleAmount));

    return $.Div(inner: [
      new MandelbrotView(grid: new Grid(p.state), onDrag: onDrag),
      $.Div(inner: [
        $.Button(onClick: (_) => zoom(0.5), inner: "Zoom In"),
        $.Button(onClick: (_) => zoom(2.0), inner: "Zoom Out"),
      ]),
      $.Div(inner: "Drag image to recenter")
    ]);
  }
}

typedef DragHandler(Point newCenter);

class MandelbrotView extends Tag {
  final Grid grid;
  final List<Color> colors;
  final DragHandler onDrag;

  MandelbrotView({
    this.grid,
    List<Color> colors,
    this.onDrag
  }) : this.colors = (colors == null) ? defaultColors : colors;

  @override
  get animator => const _MandelbrotView();

  @override
  bool operator==(Object other) {
    if (other is MandelbrotView) {
      bool result = grid == other.grid &&
          colors == other.colors &&
          onDrag == other.onDrag;
      return result;
    }
    return false;
  }

  @override
  int get hashCode => grid.hashCode;

  // A list of 1000 colors that wraps around the color spectrum and fades to black.
  static final List<Color> defaultColors = colorRange(
      new HslColor(0, 80, 70),
      new HslColor(360 * 3, 100, 0),
      1000, _ramp);

  static num _ramp(num x) => sqrt(x);
}

class _MandelbrotView extends Animator<MandelbrotView, RenderRequest> {
  const _MandelbrotView();

  @override
  start(MandelbrotView input) => new DragPlace(new RenderRequest(input.grid, input.colors, fast: true));

  @override
  bool shouldCut(DragPlace p, MandelbrotView input, nextInput, nextAnim) => p.drag == null;

  @override
  Tag renderAt(DragPlace<RenderRequest> p, MandelbrotView input) {
    RenderRequest req = p.state;

    onMouseDown(HandlerEvent e) {
      p.drag = new DragStart(e.value, req.grid);
    }

    onMouseMove(HandlerEvent e) {
      if (p.drag != null) {
        p.nextState = new RenderRequest(p.drag.getDraggedGrid(e.value), req.colors, fast: true);
      }
    }

    onMouseUp() {
      if (p.drag != null) {
        input.onDrag(p.nextState.grid.center);
      }
      p.drag = null;
    }

    // Ask for a callback when the DOM is ready.
    var canvas = new Ref<CanvasElement>();
    p.onRendered = (_) {
      req.render(canvas.elt.context2D);
      if (req.fast && p.drag == null) {
        p.nextState = new RenderRequest(req.grid, req.colors, fast: false);
      }
    };

    return $.Canvas(width: req.grid.width, height: req.grid.height, clazz: "center", ref: canvas,
      onMouseDown: onMouseDown, onMouseMove: onMouseMove, onMouseUp: (_) => onMouseUp(),
      onMouseOut: (_) => onMouseUp() // Try to avoid a "stuck" mouse button
    );
  }
}

class DragPlace<T> extends Place<T> {
  DragStart drag;
  DragPlace(T firstState) : super(firstState);
}

class DragStart {
  final MousePosition startPos;
  final Grid startGrid;
  DragStart(this.startPos, this.startGrid);

  Grid getDraggedGrid(MousePosition pos) {
    int dx = pos.x - startPos.x;
    int dy = pos.y - startPos.y;
    double dReal = dx * startGrid.pixelSize;
    double dImag = -dy * startGrid.pixelSize;
    return startGrid.drag(dReal, dImag);
  }
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
    .mount(new MandelbrotApp(startCam: camera, onCameraChange: updateCamera));
}

main() {
  render();
  window.onHashChange.listen((_) {
    lastSaved = null;
    render();
  });
}
