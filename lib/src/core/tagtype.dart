part of core;

class TagType {
  /// The name of this tag as a Dart symbol.
  /// (The method name used to create this tag.)
  final Symbol sym;

  /// The name of this tag in JSON.
  /// (May be null if not serializable.)
  final String name;

  /// The allowed properties of this tag.
  /// (As separate fields since concatenating lists isn't a const expression.)
  final List<PropType> _props1;
  final List<PropType> _props2;

  const TagType(this.sym, [this.name, this._props1 = const [], this._props2]);

  List<PropType> get props {
    var out = _props[this];
    if (out == null) {
      if (_props2 == null) {
        out = _props1;
      } else {
        out = new List.from(_props1)..addAll(_props2);
      }
      _props[this] = out;
    }
    return out;
  }

  Map<Symbol, PropType> get propsBySymbol {
    var out = _propsBySym[this];
    if (out == null) {
      out = <Symbol, PropType>{};
      for (var p in props) {
        out[p.sym] = p;
      }
      _propsBySym[this] = out;
    }
    return out;
  }

  Map<String, PropType> get propsByName {
    var out = _propsByName[this];
    if (out == null) {
      out = <String, PropType>{};
      for (var p in props) {
        out[p.name] = p;
      }
      _propsByName[this] = out;
    }
    return out;
  }

  /// Verifies that a propMap contains serializable property keys.
  bool checkPropKeys(Map<Symbol, dynamic> propMap) {
    var bySym = propsBySymbol;
    for (Symbol key in propMap.keys) {
      if (!bySym.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }
    return true;
  }

  /// Converts a map from symbol keys to string keys.
  Map<String, dynamic> propsToJson(Map<Symbol, dynamic> propMap) {
    var bySym = propsBySymbol;
    var out = {};
    for (var key in propMap.keys) {
      var name = bySym[key].name;
      assert(name != null);
      out[name] = propMap[key];
    }
    return out;
  }

  /// Converts a map from string keys to symbol keys.
  Map<Symbol, dynamic> propsFromJson(Map<String, dynamic> jsonMap) {
    var byName = propsByName;
    var out = <Symbol, dynamic>{};
    for (var name in jsonMap.keys) {
      var key = byName[name].sym;
      assert(key != null);
      out[key] = jsonMap[name];
    }
    return out;
  }

  // Lazily initialized indexes.
  static final _props = new Expando<List<PropType>>();
  static final _propsBySym = new Expando<Map<Symbol, PropType>>();
  static final _propsByName = new Expando<Map<String, PropType>>();
}

/// Defines what may be stored in a prop.
class PropType {
  /// The name of this property as a Dart symbol.
  /// The symbol is used as the prop's key and as the name of
  /// its parameter in a function call.
  final Symbol sym;

  /// The name of this property in JSON.
  /// (May be null if not serializable.)
  final String name;

  const PropType(this.sym, this.name);
}

class AttributeType extends PropType {
  const AttributeType(Symbol sym, String name) : super(sym, name);
}

class HandlerPropType extends PropType {
  const HandlerPropType(Symbol sym, String name) : super(sym, name);
}
