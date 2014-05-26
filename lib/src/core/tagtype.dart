part of core;

/// A TagType defines the public interface for constructing and serializing nodes
/// with a particular tag.
class TagType {

  /// The name of this tag as a Dart symbol.
  /// (May be used as the name of the method to create this tag.)
  final Symbol symbol;

  /// The name of this tag for serialization.
  /// (If it's an HTML element, this name is also used to construct the DOM node.)
  final String name;

  // The tag's properties, split into two lists.
  // (This is because there's no way to concatenate const lists in Dart.)
  final List<PropType> _props1;
  final List<PropType> _props2;

  const TagType(this.symbol, this.name, this._props1, [this._props2 = const []]);

  /// Checks that the type is well-formed.
  /// (Not done in the constructor so that it can be const.)
  bool checked() {
    assert(symbol != null);
    assert(name != null);
    for (var p in _props1) {
      assert(p.checked());
    }
    for (var p in _props2) {
      assert(p.checked());
    }
    return true;
  }

  /// Returns a description of each property of this tag.
  /// (The TagType will be checked the first time this is called.)
  List<PropType> get props {
    var out = _props[this];
    if (out == null) {
      assert(checked());
      if (_props2.isEmpty) {
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

  /// Verifies that a node's properties have the correct keys.
  bool checkPropKeys(Map<Symbol, dynamic> propMap) {
    var bySym = propsBySymbol;
    for (Symbol key in propMap.keys) {
      if (!bySym.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }
    return true;
  }

  /// Converts a node's properties from symbol keys to string keys.
  Map<String, dynamic> convertToStringKeys(Map<Symbol, dynamic> propMap) {
    var bySym = propsBySymbol;
    var out = {};
    for (var key in propMap.keys) {
      var name = bySym[key].name;
      assert(name != null);
      out[name] = propMap[key];
    }
    return out;
  }

  /// Converts a node's properties from string keys to symbol keys.
  Map<Symbol, dynamic> convertFromStringKeys(Map<String, dynamic> jsonMap) {
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

/// A PropType defines what may be stored in one property of a [Tag]
/// and how it may be serialized.
class PropType {
  /// The name of this property as a Dart symbol.
  /// The symbol is used as the prop's key and as the name of
  /// its parameter in a function call.
  final Symbol sym;

  /// The name of this property in JSON.
  /// (May be null if not serializable.)
  final String name;

  const PropType(this.sym, this.name);

  bool checked() {
    assert(sym != null);
    assert(name != null);
    return true;
  }

  /// Subclass hook to check that a property's value is allowed.
  bool checkValue(dynamic value) {
    return true;
  }
}

/// The type of an HTML attribute.
class AttributeType extends PropType {
  const AttributeType(Symbol sym, String name) : super(sym, name);

  @override
  bool checkValue(String value) {
    return true;
  }
}

/// The type of a property that can store an event handler.
class HandlerType extends PropType {
  const HandlerType(Symbol sym, String name) : super(sym, name);

  @override
  bool checkValue(dynamic value) {
    assert(value is HandlerFunc || value is Handler);
    return true;
  }
}
