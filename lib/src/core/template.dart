part of core;

Template defineTemplate({ShouldUpdateFunc shouldUpdate, Function render})
  => new Template._raw(shouldUpdate, render);

class Template extends TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function render;

  Template._raw(ShouldUpdateFunc shouldUpdate, Function render) :
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

class _Template extends _View {
  _View _shadow;
  Props _props;

  _Template(Template def, String path, int depth, Map<Symbol, dynamic> props) :
    super(def, path, depth, props[#ref]);
}