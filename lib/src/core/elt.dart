part of core;

/// A virtual DOM element.
class _Elt extends _View with _Inner {
  final String tagName;
  Map<Symbol, dynamic> _props;

  _Elt(EltDef def, String path, int depth, Map<Symbol, dynamic> props) :
      tagName = def.tagName,
      _props = props,
      super(def, path, depth, props[#ref]) {

    for (Symbol key in props.keys) {
      if (!_htmlPropNames.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }
    var inner = _props[#inner];
    assert(inner == null || inner is String || inner is _View || inner is Iterable);
    assert(inner == null || _props[#innerHtml] == null);
    assert(_props[#value] == null || _props[#defaultValue] == null);
  }

  Props get props => new Props(_props);
}

class EltDef extends TagDef {
  final String tagName;

  EltDef(this.tagName);

  Tag makeTag(Map<Symbol, dynamic> props) {
    return new EltTag(this, props);
  }
}

class EltTag extends Tag implements Jsonable {
  EltTag(EltDef def, Map<Symbol, dynamic> props) : super(def, props);
  EltDef get def => super.def;
  String get jsonTag => def.tagName;
}
