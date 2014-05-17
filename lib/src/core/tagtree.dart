part of core;

/// A Tag generalizes an HTML element to also include templates and widgets. Tags
/// form a tag tree similar to how HTML elements form a tree.
///
/// Each Tag has a [TagDef], which determines the tag's behavior when a tag tree is rendered.
///
/// Its props are similar to HTML attributes but instead of storing a string, they sometimes
/// store arbitrary JSON or callback functions.
///
/// The children of a tag (if any) are in its "inner" prop.
///
/// To construct a tag, see [TagMaker].
/// To define a custom tag, use [TagMaker.defineTemplate] or [TagMaker.defineWidget].
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

class JsonableTag extends Tag implements Jsonable {
  JsonableTag._raw(JsonableTagDef def, Map<Symbol, dynamic> propMap) : super._raw(def,  propMap);

  String get jsonTag => def.getJsonTag(this);
  JsonableTagDef get def => super.def;

  Map<String, dynamic> getJsonProps() {
    var state = {};
    for (Symbol sym in propMap.keys) {
      var field = def.getJsonPropName(sym);
      assert(field != null);
      state[field] = propMap[sym];
    }
    return state;
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

/// A TagDef acts as a tag constructor and also determines the behavior of the
/// tags it creates. TagDefs shouldn't be created directly; instead use
/// [TagMaker.defineTemplate] or [TagMaker.defineWidget].
abstract class TagDef {
  /// The constructing method name on the TagMaker, or null if none.
  final Symbol methodName;

  const TagDef(this.methodName);

  Tag makeTag(Map<Symbol, dynamic> props) => new Tag._raw(this, props);

  /// Subclass hook to make tags encodable as tagged JSON.
  /// By default, they aren't encodable.
  String getJsonTag(Tag tag) => null;

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

abstract class JsonableTagDef extends TagDef {
  JsonableTagDef(Symbol methodName) : super(methodName);
  String get tagName;
  String getJsonPropName(Symbol propKey);
  Symbol getJsonPropKey(String propName);
}

/// The internal constructor for tags representing HTML elements.
///
/// To construct a tag for an HTML element, use [TagMaker].
class EltDef extends JsonableTagDef {

  /// The name of the HTML element; also used for JSON encoding.
  final String tagName;

  /// A map from Dart named parameters (which will be minified) to their corresponding strings.
  /// The strings are used for creating and updating HTML elements, and for JSON serialization.
  final Map<Symbol, String> _atts;

  /// A map from Dart named parameters to their corresponding strings.
  /// The strings are used for JSON serialization.
  final Map<Symbol, String> _handlerNames;

  final Map<Symbol, String> _propKeyToJsonName;
  final Map<String, Symbol> _jsonNameToPropKey;

  EltDef._raw(Symbol methodName, this.tagName, this._atts, this._handlerNames,
      this._propKeyToJsonName, this._jsonNameToPropKey) : super(methodName);

  @override
  JsonableTag makeTag(Map<Symbol, dynamic> props) {
    for (Symbol key in props.keys) {
      if (!_propKeyToJsonName.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }

    var inner = props[#inner];
    assert(inner == null || inner is String || inner is Tag || inner is Iterable);
    assert(inner == null || props[#innerHtml] == null);
    assert(props[#value] == null || props[#defaultValue] == null);

    return new JsonableTag._raw(this, props);
  }

  @override
  String getJsonTag(Tag tag) => tagName;
  String getJsonPropName(Symbol propKey) => _propKeyToJsonName[propKey];
  Symbol getJsonPropKey(String propName) => _jsonNameToPropKey[propName];

  String getAttributeName(Symbol propKey) => _atts[propKey];

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


