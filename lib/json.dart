/**
 * A codec for encoding and decoding objects as tagged JSON.
 *
 * To convert regular JSON to tagged JSON, add a '0' to the beginning of each list
 * to escape it:
 *
 *     ["a", "b", "c"] => [0, "a", "b", "c"]
 *
 * After escaping, we can encode other objects without conflict, by putting a tag
 * in the first position, similar to Lisp:
 *
 *     ["person", "John", "McCarthy"]
 *
 * In particular, an HTML tag can be encoded using a list and a map. For example,
 * this HTML:
 *
 *     <span class="greeting">Hello!</span>
 *
 * Can be encoded to tagged JSON like this:
 *
 *     ["span" {"class": "greeting", "inner", "Hello!"}]
 *
 * (The "inner" property is special and contains the contents of the tag.)
 *
 * In this way, we can convert trees of virtual HTML elements into JSON, which
 * is easier than implementing HTML parsing and printing.
 *
 * A [TaggedJsonCodec] implements the tagged JSON format. You must configure it
 * with a [JsonRule] for each tag that needs to be encoded and decoded.
 * Objects to be transmitted over the wire can either implement [Jsonable],
 * or if that's inconvenient, you can use a [TagFinder] to encode any object.
 */
library json;

import 'dart:convert';

part 'src/json/codec.dart';
part 'src/json/jsonable.dart';
