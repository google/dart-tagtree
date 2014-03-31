part of core;

class Template extends TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function render;

  Template({ShouldUpdateFunc shouldUpdate, Function render}) :
    this.shouldUpdate = shouldUpdate, this.render = render {
    assert(render != null);
  }

  Tag makeTag(Map<Symbol, dynamic> props) {
    return new Tag(this, props);
  }

  @override
  bool _shouldUpdate(Props current, Props next) {
    if (shouldUpdate == null) {
      return true;
    }
    return shouldUpdate(current, next);
  }

  @override
  Tag _render(Map<Symbol, dynamic> props) {
    return Function.apply(render, [], props);
  }
}

class TemplateView extends View {
  View _shadow;
  Props _shadowProps;

  TemplateView(Template def, Map<Symbol, dynamic> props) : super(props[#ref]) {
    _def = def;
  }
}