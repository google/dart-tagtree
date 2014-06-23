// Original:
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ported to TagTree by Brian Slesinsky

library sunflower;

import 'dart:html';
import 'dart:math';
import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class SunflowerApp extends View {
  final int startSeeds;
  final int seedRadius;

  const SunflowerApp({this.startSeeds, this.seedRadius});

  @override
  get animation => new _SunflowerApp();
}

class _SunflowerApp extends Widget<SunflowerApp, int> {
  final canvas = new Ref<CanvasElement>();

  // The slider controls the number of seeds.

  @override
  getFirstState(SunflowerApp view) => view.startSeeds;

  get seeds => state;

  void onSliderChange(HandlerEvent e) {
    nextState = int.parse(e.value);
  }

  @override
  View render() {
    return $.Div(inner: [

        $.Div(id: "container", inner: [
            $.Canvas(width: maxD, height: maxD, clazz: "center", ref: canvas),
            $.Form(clazz: "center", inner: [
                $.Input(type: "range", max: 1000, value: seeds, onChange: onSliderChange)
            ]),
            $.Img(src: "math.png", width: "350px", height: "42px", clazz: "center")
        ]),

        $.Footer(inner: [
            $.P(id: "notes", inner: "${seeds} seeds")
        ]),
    ]);
  }

  @override
  OnRendered get onRendered => () => draw(canvas.elt.context2D);

  static const num TAU = PI * 2;
  static final num PHI = (sqrt(5) + 1) / 2;
  static const maxD = 300;
  static const centerX = maxD ~/ 2;
  static const centerY = maxD ~/ 2;

  /// Draw the complete figure for the current number of seeds.
  void draw(CanvasRenderingContext2D context) {
    num scaleFactor = view.seedRadius * 2;
    context.clearRect(0, 0, maxD, maxD);
    for (var i = 0; i < seeds; i++) {
      final num theta = i * TAU / PHI;
      final num r = sqrt(i) * scaleFactor;
      drawSeed(context, centerX + r * cos(theta), centerY - r * sin(theta), view.seedRadius);
    }
  }

  /// Draw a small circle representing a seed centered at (x,y).
  static void drawSeed(CanvasRenderingContext2D context, num x, num y, num radius) {
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

const app = const SunflowerApp(startSeeds: 500, seedRadius: 2);

main() =>
    getRoot("#sunflower").mount(app);
