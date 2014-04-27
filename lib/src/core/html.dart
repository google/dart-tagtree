part of core;

/// The API for creating nodes in a tag tree.
/// (Callers must subclass.)
/// You may want to assign this to '$' for brevity.)
/// TODO: implement more elements and attributes.
abstract class HtmlTags extends TagMaker {

  factory HtmlTags() {
    return new _HtmlTags();
  }

  /// For subclasses.
  HtmlTags.init() {
    _methodToDef.addAll(_htmlEltDefs);
  }

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
}

class _HtmlTags extends HtmlTags {
  _HtmlTags() : super.init();

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

final HtmlSchema htmlSchema = new _HtmlSchema();

abstract class HtmlSchema {

  /// A map from Dart method names (which will be minified) to their corresponding strings.
  /// The symbols must correspond to methods in HtmlTags.
  /// The strings are used for creating HTML elements and for JSON serialization.
  Map<Symbol, String> get tagNames;

  /// A map from Dart named parameters (which will be minified) to their corresponding strings.
  /// The strings are used for creating and updating HTML elements, and for JSON serialization.
  Map<Symbol, String> get atts;

  /// A map from Dart named parameters to their corresponding strings.
  /// The strings are used for JSON serialization.
  Map<Symbol, String> get handlerNames;

  /// A map from Dart named parameters to their corresponding strings.
  /// An entry must exist for each named parameter in the DartTags API.
  /// The strings are used for JSON serialization.
  Map<Symbol, String> get propNames;
}

class _HtmlSchema implements HtmlSchema {
  final tagNames = _htmlTagNames;
  final atts = _htmlAtts;
  final handlerNames = _htmlHandlerNames;
  final propNames = _htmlPropNames;
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

final Map<Symbol, String> _htmlAtts = {
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

final Map<Symbol, String> _htmlPropNames = {
  #ref: "ref",
  #inner: "inner",
  #innerHtml: "innerHtml",
  #defaultValue: "defaultValue"
}
  ..addAll(_htmlAtts)
  ..addAll(_htmlHandlerNames);

/// A map from Dart method names to the corresponding EltDef.
/// The EltDef is used to construct the Tag and for JSON serialization.
Map<Symbol, EltDef> _htmlEltDefs = () {
  var defs = <Symbol, EltDef>{};

  for (Symbol key in _htmlTagNames.keys) {
    var val = _htmlTagNames[key];
    defs[key] = new EltDef._raw(val);
  }

  return defs;
}();
