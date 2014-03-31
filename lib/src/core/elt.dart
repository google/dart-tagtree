part of core;

/// A virtual DOM element.
class Elt extends View with _Inner {
  final String tagName;
  Map<Symbol, dynamic> _props;

  Elt(EltDef def, Map<Symbol, dynamic> props) :
      tagName = def.tagName,
      _props = props,
      super(props[#ref]) {
    _def = def;

    for (Symbol key in props.keys) {
      if (!_allEltProps.contains(key)) {
        throw "property not supported: ${key}";
      }
    }
    var inner = _props[#inner];
    assert(inner == null || inner is String || inner is View || inner is Iterable);
    assert(inner == null || _props[#innerHtml] == null);
    assert(_props[#value] == null || _props[#defaultValue] == null);
  }

  Props get props => new Props(_props);

  /// A ruleSet that can encode any Elt as JSON.
  static final JsonRuleSet rules = (){
    var rs = new JsonRuleSet();
    for (EltDef def in _eltTags.values) {
      rs.add(new EltRule(def));
    }
    return rs;
  }();
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
  String get jsonTag => def.tagName;
}

/// Encodes an Elt as tagged JSON.
class EltRule extends JsonRule {
  static final Map<Symbol, String> _symbolToFieldName = _eltPropToField;
  static final Map<String, Symbol> _fieldNameToSymbol = _invertMap(_symbolToFieldName);

  EltDef _def;

  EltRule(EltDef def) : _def = def, super(def.tagName);

  @override
  bool appliesTo(Jsonable instance) {
    return instance is EltTag && instance.def == _def;
  }

  @override
  getState(EltTag instance) {
    Map<Symbol, dynamic> props = instance.props;
    var state = {};
    for (Symbol sym in props.keys) {
      var field = _symbolToFieldName[sym];
      assert(field != null);
      state[field] = props[sym];
    }
    return state;
  }

  @override
  EltTag create(Map<String, dynamic> state) {
    var props = <Symbol, dynamic>{};
    for (String field in state.keys) {
      var sym = _fieldNameToSymbol[field];
      assert(sym != null);
      props[sym] = state[field];
    }
    return new EltTag(_def, props);
  }
}

Map _invertMap(Map m) {
  var result = {};
  m.forEach((k,v) => result[v] = k);
  assert(m.length == result.length);
  return result;
}
