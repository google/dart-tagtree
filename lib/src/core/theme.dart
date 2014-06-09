part of core;

typedef Viewer ConstructViewerFunc();

/// A Theme constructs the appropriate [Viewer] for each [View].
class Theme {
  /// A map from a type to a Viewer or MakeViewerFunc
  final viewers = <dynamic, ConstructViewerFunc>{};

  Theme([TagSet tags]) {
    if (tags != null) {
      defineElements(tags);
    }
  }

  /// Sets the function that will create the Viewer for a View.
  /// (If the View already had a definition, it will be replaced.)
  void define(type, ConstructViewerFunc constructor) {
    viewers[type] = constructor;
  }

  /// Defines all element tags in a TagSet to render to themselves.
  void defineElements(TagSet tags) {
    for (var elt in tags.elementTypes) {
      define(elt, () => elt);
    }
  }
}

abstract class Viewer {
  const Viewer();
}

/// A Template renders a view by substituting another View.
class Template extends Viewer {
  final TemplateFunc render;
  final ShouldRenderFunc shouldRender;
  const Template(this.render, {this.shouldRender: _always});
}

/// A function that expands a template node to its replacement.
typedef View TemplateFunc(View node);

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(View before, View after);

bool _always(before, after) => true;
