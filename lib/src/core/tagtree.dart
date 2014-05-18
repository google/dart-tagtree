part of core;

/// Tags are nodes in a tree data structure that's similar to a tree of HTML elements.
/// They are more general than HTML elements because they support custom tags without
/// requiring any browser support.
///
/// Each Tag has a [TagDef] that determines whether it has state, how it will be rendered
/// to HTML, and whether it can be serialized as JSON.
///
/// A tag's props are similar to HTML attributes, but instead of storing a string,
/// they sometimes store arbitrary JSON, child tags, or callback functions.
///
/// The children of a tag (if any) are usually stored in its "inner" prop.
///
/// To construct a tag, use a [TagMaker] or a subclass of [TagDef].
/// To define a custom tag, use [BaseTagMaker.defineTemplate] or [BaseTagMaker.defineWidget].
class Tag {
  final TagDef def;
  final Map<Symbol, dynamic> propMap;
  Props _props;

  Tag._raw(this.def, this.propMap);

  /// Provides access to the tag's props as a map.
  operator[](Symbol key) => propMap[key];

  /// Provides access to the tag's props as fields.
  Props get props {
    if (_props == null) {
      _props = new Props(propMap);
    }
    return _props;
  }
}

/// A wrapper allowing a [Tag]'s props to be accessed as fields.
@proxy
class Props {
  final Map<Symbol, dynamic> _props;

  const Props(this._props);

  noSuchMethod(Invocation inv) {
    if (inv.isGetter) {
      if (_props.containsKey(inv.memberName)) {
        return _props[inv.memberName];
      }
    }
    print("keys: ${_props.keys.join(", ")}");
    return super.noSuchMethod(inv);
  }
}

/// A Tag that can be serialized to JSON.
class JsonableTag extends Tag implements Jsonable {
  JsonableTag._raw(TagDef def, Map<Symbol, dynamic> propMap) : super._raw(def,  propMap) {
    assert(def.jsonNames.checkPropKeys(propMap));
  }

  String get jsonTag => def.jsonNames.tagName;

  /// Returns all the props using string keys instead of symbol keys.
  Map<String, dynamic> propsToJson() => def.jsonNames.propsToJson(propMap);
}

/// A TagDef acts as a tag constructor and also determines the behavior of the
/// tags it creates.
abstract class TagDef {
  /// The constructing method name on the TagMaker, or null if none.
  final Symbol methodName;
  /// The names to use for JSON serialization, or null if not serializable.
  final JsonNames jsonNames;

  const TagDef(this.methodName, this.jsonNames);

  Tag makeTag(Map<Symbol, dynamic> props) {
    if (jsonNames != null) {
      return new JsonableTag._raw(this, props);
    } else {
      return new Tag._raw(this, props);
    }
  }

  // Implement call() with any named arguments.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod && inv.memberName == #call) {
      if (!inv.positionalArguments.isEmpty) {
        throw "position arguments not supported for tags";
      }
      return makeTag(inv.namedArguments);
    }
    return super.noSuchMethod(inv);
  }
}

// Maps between symbols and strings for JSON serialization.
class JsonNames {
  final String tagName;
  final Map<Symbol, String> _propNames;
  final Map<String, Symbol> _propKeys;
  JsonNames(this.tagName, this._propNames, this._propKeys);

  /// Verifies that a propMap contains serializable property keys.
  bool checkPropKeys(Map<Symbol, dynamic> propMap) {
    for (Symbol key in propMap.keys) {
      if (!_propNames.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }
    return true;
  }

  /// Converts a map from symbol keys to string keys.
  Map<String, dynamic> propsToJson(Map<Symbol, dynamic> propMap) {
    var jsonMap = {};
    for (Symbol sym in propMap.keys) {
      String field = _propNames[sym];
      assert(field != null);
      jsonMap[field] = propMap[sym];
    }
    return jsonMap;
  }

  /// Converts a map from string keys to symbol keys.
  Map<Symbol, dynamic> propsFromJson(Map<String, dynamic> jsonMap) {
    var propMap = <Symbol, dynamic>{};
    for (String field in jsonMap.keys) {
      var sym = _propKeys[field];
      assert(sym != null);
      propMap[sym] = jsonMap[field];
    }
    return propMap;
  }
}

/// The internal constructor for tags representing HTML elements.
///
/// To construct a tag for an HTML element, use [TagMaker].
class EltDef extends TagDef {

  /// A map from Dart named parameters (which will be minified) to their corresponding strings.
  /// The strings are used for creating and updating HTML elements, and for JSON serialization.
  final Map<Symbol, String> _attNames;

  /// A map from Dart named parameters to their corresponding strings.
  /// The strings are used for JSON serialization.
  final Map<Symbol, String> _handlerNames;

  EltDef._raw(Symbol methodName, JsonNames jsonNames, this._attNames, this._handlerNames) :
    super(methodName, jsonNames);

  /// The name of the HTML element.
  String get tagName => jsonNames.tagName;

  @override
  JsonableTag makeTag(Map<Symbol, dynamic> props) {

    var inner = props[#inner];
    assert(inner == null || inner is String || inner is Tag || inner is Iterable);
    assert(inner == null || props[#innerHtml] == null);
    assert(props[#value] == null || props[#defaultValue] == null);

    return super.makeTag(props);
  }

  String getAttributeName(Symbol propKey) => _attNames[propKey];

  bool isHandler(Symbol propKey) => _handlerNames.containsKey(propKey);
}

/// Creates tags that are rendered by expanding a template.
class TemplateDef extends TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function _renderFunc;

  /// As an alternative, see [TagMaker.defineTemplate].
  TemplateDef(Symbol methodName, ShouldUpdateFunc shouldUpdate, Function render) :
    this.shouldUpdate = shouldUpdate == null ? _alwaysUpdate : shouldUpdate,
    this._renderFunc = render,
    super(methodName, null) {
    assert(render != null);
  }

  Tag render(Map<Symbol, dynamic> props) {
    return Function.apply(_renderFunc, [], props);
  }

  static _alwaysUpdate(p, next) => true;
}

/// Creates tags that are rendered as a Widget.
class WidgetDef extends TagDef {
  final CreateWidgetFunc createWidget;

  /// As an alternative, see [TagMaker.defineTemplate].
  const WidgetDef(Symbol methodName, this.createWidget) : super(methodName, null);
}


