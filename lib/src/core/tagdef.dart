part of core;

/// A TagDef acts as a tag constructor and also determines the behavior of the
/// tags it creates.
abstract class TagDef {
  /// The constructing method name on the TagMaker, or null if none.
  final Symbol methodName;

  /// The tag name to use for JSON serialization, or null if not serializable.
  final String jsonName;

  /// Optional information about the props of this tag.
  /// (The PropDef must be present for handlers and JSON serialization.)
  final List<PropType> _propDefs;

  static final _jsonMappers = new Expando<JsonMapper>("jsonMapper");

  const TagDef(this.methodName, [this.jsonName, this._propDefs = const []]);

  PropType operator[](Symbol key) => jsonMapper._bySymbol[key];

  /// Returns the mapper to use for JSON serialization, or null if not serializable.
  JsonMapper get jsonMapper {
    // Use lazy initializion with an Expando so that TagDef can be const.
    var mapper = _jsonMappers[this];
    if (mapper == null) {
      if (jsonName == null) {
        return null;
      }
      mapper = new JsonMapper(this);
      _jsonMappers[this] = mapper;
    }
    return mapper;
  }

  Tag makeTag(Map<Symbol, dynamic> props) {
    assert(checkProps(props));
    if (jsonName != null) {
      return new JsonableTag._raw(this, props);
    } else {
      return new Tag._raw(this, props);
    }
  }

  /// Subclass hook to check a tag's properties.
  bool checkProps(Map<Symbol, dynamic> props) => true;

  /// Implement call() with any named arguments.
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


/// Maps between symbols and strings for JSON serialization.
class JsonMapper {
  final String tagName;
  final Map<Symbol, PropType> _bySymbol = {};
  final Map<String, PropType> _byName = {};

  JsonMapper(TagDef def) : this.tagName = def.jsonName {
    for (var p in def._propDefs) {
      assert(p.sym != null);
      assert(!_bySymbol.containsKey(p.sym));
      _bySymbol[p.sym] = p;
      assert(p.name != null);
      assert(!_byName.containsKey(p.name));
      _byName[p.name] = p;
    }
  }

  /// Verifies that a propMap contains serializable property keys.
  bool checkPropKeys(Map<Symbol, dynamic> propMap) {
    for (Symbol key in propMap.keys) {
      if (!_bySymbol.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }
    return true;
  }

  /// Converts a map from symbol keys to string keys.
  Map<String, dynamic> propsToJson(Map<Symbol, dynamic> propMap) {
    var jsonMap = {};
    for (var key in propMap.keys) {
      var name = _bySymbol[key].name;
      assert(name != null);
      jsonMap[name] = propMap[key];
    }
    return jsonMap;
  }

  /// Converts a map from string keys to symbol keys.
  Map<Symbol, dynamic> propsFromJson(Map<String, dynamic> jsonMap) {
    var propMap = <Symbol, dynamic>{};
    for (var name in jsonMap.keys) {
      var key = _byName[name].sym;
      assert(key != null);
      propMap[key] = jsonMap[name];
    }
    return propMap;
  }
}

/// Defines a tag representing an HTML element.
class EltDef extends TagDef {

  /// Defines an HTML element.
  /// The tagName is used for both HTML rendering and JSON serialization.
  const EltDef(Symbol methodName, String tagName, Iterable<PropType> props) :
    super(methodName, tagName, props);

  /// The name used when rendering the tag as HTML.
  String get tagName => jsonMapper.tagName;

  @override
  bool checkProps(Map<Symbol, dynamic> props) {
    var inner = props[#inner];
    assert(inner == null || props[#innerHtml] == null);
    assert(inner == null || inner is String || inner is Tag || inner is Iterable);
    assert(props[#value] == null || props[#defaultValue] == null);
    return true;
  }

  String getAttributeName(Symbol propKey) {
    var prop = this[propKey];
    if (prop is AttributeType) {
      return prop.name;
    } else {
      return null;
    }
  }

  bool isHandler(Symbol propKey) => this[propKey] is HandlerPropType;
}

/// Creates tags that are rendered by expanding a template.
class TemplateDef extends TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function _renderFunc;

  /// Defines a custom tag that's rendered by expanding a template.
  ///
  /// The render function should take a named parameter for each of the Tag's props.
  ///
  /// For increased performance, the optional shouldUpdate function may be used to
  /// avoid expanding the template when no properties have changed.
  ///
  /// If the custom tag should have internal state, use a WidgetDef instead.
  ///
  /// As an alternative, see [BaseTagMaker.defineTemplate].
  TemplateDef({Symbol method, ShouldUpdateFunc shouldUpdate, Function render,
      String jsonName, Iterable<PropType> props: const []}) :
    this.shouldUpdate = shouldUpdate == null ? _alwaysUpdate : shouldUpdate,
    this._renderFunc = render,
    super(method, jsonName, props) {
    assert(render != null);
  }

  Tag render(Map<Symbol, dynamic> props) {
    return Function.apply(_renderFunc, [], props);
  }

  static _alwaysUpdate(p, next) => true;
}

/// Creates tags that are rendered as widgets.
class WidgetDef extends TagDef {
  final CreateWidgetFunc make;

  /// As an alternative, see [BaseTagMaker.defineWidget].
  const WidgetDef({this.make, Symbol method, String jsonName,
    Iterable<PropType> props: const []}) :
      super(method, jsonName, props);
}

/// Creates tags with no implementation. (They cannot be rendered, only serialized.)
class RemoteTagDef extends TagDef {
  RemoteTagDef({Symbol method, String jsonName, Iterable<PropType> props: const []}) :
    super(method, jsonName, props) {
    assert(jsonName != null);
  }
}
