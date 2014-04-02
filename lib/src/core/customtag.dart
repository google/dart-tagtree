part of core;

typedef bool ShouldUpdateFunc(Props p, Props next);

/// Defines a custom tag.
abstract class TagDef {

  String get tagName => throw "tagName not implemented";

  Tag makeTag(Map<Symbol, dynamic> props) {
    return new Tag(this, props);
  }

  Tag _render(Map<Symbol, dynamic> props) {
    throw "render not implemented";
  }

  bool _shouldUpdate(Props current, Props next) {
    throw "_shouldUpdate not implemented";
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

class Tag {
  final TagDef def;
  final Map<Symbol, dynamic> props;

  Tag(this.def, this.props);
}
