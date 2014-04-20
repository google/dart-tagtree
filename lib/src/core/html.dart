part of core;

/// The API for creating HTML element nodes in a tag tree.
/// (Callers may want to assign this to '$' for brevity.)
const HtmlTags htmlTags = const _HtmlTagsImpl();

/// The API for constructing the corresponding Tag for each HTML elemnt.
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
}

/// A map from Dart method names (which will be minified) to their corresponding strings.
/// The symbols must correspond to methods in HtmlTags.
/// The strings are used for creating HTML elements and for JSON serialization.
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

/// A map from Dart named parameters (which will be minified) to their corresponding strings.
/// The strings are used for creating and updating HTML elements, and for JSON serialization.
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

/// A map from Dart named parameters to their corresponding strings.
/// The strings are used for JSON serialization.
final Map<Symbol, String> _htmlHandlerNames = {
  #onChange: "onChange",
  #onClick: "onClick",
  #onMouseDown: "onMouseDown",
  #onMouseOver: "onMouseOver",
  #onMouseUp: "onMouseUp",
  #onMouseOut: "onMouseOut",
  #onSubmit: "onSubmit"
};

/// A map from Dart named parameters to their corresponding strings.
/// An entry must exist for each named parameter in the DartTags API.
/// The strings are used for JSON serialization.
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
    defs[key] = new EltDef(val);
  }

  return defs;
}();

/// Implements the HtmlTags API by forwarding calls to the appropriate EltDef.
class _HtmlTagsImpl implements HtmlTags {

  const _HtmlTagsImpl();

  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      EltDef def = _htmlEltDefs[inv.memberName];
      if (def != null) {
        if (!inv.positionalArguments.isEmpty) {
          throw "positional arguments not supported for html tags";
        }
        return def.makeTag(inv.namedArguments);
      }
    }
    return super.noSuchMethod(inv);
  }
}
