part of core;

typedef bool ShouldUpdateFunc(Props p, Props next);

TagDef defineTemplate({ShouldUpdateFunc shouldUpdate, Function render})
  => new TemplateDef._raw(shouldUpdate, render);

class TemplateDef extends TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function _renderFunc;

  TemplateDef._raw(ShouldUpdateFunc shouldUpdate, Function render) :
    this.shouldUpdate = shouldUpdate == null ? _alwaysUpdate : shouldUpdate,
    this._renderFunc = render {
    assert(render != null);
  }

  Tag render(Map<Symbol, dynamic> props) {
    return Function.apply(_renderFunc, [], props);
  }

  static _alwaysUpdate(p, next) => true;
}

/// A wrapper allowing a View's props to be accessed using dot notation.
@proxy
class Props {
  final Map<Symbol, dynamic> _props;

  Props(this._props);

  noSuchMethod(Invocation inv) {
    if (inv.isGetter) {
      if (_props.containsKey(inv.memberName)) {
        return _props[inv.memberName];
      }
    }
    print("keys: ${_props.keys.join(", ")}");
    return super.noSuchMethod(inv);
  }
}