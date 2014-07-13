part of core;

/// A Theme maps Tag Types to Animators.
class Theme {
  static final EMPTY = const Theme(const {});
  final Map<Type, Animator> bindings;

  const Theme(this.bindings);
  Animator operator[](Type key) => bindings[key];
}

/// A tag that sets the theme to be used within it.
class ThemeZone extends Tag {
  final Theme theme;
  final Tag innerTag;
  ThemeZone(this.theme, this.innerTag);

  checked() {
    assert(theme != null);
    return true;
  }

  get animator => null; // special case
}
