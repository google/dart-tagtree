part of core;

typedef Viewer ViewerFunc();

/// A Theme is a set of [Viewer]s.
class Theme {
  /// A map from a type to a Viewer or MakeViewerFunc
  final viewers = <dynamic, ViewerFunc>{};

  Theme([TagSet tags]) {
    if (tags != null) {
      addTags(tags);
    }
  }

  void addTags(TagSet tags) {
    for (var elt in tags.elementTypes) {
      add(elt);
    }
  }

  /// Adds a Viewer to the theme. If there was previously a viewer for
  /// the same view type, it is replaced.
  void add(Viewer viewer) {
    define(viewer.viewType, () => viewer);
  }

  /// Adds a function that will provide the Viewer when needed.
  void define(type, ViewerFunc maker) {
    viewers[type] = maker;
  }
}

/// An implementation of all Views of a given type.
abstract class Viewer {
  /// The viewer matches a view if [View.type] matches this key.
  final viewType;
  const Viewer(this.viewType);
}

/// A Template renders a view by substituting another View.
class Template extends Viewer {
  final TemplateFunc render;
  final ShouldRenderFunc shouldRender;
  const Template(type, this.render, {this.shouldRender: _always}) : super(type);
}

/// A function that expands a template node to its replacement.
typedef View TemplateFunc(View node);

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(View before, View after);

bool _always(before, after) => true;
