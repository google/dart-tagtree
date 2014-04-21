part of core;

typedef bool ShouldUpdateFunc(Props p, Props next);

TagDef defineTemplate({ShouldUpdateFunc shouldUpdate, Function render})
  => new TemplateDef._raw(shouldUpdate, render);

/// A wrapper allowing a template's properties to be accessed as fields.
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