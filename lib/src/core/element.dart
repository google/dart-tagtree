part of core;

/// A view that TagTree will render to a single HTML element.
/// Constructed via [ElementType.makeView].
class ElementView implements View {
  final ElementType type;

  @override
  final PropsMap props;

  const ElementView._raw(this.type, this.props);

  @override
  bool checked() => true; // already done in ElementType.makeView.

  @override
  Expander createExpanderForTheme(_) => type;

  @override
  Expander createExpander() => type;

  @override
  get jsonTag => type.htmlTag;

  @override
  get propsImpl => throw "not implemented"; // not needed

  @override
  get ref => props["ref"];

  String get htmlTag => type.htmlTag;

  /// The children of this element, or null if none.
  /// (May be an Iterator<View>, a View, a String, or a RawHtml.)
  get inner => props["inner"];
}

/// Represents raw (unsanitized) HTML.
/// It can be used as the value of an element's "inner" property.
/// It will be passed through Dart's sanitizer when rendered.
class RawHtml implements Jsonable {
  final String html;
  const RawHtml(this.html);
  @override
  String get jsonTag => "rawHtml";
}

/// The structure of an HTML element, as represented by an [ElementView].
class ElementType extends Expander {

  /// The name of the [TagSet] method that will create this element.
  /// (See [namedParamToKey] for the named parameters it will have.)
  final Symbol method;

  /// The name of the HTML element that TagTree will render.
  final String htmlTag;

  final List<PropType> _props1;
  final List<PropType> _props2;

  /// Defines a new element type.
  /// As a convenience, the element's property types may be passed in as two lists
  /// and they will automatically be concatenated.
  /// (This is because there's no way to concatenate const lists in Dart.)
  const ElementType(this.method, this.htmlTag, this._props1, [this._props2 = const []]);

  /// Checks that the element definition is well-formed.
  /// Called automatically when [props] is accessed.
  /// (Not done in the constructor so that it can be const.)
  bool checked() {
    assert(method != null);
    assert(htmlTag != null);
    for (var p in _props1) {
      assert(p.checked());
    }
    for (var p in _props2) {
      assert(p.checked());
    }
    return true;
  }

  /// Creates a view that will render as this HTML element.
  /// The map must only contain properties listed in [propTypes].
  View makeView(Map<String, dynamic> propMap) {
    var v = new ElementView._raw(this, new PropsMap(propMap));
    assert(checkView(v));
    return v;
  }

  @override
  expand(v) => v;

  /// A description of each property that may be passed to [makeView].
  /// This includes regular HTML attributes, handler properties,
  /// and special properties used to hold the element's children.
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

  /// The same properties as [propTypes], but as a map.
  Map<String, PropType> get propsByName {
    var out = _propsByName[this];
    if (out == null) {
      out = <String, PropType>{};
      for (var p in propTypes) {
        out[p.propKey] = p;
      }
      _propsByName[this] = out;
    }
    return out;
  }

  /// The description of each property that stores a handler.
  Iterable<HandlerType> get handlerTypes => propTypes.where((t) => t is HandlerType);

  /// A map from a named parameter to the property key to use with [makeView].
  /// There is one entry for each property.
  Map<Symbol, String> get namedParamToKey {
    var out = <Symbol, String>{};
    for (var propType in propTypes) {
      out[propType.namedParam] = propType.propKey;
    }
    return out;
  }

  /// Checks that a new ElementView only has the properties that it's allowed.
  /// (Called automatically on view creation when Dart is running in checked mode.)
  bool checkView(ElementView v) {
    assert(v != null);
    PropsMap props = v.props;

    // Checks that each key and value is allowed.
    var byName = propsByName;
    for (String key in props.keys) {
      if (!byName.containsKey(key)) {
        throw "property not supported: ${key} in ${v.htmlTag}";
      }
      byName[key].checkValue(props[key]);
    }

    assert(props["value"] == null || props["defaultValue"] == null);
    return true;
  }

  // Lazily initialized indexes.
  static final _props = new Expando<List<PropType>>();
  static final _propsByName = new Expando<Map<String, PropType>>();
}

/// A description of one property of an [ElementView].
class PropType {
  /// The named parameter that holds this property in a method
  /// call that creates an ElementView. (Used in a [TagSet].)
  final Symbol namedParam;

  /// The property key to use with [ElementType#makeView].
  final String propKey;

  const PropType(this.namedParam, this.propKey);

  bool checked() {
    assert(namedParam != null);
    assert(propKey != null);
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
    assert(inner == null || inner is String || inner is RawHtml ||
        inner is View || inner is Iterable);
    return true;
  }
}

/// The type of an HTML attribute.
class AttributeType extends PropType {
  const AttributeType(Symbol sym, String name) : super(sym, name);

  @override
  bool checkValue(value) {
    assert(value is String || value is num); // automatically converted
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
