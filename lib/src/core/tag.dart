part of core;

/// A tag constructor. Also represents the tag type.
abstract class TagDef {

  const TagDef();

  Tag makeTag(Map<Symbol, dynamic> props) {
    return new Tag(this, props);
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

/// A node in a tag tree.
class Tag {
  final TagDef def;
  final Map<Symbol, dynamic> props;

  Tag(this.def, this.props);
}
