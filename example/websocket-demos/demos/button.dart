library button;

import "../web/shared.dart";

import "package:tagtree/core.dart";
import "package:tagtree/server.dart";

final $ = new HtmlTagSet();

class ButtonDemoSession extends Session<ButtonDemo, int> {
  @override
  getFirstState(_) => 0;

  int get clicks => state;

  onClick(_) {
    print("button clicked");
    nextState = clicks + 1;
  }

  @override
  Tag render(_) {
    return $.Div(inner: [
                 $.H1(inner: "Button Demo"),
                 $.Div(inner: "Clicks: ${clicks}"),
                 $.Button(onClick: remote(onClick), inner: "Click to log a message"),
                ]);
  }
}
