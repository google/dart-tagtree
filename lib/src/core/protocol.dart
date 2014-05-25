part of core;

/// A collection of tag types defining a protocol.
class Protocol {
  final List<TagType> types;

  const Protocol(this.types);
}

class TagType {
  /// The name of this tag as a Dart symbol.
  /// (The method name used to create this tag.)
  final Symbol sym;

  /// The name of this tag in JSON.
  /// (May be null if not serializable.)
  final String name;

  /// The allowed properties of this tag.
  /// (As separate fields since concatenating lists isn't a const expression.)
  final List<PropType> _props1;
  final List<PropType> _props2;

  const TagType(this.sym, [this.name, this._props1 = const [], this._props2]);

  List<PropType> get props {
    var out = _props[this];
    if (out == null) {
      if (_props2 == null) {
        out = _props1;
      } else {
        out = new List.from(_props1)..addAll(_props2);
      }
      _props[this] = out;
    }
    return out;
  }

  // Lazily initialized list.
  static final _props = new Expando<List<PropType>>();
}

/// Defines what may be stored in a prop.
class PropType {
  /// The name of this property as a Dart symbol.
  /// The symbol is used as the prop's key and as the name of
  /// its parameter in a function call.
  final Symbol sym;

  /// The name of this property in JSON.
  /// (May be null if not serializable.)
  final String name;

  const PropType(this.sym, this.name);
}

class AttributeType extends PropType {
  const AttributeType(Symbol sym, String name) : super(sym, name);
}

class HandlerPropType extends PropType {
  const HandlerPropType(Symbol sym, String name) : super(sym, name);
}
