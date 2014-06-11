part of core;

abstract class Viewer {
  const Viewer();
}

typedef Viewer CreateViewerFunc();

/// A Theme implements a set of tags.
/// Each tag has a mapping to a function that creates a Viewer.
class Theme extends UnmodifiableMapBase<dynamic, CreateViewerFunc> {
  final String name;
  final _bindings = <dynamic, CreateViewerFunc>{};

  Theme(Map<dynamic, CreateViewerFunc> bindings, {String name}) :
    this.name = _chooseThemeName(name) {
    _bindings.addAll(bindings);
  }

  Theme._extend(Theme parent, Map<dynamic, CreateViewerFunc> bindings, {String name}) :
    this.name = _chooseThemeName(name) {
    _bindings.addAll(parent._bindings);
    _bindings.addAll(bindings);
  }

  @override
  Iterable get keys => _bindings.keys;

  @override
  CreateViewerFunc operator [](Object key) => _bindings[key];

  /// Returns a new theme with additional tags defined.
  Theme extend(Map<dynamic, CreateViewerFunc> bindings) =>
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
abstract class Template<V extends View> extends Viewer {
  const Template();
  View render(V props);
  bool shouldRender(V before, V after) => true;

  // implement CreateViewerFunc
  Template call() => this;
}

