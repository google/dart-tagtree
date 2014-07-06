import "package:tagtree/browser.dart";
import "package:tagtree/core.dart";

import "shared.dart";

final $ = new HtmlTagSet.withTags([ButtonDemo.$maker, TailDemo.$maker, TailSnapshot.$maker]);

final theme = new Theme(const {
  TailSnapshot: const _TextFile(),
});

class DemoPicker extends AnimatedTag<JsonTag> {
  const DemoPicker();

  @override
  Place start() => new Place(const ButtonDemo());

  @override
  Tag renderAt(Place p) {

    var makeButton = (Tag request, String text) {
      onClick(_) {
        p.nextState = request;
      }
      return $.Button(onClick: onClick, inner: text);
    };

    JsonTag request = p.state;

    final serverDemo = new RemoteZone(
        placeholder: $.Div(inner: "Loading..."),
        src: "ws://localhost:8081/ws",
        request: request,
        exports: $,
        theme: theme);

    return $.Div(inner: [
      $.Div(inner: [
        "Choose a demo: ",
        makeButton(const ButtonDemo(), "Button"),
        makeButton(const TailDemo(25), "Tail")
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
