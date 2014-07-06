library button;

import "../web/shared.dart";

import "package:tagtree/core.dart";
import "package:tagtree/server.dart";

final $ = new HtmlTagSet();

class ButtonAnimator extends Animator<ButtonDemo, int> {
  const ButtonAnimator();

  @override
  Place start(ButtonDemo tag) => new Place(0);

  @override
  Tag renderAt(Place<int> p, ButtonDemo tag) {

    onClick(_) {
      print("button clicked");
      p.nextState = p.nextState + 1;
    }

    return $.Div(inner: [
     $.H1(inner: "Button Demo"),
     $.Div(inner: "Clicks: ${p.state}"),
     $.Button(onClick: p.handler(onClick), inner: "Click to log a message"),
    ]);
  }
}
