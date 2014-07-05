library button;

import "package:tagtree/core.dart";
import "package:tagtree/server.dart";

final $ = new HtmlTagSet();

class ButtonDemo extends Session<int> {
  @override
  getFirstState() => 0;

  int get clicks => state;

  onClick(_) {
    print("button clicked");
    nextState = clicks + 1;
  }

  @override
  Tag render() {
    return $.Div(inner: [
                 $.Div(inner: "Clicks: ${clicks}"),
                 $.Button(onClick: remote(onClick), inner: "Click to log a message"),
                ]);
  }
}
