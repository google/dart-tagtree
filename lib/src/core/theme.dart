part of core;

typedef Animation CreateExpander();

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


