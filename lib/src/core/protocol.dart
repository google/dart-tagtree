part of core;

/// A collection of tags defining a protocol.
class TagProtocol {
  final List<TagInterface> tags;

  const TagProtocol(this.tags);
}

class TagInterface {
  /// The name of this tag as a Dart symbol.
  /// (The method name used to create this tag.)
  final Symbol sym;

  /// The name of this tag in JSON.
  /// (May be null if not serializable.)
  final String name;

  /// The allowed properties of this tag.
  final List<PropDef> props;

  const TagInterface(this.sym, this.name, this.props);
}

/// Defines what may be stored in a prop.
class PropDef {
  /// The name of this property as a Dart symbol.
  /// The symbol is used as the prop's key and as the name of
  /// its parameter in a function call.
  final Symbol sym;

  /// The name of this property in JSON.
  /// (May be null if not serializable.)
  final String name;

  /// If not null, the property is a special type.
  final PropType type;

  const PropDef(this.sym, this.name, [this.type]);
}

/// Some properties that are handled specially.
class PropType {
  final _value;
  const PropType._raw(this._value);
  toString() => 'PropType.$_value';

  /// An HTML attribute. It will be rendered as its json tag name.
  static const ATTRIBUTE = const PropType._raw('ATTRIBUTE');

  /// An HTML event handler.
  static const HANDLER = const PropType._raw('HANDLER');
}