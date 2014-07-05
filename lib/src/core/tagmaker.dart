part of core;

/// A function for creating a Tag from its JSON properties.
typedef JsonTag MapToTag(Map<String, dynamic> propsMap);

/// A function for converting a Tag to a PropsMap containing its JSON properties.
///
/// For a tag to be serializable, the properties should contain JSON data
/// (including other [Jsonable] nodes) or a [HandlerFunc].
typedef PropsMap TagToProps(JsonTag tag);

/// A TagMaker provides additional ways to create a [JsonTag].
///
/// The [fromMap] method creates a tag from a map containing its properties.
///
/// The [fromInvocation] method can be used to create a tag from within
/// [noSuchMethod].
///
/// By convention, the TagMaker for "Foo" should be in a constant named "$Foo".
/// Multiple TagMakers can be collected into a [TagSet].
class TagMaker {
  /// For decoding and encoding JSON
  final String jsonTag;
  final MapToTag fromMap;
  final TagToProps toProps;
  final Iterable<HandlerType> handlers;

  /// For decoding an Invocation
  final Symbol method;
  final Map<Symbol, String> params;

  const TagMaker({this.jsonTag, this.fromMap, this.toProps, this.handlers: const [],
    this.method, this.params});

  bool checked() {
    assert(handlers != null);
    if (canDecodeJson) {
      assert(fromMap != null);
    }
    if (canDecodeInvocation) {
      assert(jsonTag != null); // for error reporting
      assert(params != null);
      assert(fromMap != null);
    }
    return true;
  }

  bool get canDecodeJson => jsonTag != null;

  bool get canDecodeInvocation => method != null;

  Tag fromInvocation(Invocation inv) {
    if (!inv.positionalArguments.isEmpty) {
      throw "positional arguments not supported when creating tags";
    }
    assert(canDecodeInvocation);
    var propsMap = <String, dynamic>{};
    for (Symbol name in inv.namedArguments.keys) {
      var propKey = params[name];
      if (propKey == null) {
        throw "no property found for ${name} in ${jsonTag}";
      }
      propsMap[propKey] = inv.namedArguments[name];
    }
    return fromMap(propsMap);
  }
}
