part of core;

/// A synthetic, browser-independent event.
class ViewEvent {

  /// A symbol indicating what kind of event this is; #onChange, #onSubmit, and so on.
  /// (This is the same key used as the Element prop when creating the Element.)
  final Symbol type;

  final String targetPath;

  ViewEvent(this.type, this.targetPath) {
    assert(type != null);
    assert(targetPath != null);
  }
}

/// Indicates that the user changed the value in a form control.
/// (This event happens after every keystroke.)
class ChangeEvent extends ViewEvent {

  /// The new value in the <input> or <textarea> element.
  final value;

  ChangeEvent(String path, this.value): super(#onChange, path);
}

typedef EventHandler(ViewEvent e);

/// All installed event handlers. The submap's key is the View's path.
/// TODO: make this a field in a ViewTree instead of a global?
Map<Symbol, Map<String, EventHandler>> _allHandlers = {
  #onChange: {},
  #onClick: {},
  #onSubmit: {}
};
