part of core;

/// A Dart object that might be encoded as tagged JSON.
abstract class Jsonable {

  /// If this instance can be encoded as tagged JSON, returns the tag of the
  /// JsonRule that should be used. (JsonRule.appliesTo must also return true
  /// for this instance.) Otherwise returns null.
  String get jsonTag;
}
