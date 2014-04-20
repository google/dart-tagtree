part of core;

class EltDef extends TagDef {
  final String tagName;

  EltDef(this.tagName);

  Tag makeTag(Map<Symbol, dynamic> props) {
    return new EltTag(this, props);
  }
}

class EltTag extends Tag implements Jsonable {
  EltTag(EltDef def, Map<Symbol, dynamic> props) : super(def, props);
  EltDef get def => super.def;
  String get jsonTag => def.tagName;
}
