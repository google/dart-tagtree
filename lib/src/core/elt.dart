part of core;

class EltDef extends TagDef {
  final String tagName;

  EltDef(this.tagName);

  Tag makeTag(Map<Symbol, dynamic> props) {
    for (Symbol key in props.keys) {
      if (!_htmlPropNames.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }

    var inner = props[#inner];
    assert(inner == null || inner is String || inner is _View || inner is Iterable);
    assert(inner == null || props[#innerHtml] == null);
    assert(props[#value] == null || props[#defaultValue] == null);

    return new EltTag(this, props);
  }
}

class EltTag extends Tag implements Jsonable {
  EltTag(EltDef def, Map<Symbol, dynamic> props) : super(def, props);
  EltDef get def => super.def;
  String get jsonTag => def.tagName;
}
