part of core;

/// A factory for tags (and their implementations).
class TagMaker {
  final Map<Symbol, TagDef> defs;
  TagMaker(this.defs);

  /// Creates a new tag for one of the TagDefs in this set.
  Tag makeTag(Symbol tag, Map<Symbol, dynamic> props) {
    TagDef def = defs[tag];
    if (def == null) {
      throw "undefined tag: ${tag}";
    }
    return def.makeTag(props);
  }

  /// Tags may also be created by calling a method with the same name.
  /// It's best to do this using a mixin class such as [HtmlTags].
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      TagDef def = defs[inv.memberName];
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
