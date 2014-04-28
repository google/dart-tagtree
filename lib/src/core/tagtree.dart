part of core;

/// A Tag generalizes an HTML element to also include templates and widgets. Tags
/// form a tag tree similar to how HTML elements form a tree.
///
/// Each Tag has a TagDef, which determines the tag's behavior when a tag tree is rendered.
///
/// Its props are similar to HTML attributes but instead of storing a string, they sometimes
/// store arbitrary JSON or callback functions.
///
/// The children of a tag (if any) are in its "inner" prop.
///
/// To construct a Tag that renders as an HTML element, call the appropriate method on
/// [htmlTags].
///
/// To create a custom tag, first use [defineTemplate] or [defineWidget] to create
/// a TagDef, then call it with the appropriate named parameters for its props.
class Tag implements Jsonable {
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

  String get jsonTag => def.getJsonTag(this);
}

/// A wrapper allowing a tag's props to be accessed as fields.
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
/// [defineTemplate] or [defineWidget].
abstract class TagDef {

  const TagDef();

  Tag makeTag(Map<Symbol, dynamic> props) {
    return new Tag._raw(this, props);
  }

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

/// The internal constructor for tags representing HTML elements.
///
/// To construct a Tag, use [htmlTags] instead of calling this directly.
class EltDef extends TagDef {
  final String tagName;

  /// A map from Dart named parameters (which will be minified) to their corresponding strings.
  /// The strings are used for creating and updating HTML elements, and for JSON serialization.
  final Map<Symbol, String> _atts;

  /// A map from Dart named parameters to their corresponding strings.
  /// The strings are used for JSON serialization.
  final Map<Symbol, String> _handlerNames;

  EltDef._raw(this.tagName, this._atts, this._handlerNames);

  @override
  Tag makeTag(Map<Symbol, dynamic> props) {
    for (Symbol key in props.keys) {
      if (!_htmlPropNames.containsKey(key)) {
        throw "property not supported: ${key}";
      }
    }

    var inner = props[#inner];
    assert(inner == null || inner is String || inner is Tag || inner is Iterable);
    assert(inner == null || props[#innerHtml] == null);
    assert(props[#value] == null || props[#defaultValue] == null);

    return new Tag._raw(this, props);
  }

  @override
  String getJsonTag(Tag tag) => tagName;

  String getAttributeName(Symbol propKey) => _atts[propKey];

  bool isHandler(Symbol propKey) => _handlerNames.containsKey(propKey);
}

/// Creates tags that are rendered by expanding a template.
/// To construct, use [defineTemplate].
class TemplateDef extends TagDef {
  final ShouldUpdateFunc shouldUpdate;
  final Function _renderFunc;

  TemplateDef._raw(ShouldUpdateFunc shouldUpdate, Function render) :
    this.shouldUpdate = shouldUpdate == null ? _alwaysUpdate : shouldUpdate,
    this._renderFunc = render {
    assert(render != null);
  }

  Tag render(Map<Symbol, dynamic> props) {
    return Function.apply(_renderFunc, [], props);
  }

  static _alwaysUpdate(p, next) => true;
}

/// Creates tags that are rendered as a Widget.
/// To construct, use [defineWidget].
class WidgetDef extends TagDef {
  final CreateWidgetFunc createWidget;
  const WidgetDef._raw(this.createWidget);
}


