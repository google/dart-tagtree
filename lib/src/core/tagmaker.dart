part of core;

typedef bool ShouldUpdateFunc(Props p, Props next);

typedef Widget CreateWidgetFunc();

/// Creates HTML tags.
/// (This class may be exended to support custom tags.)
class TagMaker extends BaseTagMaker with HtmlTags {
  TagMaker() {
    defineTags(htmlDefs);
  }

  /// Returns the parameter name and corresponding JSON tag of each HTML handler
  /// supported by this TagMaker.
  Map<Symbol, String> get handlerNames => _htmlHandlerNames;

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

/// A factory for a set of tags.
/// BaseTagMaker has no tags predefined.
class BaseTagMaker {
  final Map<Symbol, TagDef> _methodToDef = <Symbol, TagDef>{};

  /// Adds a Tag to this TagMaker, so that it's callable via noSuchMethod.
  /// (To support autocomplete, TagMakers might also implement an
  /// interface declaring the same method.)
  void defineTag(TagDef def) {
    assert(def.methodName != null);
    assert(!(_methodToDef.containsKey(def.methodName)));
    _methodToDef[def.methodName] = def;
  }

  /// Defines many tags at once. (A convenience for supporting mixins.)
  void defineTags(Iterable<TagDef> defs) {
    for (TagDef def in defs) {
      defineTag(def);
    }
  }

  /// Returns the definition of every tag supported by this TagMaker.
  Iterable<TagDef> get defs => _methodToDef.values;

  /// Defines a custom tag that's rendered by expanding a template.
  ///
  /// The render function should take a named parameter for each
  /// of the Tag's props.
  ///
  /// For increased performance, the optional shouldUpdate function may be
  /// used to avoid expanding the template when no properties have changed.
  ///
  /// If the custom tag should have internal state, use defineWidget instead.
  TagDef defineTemplate({Symbol method, ShouldUpdateFunc shouldUpdate, Function render}) {
    var def = new TemplateDef(method, shouldUpdate, render);
    if (method != null) {
      defineTag(def);
    }
    return def;
  }

  /// Defines a custom Tag that has state.
  ///
  /// For custom tags that are stateless, use defineTemplate instead.
  TagDef defineWidget({Symbol method, CreateWidgetFunc create}) {
    var def = new WidgetDef(method, create);
    if (method != null) {
      defineTag(def);
    }
    return def;
  }

  /// Creates a new tag for any of the TagDefs in this set.
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
