part of core;

/// An API for constructing the corresponding view for each HTML Element.
/// (Typically Tags is used instead.)
abstract class TagsApi {
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

final Map<Symbol, String> _allTags = {
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

final Map<Symbol, String> _allAtts = {
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

final Map<Symbol, String> _allEltProps = {
  #ref: "ref",
  #inner: "inner",
  #innerHtml: "innerHtml",
  #defaultValue: "defaultValue"
}
  ..addAll(_allAtts)
  ..addAll(_allHandlerNames);

Map<Symbol, EltDef> _eltTags = () {
  var tags = <Symbol, EltDef>{};

  for (Symbol key in _allTags.keys) {
    tags[key] = new EltDef(_allTags[key]);
  }

  return tags;
}();

/// A factory for constructing the corresponding view for each HTML Element.
/// (Typically assigned to '$'.)
class Tags implements TagsApi {

  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      EltDef def = _eltTags[inv.memberName];
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
