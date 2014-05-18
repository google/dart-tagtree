part of core;

/// A TagMaker mixin that provides HTML tags.
/// TODO: implement more elements and attributes.
abstract class HtmlTags {

  Tag Div({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});
  Tag Span({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});

  Tag Header({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});
  Tag Footer({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});

  Tag H1({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});
  Tag H2({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});
  Tag H3({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});

  Tag P({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});
  Tag Pre({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});

  Tag Ul({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});
  Tag Li({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});

  Tag Table({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});
  Tag Tr({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});
  Tag Td({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});

  Tag Img({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref, width, height, src});
  Tag Canvas({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref, width, height});

  Tag Form({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onSubmit,
    inner, innerHtml, ref});
  Tag Input({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue, ref, type, min, max});
  Tag TextArea({id, clazz,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue, ref});
  Tag Button({id, clazz, onClick,
    onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml, ref});

  /// The definitions of all HTML tags.
  /// (Subclasses must install them using [BaseTagMaker#defineTags].)
  List<TagDef> get htmlDefs => _htmlDefs;

  static List<TagDef> _htmlDefs = () {

    Map<String, Symbol> propNameToKey = _invertMap(_htmlPropNames);

    var out = <TagDef>[];

    for (Symbol key in _htmlTagNames.keys) {
      var val = _htmlTagNames[key];
      out.add(new EltDef._raw(key, new JsonNames(val, _htmlPropNames, propNameToKey),
          _htmlAttributeNames, _htmlHandlerNames));
    }

    return out;
  }();

  static Map _invertMap(Map m) {
    var result = {};
    m.forEach((k,v) => result[v] = k);
    assert(m.length == result.length);
    return result;
  }
}

final Map<Symbol, String> _htmlTagNames = {
  #Div: "div",
  #Span: "span",
  #Header: "header",
  #Footer: "footer",

  #H1: "h1",
  #H2: "h2",
  #H3: "h3",

  #P: "p",
  #Pre: "pre",

  #Ul: "ul",
  #Li: "li",

  #Table: "table",
  #Tr: "tr",
  #Td: "td",

  #Img: "img",
  #Canvas: "canvas",

  #Form: "form",
  #Input: "input",
  #TextArea: "textarea",
  #Button: "button"
};

final Map<Symbol, String> _htmlAttributeNames = {
  #id: "id",
  #clazz: "class",

  #src: "src",
  #width: "width",
  #height: "height",

  #type: "type",
  #value: "value",
  #min: "min",
  #max: "max"
};

final Map<Symbol, String> _htmlHandlerNames = {
  #onChange: "onChange",
  #onClick: "onClick",
  #onMouseDown: "onMouseDown",
  #onMouseOver: "onMouseOver",
  #onMouseUp: "onMouseUp",
  #onMouseOut: "onMouseOut",
  #onSubmit: "onSubmit"
};

final Map<Symbol, String> _htmlSpecialPropNames = {
  #inner: "inner",
  #innerHtml: "innerHtml",
  #ref: "ref",
  #defaultValue: "defaultValue"
};

final Map<Symbol, String> _htmlPropNames = {}
  ..addAll(_htmlSpecialPropNames)
  ..addAll(_htmlAttributeNames)
  ..addAll(_htmlHandlerNames);
