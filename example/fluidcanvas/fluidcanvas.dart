import 'dart:html';
import 'package:tagtree/browser.dart';

class Demo extends AnimatedTag implements Resizable<Demo> {
  final num width;
  final num height;
  const Demo({this.width, this.height});

  Demo resize(num width, num height) {
    return new Demo(width: width, height: height);
  }

  start() => new Place(false);

  renderAt(Place p) {
    var canvas = new Ref<CanvasElement>();
    p.onRendered = (Place p) {
      var ctx = canvas.elt.context2D;
      ctx.fillStyle = "#888";
      ctx.fillRect(0,  0,  width,  height);
      ctx.clearRect(1,  1,  width - 2, height - 2);
    };

    return $.Canvas(width: width, height: height, ref: canvas);
  }
}

main() =>
    getRoot("#container")
      .mount(new ResizeZone(const Demo()));
