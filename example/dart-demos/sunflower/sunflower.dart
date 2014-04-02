// Original:
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ported to ViewTree by Brian Slesinsky

library sunflower;

import 'dart:html';
import 'dart:math';
import 'package:viewtree/core.dart';
import 'package:viewtree/browser.dart';

void main() {
  root("#sunflower").mount(Sunflower(startSeeds: 500, seedRadius: 2));
}

final $ = new Tags();

final Sunflower = defineWidget(
    props: ({int startSeeds, num seedRadius}) => true,
    state: (p) => p.startSeeds,
    widget: () => new _Sunflower()
);

const num TAU = PI * 2;
final num PHI = (sqrt(5) + 1) / 2;

class _Sunflower extends Widget<int> {
  final _canvas = new ElementRef<CanvasElement>();

  _Sunflower() {
    didMount.listen((_) => draw());
    didUpdate.listen((_) => draw());
  }

  int get seeds => state;

  void onChange(ChangeEvent e) {
    nextState = int.parse(e.value);
  }

  int get maxD => 300;
  int get centerX => maxD ~/ 2;
  int get centerY => maxD ~/ 2;

  @override
  Tag render() {
    return $.Div(inner: [

        $.Div(id: "container", inner: [
            $.Canvas(width: maxD, height: maxD, clazz: "center", ref: _canvas),
            $.Form(clazz: "center", inner: [
                $.Input(type: "range", max: 1000, value: seeds, onChange: onChange)
            ]),
            $.Img(src: "math.png", width: "350px", height: "42px", clazz: "center")
        ]),

        $.Footer(inner: [
            $.P(id: "notes", inner: "${seeds} seeds")
        ]),
    ]);
  }

  /// Draw the complete figure for the current number of seeds.
  void draw() {
    CanvasRenderingContext2D context = _canvas.elt.context2D;
    num scaleFactor = props.seedRadius * 2;
    context.clearRect(0, 0, maxD, maxD);
    for (var i = 0; i < seeds; i++) {
      final num theta = i * TAU / PHI;
      final num r = sqrt(i) * scaleFactor;
      drawSeed(context, centerX + r * cos(theta), centerY - r * sin(theta), props.seedRadius);
    }
  }

  /// Draw a small circle representing a seed centered at (x,y).
  void drawSeed(CanvasRenderingContext2D context, num x, num y, num radius) {
    context..beginPath()
           ..lineWidth = 2
           ..fillStyle = "orange"
           ..strokeStyle = "orange"
           ..arc(x, y, radius, 0, TAU, false)
           ..fill()
           ..closePath()
           ..stroke();
  }
}


