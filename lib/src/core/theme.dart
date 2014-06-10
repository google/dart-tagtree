part of core;

typedef Viewer CreateViewerFunc();

/// A Theme implements a set of tags.
/// Each tag has a mapping to a function that creates a Viewer.
class Theme extends UnmodifiableMapBase<dynamic, CreateViewerFunc> {
  /// Maps types to Viewer constructors
  final _bindings = <dynamic, CreateViewerFunc>{};

  Theme(Map<dynamic, CreateViewerFunc> bindings) {
    _bindings.addAll(bindings);
  }

  Theme._extend(Theme parent, Map<dynamic, CreateViewerFunc> bindings) {
    _bindings.addAll(parent._bindings);
    _bindings.addAll(bindings);
  }

  @override
  Iterable get keys => _bindings.keys;

  @override
  CreateViewerFunc operator [](Object key) => _bindings[key];

  /// Sets the function that will create the Viewer for a View.
  /// (If the View already had a definition, it will be replaced.)
  void define(type, CreateViewerFunc constructor) {
    _bindings[type] = constructor;
  }

  Viewer createViewer(View view) {
    CreateViewerFunc create = _bindings[view.tag];
    if (create == null) {
      throw "no Viewer constructor found for: ${view}";
    }
    return create();
  }

  /// Returns a new theme with additional tags defined.
  Theme extend(Map<dynamic, CreateViewerFunc> bindings) =>
      new Theme._extend(this,  bindings);
}

abstract class Viewer {
  const Viewer();
}

/// A Template renders a view by substituting another View.
abstract class Template<V extends View> extends Viewer {
  const Template();
  View render(V props);
  bool shouldRender(V before, V after) => true;

  // implement CreateViewerFunc
  Template call() => this;
}

/// A function that expands a template node to its replacement.
typedef View TemplateFunc(View node);

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(View before, View after);

bool _always(before, after) => true;
