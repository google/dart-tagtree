part of core;

/// Expands a view to its "shadow" which will be used for rendering.
/// Expanders can be stateless (a template) or stateful (a Widget).
abstract class Expander {
  const Expander();

  /// Returns true if we can reuse this expander for another animation frame.
  ///
  /// Otherwise, the current expander will be discarded and the [next]
  /// one will be used instead. The DOM will be updated by removing the
  /// corresponding element and recreating it.
  bool canReuse(Expander next) => next == this;

  /// Returns true if we should call [expand] to render the next frame.
  ///
  /// Otherwise, the previous expansion will be reused,
  /// and usually the DOM update will be skipped entirely.
  bool shouldExpand(View prev, View next) => true;

  /// Returns the shadow view to be rendered in place of the given input.
  /// The input may be returned if the view doesn't need to be expanded.
  /// (In that case, it must be an [ElementView] that can be rendered
  /// directly.)
  View expand(View input);

  /// Called when the expander is no longer needed.
  void unmount() {}
}

typedef Expander CreateExpander();

/// A Theme maps Views to Expanders.
class Theme {
  final String name;
  final _bindings = <dynamic, CreateExpander>{};

  Theme(Map<dynamic, CreateExpander> bindings, {String name}) :
    this.name = _chooseThemeName(name) {
    _bindings.addAll(bindings);
  }

  Theme._extend(Theme parent, Map<dynamic, CreateExpander> bindings, {String name}) :
    this.name = _chooseThemeName(name) {
    _bindings.addAll(parent._bindings);
    _bindings.addAll(bindings);
  }

  Iterable get keys => _bindings.keys;

  CreateExpander operator [](Object key) => _bindings[key];

  /// Returns a new theme with additional tags defined.
  Theme extend(Map<dynamic, CreateExpander> bindings) =>
      new Theme._extend(this,  bindings);

  @override
  String toString() => "Theme(${name})";
}

int _untitledCount = 0;

_chooseThemeName(String name) {
  if (name == null) {
    _untitledCount += 1;
    return "Untitled-${ _untitledCount}";
  }
  return name;
}

/// A Template renders a view by substituting another View.
abstract class Template<V extends View> extends Expander {
  const Template();

  @override
  View expand(V props);

  @override
  bool shouldExpand(V before, V after) => true;

  // implement CreateExpander.
  Template call() => this;
}

