part of core;

typedef bool ShouldUpdateFunc(Props p, Props next);

typedef Widget WidgetFunc(Props p);

/// Defines a custom tag.
class TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function render;
  final WidgetFunc widgetFunc;

  TagDef({ShouldUpdateFunc shouldUpdate, Function render, WidgetFunc widget}) :
    this.shouldUpdate = shouldUpdate, this.render = render, this.widgetFunc = widget {
    assert((render != null) != (widget != null));
    if (shouldUpdate != null) {
      assert(render != null);
    }
  }

  // Implement call() with any named arguments.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod && inv.memberName == #call) {
      if (!inv.positionalArguments.isEmpty) {
        throw "position arguments not supported for tags";
      }
      if (widgetFunc != null) {
        return widgetFunc(new Props(inv.namedArguments));
      } else {
        return new Tag(this, inv.namedArguments);
      }
    }
    return super.noSuchMethod(inv);
  }
}

class Tag extends View {
  final TagDef def;
  final Map<Symbol, dynamic> _props;

  View _shadow;
  Props _shadowProps;

  Tag(this.def, Map<Symbol, dynamic> props) : _props = props, super(props[#ref]);

  View render(Map<Symbol, dynamic> props) {
    assert(def.render != null);
    return Function.apply(def.render, [], props);
  }
}
