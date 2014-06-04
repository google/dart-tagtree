part of theme;

/// A function that expands a template node to its replacement.
typedef View TemplateFunc(View node);

/// A function that returns true when a template needs to be re-rendered.
typedef bool ShouldRenderFunc(View before, View after);

typedef Widget CreateWidgetFunc();

class Theme {
  final tagDefs = <String, TagDef>{};

  Theme([TagSet tags]) {
    if (tags != null) {
      addElements(tags);
    }
  }

  void addElements(TagSet tags) {
    for (var elt in tags.elementTypes) {
      addElement(elt);
    }
  }

  void addElement(ElementType type) {
    tagDefs[type.tag] = new ElementDef(type);
  }

  void addTemplate(String tag, TemplateFunc render, {ShouldRenderFunc shouldRender: _always}) {
    tagDefs[tag] = new TemplateDef(render, shouldRender);
  }

  void addWidget(String tag, CreateWidgetFunc createWidget) {
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
