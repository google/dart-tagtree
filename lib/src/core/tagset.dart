part of core;

typedef bool ShouldUpdateFunc(Props p, Props next);

typedef Widget CreateWidgetFunc();

/// A set of tags that may be used to construct a tag tree.
/// Automatically includes HTML tags.
class TagSet extends BaseTagSet with HtmlTags {
  TagSet() {
    defineTags(htmlDefs);
  }

  /// Returns the parameter name and corresponding JSON tag of each HTML handler
  /// supported by this TagSet.
  Map<Symbol, String> get handlerNames => _htmlHandlerNames;

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

/// A set of tags that starts out empty.
class BaseTagSet {
  final Map<Symbol, TagDef> _methodToDef = <Symbol, TagDef>{};

  /// Adds a Tag to this TagSet, so that it's callable via noSuchMethod.
  /// (To support autocomplete, TagSets might also implement an
  /// interface declaring the same method.)
  void defineTag(TagDef def) {
    assert(def.type != null);
    assert(!(_methodToDef.containsKey(def.type.sym)));
    _methodToDef[def.type.sym] = def;
  }

  /// Defines many tags at once. (A convenience for supporting mixins.)
  void defineTags(Iterable<TagDef> defs) {
    for (TagDef def in defs) {
      defineTag(def);
    }
  }

  /// Returns the definition of every tag supported by this TagSet.
  Iterable<TagDef> get defs => _methodToDef.values;

  /// Defines a custom tag that's rendered by expanding a template.
  ///
  /// The render function should take a named parameter for each
  /// of the Tag's props.
  ///
  /// For increased performance, the optional shouldUpdate function may be
  /// used to avoid expanding the template when no properties have changed.
  ///
  /// If the custom tag should have internal state, use [defineWidget] instead.
  void defineTemplate({Symbol method, TagType type, ShouldUpdateFunc shouldUpdate,
    Function render}) {
    assert(method == null || type == null);
    if (type == null) {
      assert(method != null);
      type = new TagType(method);
    }
    defineTag(new TemplateDef(type: type, shouldUpdate: shouldUpdate, render: render));
  }

  /// Defines a custom Tag that has state.
  ///
  /// For custom tags that are stateless, use [defineTemplate] instead.
  void defineWidget({Symbol method, TagType type, CreateWidgetFunc make}) {
    assert(method == null || type == null);
    if (type == null) {
      assert(method != null);
      type = new TagType(method);
    }
    defineTag(new WidgetDef(type: type, make: make));
  }

  /// Creates a new tag for any of the TagDefs in this set.
  TagNode makeTag(Symbol tagMethodName, Map<Symbol, dynamic> props) {
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