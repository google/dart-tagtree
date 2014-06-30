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

class SunflowerApp extends AnimatedView<int> {
  final int startSeeds;
  final int seedRadius;

  const SunflowerApp({this.startSeeds, this.seedRadius});

  @override
  int get firstState => startSeeds;

  @override
  View renderFrame(Place<int> p) {
    int seeds = p.state;

    // The slider controls the number of seeds.
    void onSliderChange(HandlerEvent e) {
      p.nextState = int.parse(e.value);
    }

    // Ask for a callback when the DOM is ready.
    var canvas = new Ref<CanvasElement>();
    p.onRendered = () => draw(canvas.elt.context2D, seeds, seedRadius);

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
}

const num TAU = PI * 2;
final num PHI = (sqrt(5) + 1) / 2;
const maxD = 300;
const centerX = maxD ~/ 2;
const centerY = maxD ~/ 2;

/// Draw the complete figure for the current number of seeds.
void draw(CanvasRenderingContext2D context, int seeds, int seedRadius) {
  num scaleFactor = seedRadius * 2;
  context.clearRect(0, 0, maxD, maxD);
  for (var i = 0; i < seeds; i++) {
    final num theta = i * TAU / PHI;
    final num r = sqrt(i) * scaleFactor;
    drawSeed(context, centerX + r * cos(theta), centerY - r * sin(theta), seedRadius);
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

main() =>
    getRoot("#sunflower")
      .mount(const SunflowerApp(startSeeds: 500, seedRadius: 2));
