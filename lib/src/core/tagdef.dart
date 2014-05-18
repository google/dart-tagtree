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
  final List<PropDef> _propDefs;

  static final _jsonMappers = new Expando<JsonMapper>("jsonMapper");

  const TagDef(this.methodName, [this.jsonName, this._propDefs = const []]);

  PropDef operator[](Symbol key) => jsonMapper._byKey[key];

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

/// Defines what may be stored in a property.
class PropDef {
  /// The key into the propMap (and also the named parameter for a TagMaker).
  final Symbol key;

  /// The name to be used for serializing to JSON.
  /// (May be null if not serializable.)
  final String jsonName;

  /// If not null, the property is a special type.
  final PropType type;

  const PropDef(this.key, this.jsonName, this.type);
}

/// Some properties that are handled specially.
class PropType {
  final _value;
  const PropType._raw(this._value);
  toString() => 'PropType.$_value';

  /// An HTML attribute. It will be rendered as its json tag name.
  static const ATTRIBUTE = const PropType._raw('ATTRIBUTE');

  /// An HTML event handler.
  static const HANDLER = const PropType._raw('HANDLER');
}

/// Maps between symbols and strings for JSON serialization.
class JsonMapper {
  final String tagName;
  final Map<Symbol, PropDef> _byKey = {};
  final Map<String, PropDef> _byJsonName = {};

  JsonMapper(TagDef def) : this.tagName = def.jsonName {
    for (var p in def._propDefs) {
      assert(p.key != null);
      assert(!_byKey.containsKey(p.key));
      _byKey[p.key] = p;
      assert(p.jsonName != null);
      assert(!_byJsonName.containsKey(p.jsonName));
      _byJsonName[p.jsonName] = p;
    }
  }

  /// Verifies that a propMap contains serializable property keys.
  bool checkPropKeys(Map<Symbol, dynamic> propMap) {
    for (Symbol key in propMap.keys) {
      if (!_byKey.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }
    return true;
  }

  /// Converts a map from symbol keys to string keys.
  Map<String, dynamic> propsToJson(Map<Symbol, dynamic> propMap) {
    var jsonMap = {};
    for (var key in propMap.keys) {
      var name = _byKey[key].jsonName;
      assert(name != null);
      jsonMap[name] = propMap[key];
    }
    return jsonMap;
  }

  /// Converts a map from string keys to symbol keys.
  Map<Symbol, dynamic> propsFromJson(Map<String, dynamic> jsonMap) {
    var propMap = <Symbol, dynamic>{};
    for (var name in jsonMap.keys) {
      var key = _byJsonName[name].key;
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
  const EltDef(Symbol methodName, String tagName, Iterable<PropDef> props) :
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
    if (prop.type == PropType.ATTRIBUTE) {
      return prop.jsonName;
    } else {
      return null;
    }
  }

  bool isHandler(Symbol propKey) => this[propKey].type == PropType.HANDLER;
}

/// Creates tags that are rendered by expanding a template.
class TemplateDef extends TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function _renderFunc;

  /// As an alternative, see [TagMaker.defineTemplate].
  TemplateDef(Symbol methodName, ShouldUpdateFunc shouldUpdate, Function render) :
    this.shouldUpdate = shouldUpdate == null ? _alwaysUpdate : shouldUpdate,
    this._renderFunc = render,
    super(methodName) {
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
  const WidgetDef(Symbol methodName, this.createWidget) : super(methodName);
}
