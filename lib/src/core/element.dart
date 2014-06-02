part of core;

/// A node that renders as an HTML element.
class ElementNode extends TaggedNode {
  final ElementType type;
  final Map<String, dynamic> propsMap;

  ElementNode(this.type, this.propsMap) {
    assert(type.checkNode(this));
  }

  String get tag => type.tag;

  /// Returns the key of each prop.
  Iterable<String> get keys => propsMap.keys;

  /// Returns the value of a property.
  operator[](String key) => propsMap[key];

  get ref => propsMap["ref"];
}

class ElementType {

  /// The method in HtmlTagSet that creates this element.
  final Symbol method;

  /// The name of the HTML Element that the node will render to.
  /// (Also used for sending the node over the network.)
  final String tag;

  // The tag's properties, split into two lists.
  // (This is because there's no way to concatenate const lists in Dart.)
  final List<PropType> _props1;
  final List<PropType> _props2;

  const ElementType(this.method, this.tag, this._props1, [this._props2 = const []]);

  /// Checks that the type is well-formed.
  /// (Not done in the constructor so that it can be const.)
  bool checked() {
    assert(method != null);
    assert(tag != null);
    for (var p in _props1) {
      assert(p.checked());
    }
    for (var p in _props2) {
      assert(p.checked());
    }
    return true;
  }

  /// Creates a node with this element type.
  ElementNode makeNode(Map<String, dynamic> props) => new ElementNode(this, props);

  /// Returns a description of each property of this element.
  /// (The ElementType will be checked the first time this is called.)
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

  /// Returns a description of each property that stores a handler.
  Iterable<HandlerType> get handlerTypes => props.where((t) => t is HandlerType);

  /// Returns a mapping from each named parameter in a method call to the property key.
  Map<Symbol, String> get namedParams {
    var out = <Symbol, String>{};
    for (var propType in props) {
      out[propType.sym] = propType.name;
    }
    return out;
  }

  /// Checks that a node is well-formed.
  /// Called automatically on new nodes when Dart is running in checked mode.
  bool checkNode(ElementNode node) {
    _checkPropKeys(node);
    assert(node["inner"] == null || node["innerHtml"] == null);
    assert(node["value"] == null || node["defaultValue"] == null);
    return true;
  }

  /// Verifies that a node's properties have the correct keys.
  bool _checkPropKeys(ElementNode node) {
    var byName = propsByName;
    for (String key in node.keys) {
      if (!byName.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }
    return true;
  }

  // Lazily initialized indexes.
  static final _props = new Expando<List<PropType>>();
  static final _propsByName = new Expando<Map<String, PropType>>();
}

/// A PropType describes a property of an ElementNode.
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

/// The type of a property that stores HTML mixed content.
class MixedContentType extends PropType {
  const MixedContentType(Symbol sym, String name) : super(sym, name);

  @override
  bool checkValue(inner) {
    assert(inner == null || inner is String || inner is ElementNode || inner is Iterable);
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
    assert(value is HandlerFunc || value is HandlerId);
    return true;
  }
}
