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

/// A ruleSet that can encode any Elt as JSON.
final JsonRuleSet eltRules = (){
  var rs = new JsonRuleSet();
  for (EltDef def in _htmlEltDefs.values) {
    rs.add(new EltRule(def));
  }
  rs.add(new _HandleRule());
  for (Symbol key in _htmlHandlerNames.keys) {
    if (key == #onChange) {
      rs.add(new _ChangeEventRule());
    } else {
      rs.add(new _EventRule(key));
    }
  }
  rs.add(new _HandleCallRule());
  return rs;
}();

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
class EltRule extends JsonRule<EltTag> {
  static final Map<Symbol, String> _symbolToFieldName = _htmlPropNames;
  static final Map<String, Symbol> _fieldNameToSymbol = _invertMap(_symbolToFieldName);

  EltDef _def;

  EltRule(EltDef def) : _def = def, super(def.tagName);

  @override
  bool appliesTo(Jsonable instance) {
    return instance is EltTag && instance.def == _def;
  }

  @override
  encode(EltTag instance) {
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
  EltTag decode(Map<String, dynamic> state) {
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
