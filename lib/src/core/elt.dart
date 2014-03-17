part of core;

/// A virtual DOM element.
class Elt extends View with _Inner implements Jsonable {
  final String tagName;
  Map<Symbol, dynamic> _props;

  Elt(this.tagName, Map<Symbol, dynamic> props)
      : _props = props,
        super(props[#ref]) {

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

  String get jsonTag => tagName;

  Props get props => new Props(_props);

  bool canUpdateTo(View other) => (other is Elt) && other.tagName == tagName;

  /// A ruleSet that can encode any Elt as JSON.
  static final JsonRuleSet rules = (){
    var rs = new JsonRuleSet();
    for (String tag in _allTags.values) {
      rs.add(new EltRule(tag));
    }
    return rs;
  }();
}

/// Encodes an Elt as tagged JSON.
class EltRule extends JsonRule {
  static final Map<Symbol, String> _symbolToFieldName = _eltPropToField;
  static final Map<String, Symbol> _fieldNameToSymbol = _invertMap(_symbolToFieldName);

  EltRule(String tag) : super(tag);

  @override
  bool appliesTo(Jsonable instance) {
    return instance is Elt && instance.tagName == tag && !instance._mounted;
  }

  @override
  getState(Elt instance) {
    Map<Symbol, dynamic> props = instance.props._props;
    var state = {};
    for (Symbol sym in props.keys) {
      var field = _symbolToFieldName[sym];
      assert(field != null);
      state[field] = props[sym];
    }
    return state;
  }

  @override
  Elt create(Map<String, dynamic> state) {
    var props = <Symbol, dynamic>{};
    for (String field in state.keys) {
      var sym = _fieldNameToSymbol[field];
      assert(sym != null);
      props[sym] = state[field];
    }
    return new Elt(tag, props);
  }
}

Map _invertMap(Map m) {
  var result = {};
  m.forEach((k,v) => result[v] = k);
  assert(m.length == result.length);
  return result;
}
