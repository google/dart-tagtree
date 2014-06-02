part of core;

/// A view that renders to a single HTML element.
class _ElementView implements View {
  @override
  final Props props;
  const _ElementView(this.props);

  @override
  bool checked() => true; // already done in ElementType.makeNode.

  @override
  get tag => props.tag;

  @override
  get jsonTag => props.tag;

  @override
  get propsImpl => props.propsMap;

  @override
  get ref => props["ref"];

  static final _checked = new Expando<bool>();
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

  /// Creates a view corresponding to this element.
  View makeView(Map<String, dynamic> propMap) {
    assert(propMap != null);
    Props p = new Props(tag, propMap);
    checkProps(p);
    return new _ElementView(p);
  }

  /// Returns a description of each property of this element.
  /// (The ElementType will be checked the first time this is called.)
  List<PropType> get propTypes {
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
      for (var p in propTypes) {
        out[p.name] = p;
      }
      _propsByName[this] = out;
    }
    return out;
  }

  /// Returns a description of each property that stores a handler.
  Iterable<HandlerType> get handlerTypes => propTypes.where((t) => t is HandlerType);

  /// Returns a mapping from each named parameter in a method call to the property key.
  Map<Symbol, String> get namedParams {
    var out = <Symbol, String>{};
    for (var propType in propTypes) {
      out[propType.sym] = propType.name;
    }
    return out;
  }

  /// Checks that an Element node's properties are well-formed.
  /// Called automatically on new nodes when Dart is running in checked mode.
  bool checkProps(Props props) {
    _checkPropKeys(props);
    assert(props["inner"] == null || props["innerHtml"] == null);
    assert(props["value"] == null || props["defaultValue"] == null);
    return true;
  }

  /// Verifies that a node's properties have the correct keys.
  bool _checkPropKeys(Props props) {
    assert(props != null);
    var byName = propsByName;
    for (String key in props.keys) {
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
    assert(inner == null || inner is String || inner is View || inner is Iterable);
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
