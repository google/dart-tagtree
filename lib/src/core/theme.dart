part of core;

/// A Theme maps Tag types to Animators.
class Theme {
  static final EMPTY = new Theme(const {});

  final String name;
  final _bindings = <dynamic, Animator>{};

  Theme(Map<dynamic, Animator> bindings, {String name}) :
    this.name = _chooseThemeName(name) {
    _bindings.addAll(bindings);
  }

  Theme._extend(Theme parent, Map<dynamic, Animator> bindings, {String name}) :
    this.name = _chooseThemeName(name) {
    _bindings.addAll(parent._bindings);
    _bindings.addAll(bindings);
  }

  Iterable get keys => _bindings.keys;

  Animator operator [](Object key) => _bindings[key];

  /// Returns a new theme with additional tags defined.
  Theme extend(Map<dynamic, Animator> bindings) =>
      new Theme._extend(this,  bindings);

  @override
  String toString() => "Theme(${name})";
}

/// A tag that set the theme to be used for rendering its shadow.
class ThemeTag extends Tag {
  final Theme theme;
  final Tag shadow;
  ThemeTag(this.theme, this.shadow);

  checked() {
    assert(theme != null);
    return true;
  }

  get animator => null; // special case
}

int _untitledCount = 0;

_chooseThemeName(String name) {
  if (name == null) {
    _untitledCount += 1;
    return "Untitled-${ _untitledCount}";
  }
  return name;
}
