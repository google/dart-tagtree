part of theme;

/// A function that expands a template node to its replacement.
typedef View TemplateFunc(View node);

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(View before, View after);

bool _always(before, after) => true;

typedef Widget CreateWidgetFunc();

/// A module that contains tag implementations.
class Theme {
  final tagDefs = <dynamic, Binding>{};

  Theme([TagSet tags]) {
    if (tags != null) {
      defineElements(tags);
    }
  }

  void defineElements(TagSet tags) {
    for (var elt in tags.elementTypes) {
      defineElement(elt);
    }
  }

  /// Redefines a tag so it renders as a single HTML element.
  void defineElement(ElementType type) {
    tagDefs[type] = new ElementBinding(type);
  }

  /// Redefines a tag so it renders by expanding a template.
  void defineTemplate(tag, TemplateFunc render, {ShouldRenderFunc shouldRender: _always}) {
    tagDefs[tag] = new TemplateBinding(render, shouldRender);
  }

  /// Redefines a tag so it renders by either starting or reconfiguring a Widget.
  void defineWidget(tag, CreateWidgetFunc createWidget) {
    tagDefs[tag] = new WidgetBinding(createWidget);
  }
}

abstract class Binding {
  const Binding();
}

class ElementBinding extends Binding {
  final ElementType type;
  const ElementBinding(this.type);
}

class TemplateBinding extends Binding {
  final TemplateFunc render;
  final ShouldRenderFunc shouldRender;
  const TemplateBinding(this.render, [this.shouldRender = _always]);
}

class WidgetBinding extends Binding {
  final CreateWidgetFunc create;
  const WidgetBinding(CreateWidgetFunc this.create);
}
