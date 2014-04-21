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

class TextDef extends TagDef {
  static final instance = new TextDef();
}

class EltDef extends TagDef {
  final String tagName;

  EltDef(this.tagName);

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

    return new EltTag(this, props);
  }
}

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

class WidgetDef extends TagDef {
  final CreateWidgetFunc createWidget;
  const WidgetDef(this.createWidget);
}

/// A node in a tag tree.
class Tag {
  final TagDef def;
  final Map<Symbol, dynamic> props;

  Tag(this.def, this.props);
}

class EltTag extends Tag implements Jsonable {
  EltTag(EltDef def, Map<Symbol, dynamic> props) : super(def, props);
  EltDef get def => super.def;
  String get jsonTag => def.tagName;
}
