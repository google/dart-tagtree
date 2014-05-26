part of json;

class TaggedJsonCodec extends Codec<dynamic, String> {
  Converter<dynamic, String> encoder;
  Converter<String, dynamic> decoder;

  TaggedJsonCodec(Iterable<JsonRule> rules, Iterable<TagFinder> getters) {
    var tagToRule = <String, JsonRule>{};
    for (var r in rules) {
      assert(!tagToRule.containsKey(r.tagName));
      tagToRule[r.tagName] = r;
    }
    encoder = new TaggedJsonEncoder(tagToRule, getters);
    decoder = new TaggedJsonDecoder(tagToRule);
  }
}

/// A rule to be applied when encoding and decoding objects with a certain tag.
abstract class JsonRule<T> {

  /// A tag used on the wire to identify instances encoded using this rule.
  /// (The tag must be unique within a [JsonRuleSet].)
  final String tagName;

  const JsonRule(this.tagName);

  /// Returns true if this rule can encode the instance.
  bool appliesTo(instance);

  /// Returns the state of a Dart object as a JSON-encodable tree.
  /// The result may contain Jsonable instances and these will be
  /// encoded recursively.
  encode(T instance);

  /// Given a tree returned by [encode], creates an instance.
  T decode(jsonTree);
}

/// A TagFinder finds the JSON tag for encoding an instance.
abstract class TagFinder<T> {

  /// Returns true if this finder works for the given instance,
  /// and all other instances with the same runtime type.
  bool appliesToType(instance);

  String getTag(T instance);
}

/// Encodes a Dart object as a tree of tagged JSON.
///
/// The tree may contain values directly encodable as JSON (String, Map, List, and so on)
/// or instances for which there is a [TagFinder] that returns the tag of the rule to use.
class TaggedJsonEncoder extends Converter<dynamic, String> {
  final Map<String, JsonRule> _rules;
  final Iterable<TagFinder> _getters;

  /// A cache that's populated when a runtime type is first seen.
  final _getterCache = <Type, TagFinder>{};

  TaggedJsonEncoder(this._rules, this._getters);

  String convert(object) {
    StringBuffer out = new StringBuffer();
    _encodeTree(out, object);
    return out.toString();
  }

  void _encodeTree(StringBuffer out, v) {

    if (v == null || v is bool || v is num || v is String) {
      out.write(JSON.encode(v));
      return;
    }

    if (v is List) {
      out.write("[0");
      for (var item in v) {
        out.write(",");
        _encodeTree(out, item);
      }
      out.write("]");
      return;
    }

    if (v is Map) {
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
      return;
    }

    JsonRule rule = _findRule(v);
    if (rule == null) {
      // encoding will probably fail, but give the default encoder a chance.
      out.write(JSON.encode(v));
      return;
    }

    assert(rule.appliesTo(v));
    var data = rule.encode(v);
    out.write("[${JSON.encode(rule.tagName)},");
    _encodeTree(out, data);
    out.write("]");
  }

  /// Returns the rule or null if there is none.
  JsonRule _findRule(v) {
    TagFinder getter = _findGetter(v);
    if (getter == null) {
      return null;
    }

    String tag = getter.getTag(v);
    if (tag == null) {
      return null;
    }

    return _rules[tag];
  }

  /// Returns the TagGetter or null if there is none.
  TagFinder _findGetter(v) {
    if (_getterCache.containsKey(v.runtimeType)) {
      return _getterCache[v.runtimeType];
    }

    // We haven't seen this type before, so search the slow way.
    for (var getter in _getters) {
      if (getter.appliesToType(v)) {
        _getterCache[v.runtimeType] = getter;
        return getter;
      }
    }

    // Not found. Cache this so we don't search again.
    _getterCache[v.runtimeType] = null;
    return null;
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
