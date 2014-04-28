part of core;

typedef bool ShouldUpdateFunc(Props p, Props next);

typedef Widget CreateWidgetFunc();

/// Creates HTML tags.
/// (This class may be exended to support custom tags.)
class TagMaker extends BaseTagMaker implements HtmlTags {
  TagMaker() {
    for (Symbol key in _defaultEltDefs.keys) {
      _defineElt(key, _defaultEltDefs[key]);
    }
  }

  /// Returns the parameter name and corresponding JSON tag of each HTML handler
  /// supported by this TagMaker.
  Map<Symbol, String> get handlerNames => _htmlHandlerNames;

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);

  /// The default HTML elements defined in every TagMaker.
  static Map<Symbol, EltDef> _defaultEltDefs = () {
    Map<Symbol, String> propNames = {}
      ..addAll(_htmlSpecialPropNames)
      ..addAll(_htmlAttributeNames)
      ..addAll(_htmlHandlerNames);

    Map<String, Symbol> propNameToKey = _invertMap(propNames);

    var defs = <Symbol, EltDef>{};

    for (Symbol key in _htmlTagNames.keys) {
      var val = _htmlTagNames[key];
      defs[key] = new EltDef._raw(val, _htmlAttributeNames, _htmlHandlerNames,
          propNames, propNameToKey);
    }

    return defs;
  }();

  static Map _invertMap(Map m) {
    var result = {};
    m.forEach((k,v) => result[v] = k);
    assert(m.length == result.length);
    return result;
  }
}

/// A factory for tags (and their implementations).
/// BaseTagMaker has no tags predefined.
class BaseTagMaker {
  final Map<Symbol, TagDef> _methodToDef = <Symbol, TagDef>{};

  /// Returns the definition of each tag supported by this TagMaker.
  Iterable<TagDef> get defs => _methodToDef.values;

  _defineElt(Symbol method, EltDef def) {
    _methodToDef[method] = def;
  }

  /// Defines a custom tag that's rendered by expanding a template.
  ///
  /// The render function should take a named parameter for each
  /// of the Tag's props.
  ///
  /// For increased performance, the optional shouldUpdate function may be
  /// used to avoid expanding the template when no properties have changed.
  ///
  /// If the custom tag should have internal state, use [defineWidget] instead.
  TagDef defineTemplate({Symbol method, ShouldUpdateFunc shouldUpdate, Function render}) {
    var def = new TemplateDef._raw(shouldUpdate, render);
    if (method != null) {
      _methodToDef[method] = def;
    }
    return def;
  }

  /// Defines a custom Tag that has state.
  ///
  /// For custom tags that are stateless, use [defineTemplate] instead.
  TagDef defineWidget({Symbol method, CreateWidgetFunc create}) {
    var def = new WidgetDef._raw(create);
    if (method != null) {
      _methodToDef[method] = def;
    }
    return def;
  }

  /// Creates a new tag for one of the TagDefs in this set.
  Tag makeTag(Symbol tagMethodName, Map<Symbol, dynamic> props) {
    TagDef def = _methodToDef[tagMethodName];
    if (def == null) {
      throw "undefined tag: ${tagMethodName}";
    }
    return def.makeTag(props);
  }

  /// Tags may also be created by calling a method with the same name.
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      TagDef def = _methodToDef[inv.memberName];
      if (def != null) {
        if (!inv.positionalArguments.isEmpty) {
          throw "positional arguments not supported when creating tags";
        }
        return def.makeTag(inv.namedArguments);
      }
    }
    return super.noSuchMethod(inv);
  }
}
