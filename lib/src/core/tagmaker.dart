part of core;

typedef bool ShouldUpdateFunc(Props p, Props next);

typedef Widget CreateWidgetFunc();

/// A factory for tags (and their implementations).
class TagMaker {
  final _methodToDef = <Symbol, TagDef>{};

  /// Defines a custom tag that's rendered by expanding a template.
  ///
  /// The render function should take a named parameter for each
  /// of the Tag's props.
  ///
  /// For increased performance, the optional shouldUpdate function may be
  /// used to avoid expanding the template when no properties have changed.
  ///
  /// If the custom tag should have internal state, use [defineWidget] instead.
  TagDef defineTemplate({ShouldUpdateFunc shouldUpdate, Function render}) {
    return new TemplateDef._raw(shouldUpdate, render);
  }

  /// Defines a custom Tag that has state.
  ///
  /// For custom tags that are stateless, use [defineTemplate] instead.
  TagDef defineWidget(CreateWidgetFunc f) => new WidgetDef._raw(f);

  /// Creates a new tag for one of the TagDefs in this set.
  Tag makeTag(Symbol tag, Map<Symbol, dynamic> props) {
    TagDef def = _methodToDef[tag];
    if (def == null) {
      throw "undefined tag: ${tag}";
    }
    return def.makeTag(props);
  }

  /// Tags may also be created by calling a method with the same name.
  /// It's best to do this using a mixin class such as [HtmlTagMaker].
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
