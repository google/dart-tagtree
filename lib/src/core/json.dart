part of core;

/// A Dart object that may be encoded as tagged JSON.
abstract class Jsonable {

  /// Returns the tag of the rule to be used to encode this instance.
  /// ([JsonRule.appliesTo] must return true for this instance.)
  String get jsonTag;
}

/// A rule to be applied when encoding and decoding objects with a certain tag.
abstract class JsonRule<T extends Jsonable> {

  /// A tag used on the wire to identify instances encoded using this rule.
  /// (The tag must be unique within a [JsonRuleSet].)
  final String tagName;

  JsonRule(this.tagName);

  /// Returns true if this rule can encode the instance.
  bool appliesTo(Jsonable instance);

  /// Returns the state of a Dart object as a JSON-encodable tree.
  /// The result may contain Jsonable instances and these will be
  /// encoded recursively.
  encode(T instance);

  /// Given a tree returned by [encode], creates an instance.
  T decode(jsonTree);
}

/// The rules for encoding and decoding a tree of objects as JSON.
/// (Usually the same rules should be used for encoding and decoding.)
class JsonRuleSet {
  final _rules = <String, JsonRule>{};

  void add(JsonRule rule) {
    assert(!_rules.containsKey(rule.tagName));
    _rules[rule.tagName] = rule;
  }

  /// Returns true if there is a rule for the given tag.
  bool supportsTag(String tag) {
    return _rules.containsKey(tag);
  }

  /// Converts a tree of Dart objects to JSON. The tree may contain values directly
  /// encodable as JSON (String, Map, List, and so on) and instances of
  /// Jsonable where [Jsonable.jsonTag] matches a rule in this ruleset.
  String encodeTree(tree) {
    StringBuffer out = new StringBuffer();
    _encodeTree(out, tree);
    return out.toString();
  }

  void _encodeTree(StringBuffer out, v) {
    if (v is Jsonable) {
      String tag = v.jsonTag;
      var rule = _rules[tag];
      assert(rule.appliesTo(v));
      var data = rule.encode(v);
      out.write("[${JSON.encode(tag)},");
      _encodeTree(out, data);
      out.write("]");
    } else if (v is List) {
      out.write("[0");
      for (var item in v) {
        out.write(",");
        _encodeTree(out, item);
      }
      out.write("]");
    } else if (v is Map) {
      Map<String, Object> m = v;
      out.write("{");
      bool first = true;
      v.forEach((String key, Object value) {
        if (!first) {
          out.write(',');
        }
        out.write("${JSON.encode(key)}:");
        _encodeTree(out, value);
        first = false;
      });
      out.write("}");
    } else {
      out.write(JSON.encode(v));
    }
  }

  decodeTree(String source) => JSON.decode(source, reviver: (k,v) {
    if (v is List) {
      var tag = v[0];
      if (tag == 0) {
        v.remove(0);
        return v;
      } else {
        var rule = _rules[tag];
        if (rule == null) {
          throw "no rule for tag: ${tag}";
        }
        assert(v.length == 2);
        return rule.decode(v[1]);
      }
    } else {
      return v;
    }
  });
}
