part of core;

typedef bool ShouldUpdateFunc(Props p, Props next);

TagDef defineTemplate({ShouldUpdateFunc shouldUpdate, Function render})
  => new TemplateDef._raw(shouldUpdate, render);

class TemplateDef extends TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function render;

  TemplateDef._raw(ShouldUpdateFunc shouldUpdate, Function render) :
    this.shouldUpdate = shouldUpdate, this.render = render {
    assert(render != null);
  }

  bool _shouldUpdate(Props current, Props next) {
    if (shouldUpdate == null) {
      return true;
    }
    return shouldUpdate(current, next);
  }

  Tag _render(Map<Symbol, dynamic> props) {
    return Function.apply(render, [], props);
  }
}

class _Template extends _View {
  _View _shadow;
  Props _props;

  _Template(TemplateDef def, String path, int depth, Map<Symbol, dynamic> props) :
    super(def, path, depth, props[#ref]);
}