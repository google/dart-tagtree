part of theme;

/// A function that expands a template node to its replacement.
typedef View TemplateFunc(View node);

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(View before, View after);

typedef Widget CreateWidgetFunc();

/// A module that contains tag implementations.
class Theme {
  final tagDefs = <dynamic, TagDef>{};

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
    tagDefs[type] = new ElementDef(type);
  }

  /// Redefines a tag so it renders by expanding a template.
  void defineTemplate(tag, TemplateFunc render, {ShouldRenderFunc shouldRender: _always}) {
    tagDefs[tag] = new TemplateDef(render, shouldRender);
  }

  /// Redefines a tag so it renders by either starting or reconfiguring a Widget.
  void defineWidget(tag, CreateWidgetFunc createWidget) {
    tagDefs[tag] = new WidgetDef(createWidget);
  }
}

abstract class TagDef {
  const TagDef();
}

bool _always(before, after) => true;

class ElementDef extends TagDef {
  final ElementType type;
  const ElementDef(this.type);
}

class TemplateDef extends TagDef {
  final TemplateFunc render;
  final ShouldRenderFunc shouldRender;
  const TemplateDef(this.render, [this.shouldRender = _always]);
}

class WidgetDef extends TagDef {
  final CreateWidgetFunc create;
  const WidgetDef(CreateWidgetFunc this.create);
}
