part of core;

/// A synthetic, browser-independent event.
class HtmlEvent implements Jsonable {

  @override
  String get jsonTag => _htmlHandlerNames[type];

  /// A symbol indicating what kind of event this is; #onChange, #onSubmit, and so on.
  /// (This is the same key used as the Element prop when creating the Element.)
  final Symbol type;

  final String targetPath;

  HtmlEvent(this.type, this.targetPath) {
    assert(type != null);
    assert(targetPath != null);
  }
}

/// Indicates that the user changed the value in a form control.
/// (This event happens after every keystroke.)
class ChangeEvent extends HtmlEvent {

  /// The new value in the <input> or <textarea> element.
  final value;

  ChangeEvent(String path, this.value): super(#onChange, path);
}

typedef EventHandler(HtmlEvent e);

/// A unique id that identifies a remote event handler.
class Handle implements Jsonable {
  final int frameId;
  final int id;

  Handle(this.frameId, this.id);

  @override
  String get jsonTag => "handle";
}

/// A call to a remote handler.
class HandleCall implements Jsonable {
  final Handle handle;
  final HtmlEvent event;

  HandleCall(this.handle, this.event);

  @override
  String get jsonTag => "call";
}
