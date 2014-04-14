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

class TaggedJsonCodec extends Codec<dynamic, String> {
  final Iterable<JsonRule> _rules;
  final _cache = <String, JsonRule>{};

  const TaggedJsonCodec(this._rules);

  Map<String, JsonRule> get ruleset {
    if (!_cache.isEmpty) {
      return _cache;
    }
    assert(!_rules.isEmpty);
    var map = <String, JsonRule>{};
    for (var rule in _rules) {
      assert(!map.containsKey(rule.tagName));
      map[rule.tagName] = rule;
    }
    _cache.addAll(map);
    return _cache;
  }

  Converter<dynamic, String> get encoder => new TaggedJsonEncoder(ruleset);
  Converter<String, dynamic> get decoder => new TaggedJsonDecoder(ruleset);
}

/// Encodes a Dart object as a tree of tagged JSON.
///
/// The tree may contain values directly encodable as JSON (String, Map, List, and so on)
/// and instances of Jsonable where Jsonable.jsonTag matches a rule in the given ruleset.
class TaggedJsonEncoder extends Converter<dynamic, String> {
  final Map<String, JsonRule> _rules;

  TaggedJsonEncoder(this._rules);

  String convert(object) {
    StringBuffer out = new StringBuffer();
    _encodeTree(out, object);
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
}

/// Decodes tagged JSON into Dart objects.
///
/// Lists in the JSON code are treated specially based on the
/// first item, which is used as a tag. If the tag is a 0 then
/// the remaining items form the actual list. Otherwise, the
/// decoder looks up the tag in the ruleset and uses the appropriate
/// rule to decode the list.
class TaggedJsonDecoder extends Converter<String, dynamic> {
  final Map<String, JsonRule> _rules;

  TaggedJsonDecoder(this._rules);

  convert(String json) => JSON.decode(json, reviver: (k,v) {
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
