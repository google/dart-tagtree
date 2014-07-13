import "package:tagtree/browser.dart";
import "package:tagtree/core.dart";

import "shared.dart";

final $ = new HtmlTagSet.withTags([ButtonDemoRequest.$jsonType, TailDemoRequest.$jsonType, TailSnapshot.$jsonType]);

final theme = new Theme(const {
  TailSnapshot: const _TextFile(),
});

class DemoPicker extends AnimatedTag<Jsonable> {
  const DemoPicker();

  @override
  Place start() => new Place(const ButtonDemoRequest());

  @override
  Tag renderAt(Place p) {

    var makeButton = (Jsonable request, String text) {
      onClick(_) {
        p.nextState = request;
      }
      return $.Button(onClick: onClick, inner: text);
    };

    Jsonable request = p.state;

    final serverDemo = new RemoteZone(
        placeholder: $.Div(inner: "Loading..."),
        src: "ws://localhost:8081/ws",
        request: request,
        exports: $,
        theme: theme);

    return $.Div(inner: [
      $.Div(inner: [
        "Choose a demo: ",
        makeButton(const ButtonDemoRequest(), "Button"),
        makeButton(const TailDemoRequest(25), "Tail")
      ]),
      serverDemo
    ]);
  }
}

class _TextFile extends Template {
  const _TextFile();

  @override
  render(TailSnapshot tag) => $.Pre(inner: tag.lines.join("\n"));
}

main() =>
    getRoot("#view")
        ..mount(const DemoPicker());
