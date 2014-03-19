part of core;

/// An API for constructing the corresponding view for each HTML Element.
/// (Typically Tags is used instead.)
abstract class TagsApi {
  View Div({id, clazz, onClick, inner, innerHtml, ref});
  View Span({id, clazz, onClick, inner, innerHtml, ref});

  View Header({id, clazz, onClick, inner, innerHtml, ref});
  View Footer({id, clazz, onClick, inner, innerHtml, ref});

  View H1({id, clazz, onClick, inner, innerHtml, ref});
  View H2({id, clazz, onClick, inner, innerHtml, ref});
  View H3({id, clazz, onClick, inner, innerHtml, ref});

  View P({id, clazz, onClick, inner, innerHtml, ref});
  View Pre({id, clazz, onClick, inner, innerHtml, ref});

  View Ul({id, clazz, onClick, inner, innerHtml, ref});
  View Li({id, clazz, onClick, inner, innerHtml, ref});

  View Img({id, clazz, onClick, inner, innerHtml, ref, width, height, src});
  View Canvas({id, clazz, onClick, inner, innerHtml, ref, width, height});

  View Form({id, clazz, onClick, onSubmit, inner, innerHtml, ref});
  View Input({id, clazz, onClick, onChange, value, defaultValue, ref, type, min, max});
  View TextArea({id, clazz, onClick, onChange, value, defaultValue, ref});
  View Button({id, clazz, onClick, inner, innerHtml, ref});
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

final Map<Symbol, String> _eltPropToField = {
  #ref: "ref",
  #inner: "inner",
  #innerHtml: "innerHtml",
  #defaultValue: "defaultValue"
}
  ..addAll(_allAtts);

final Set<Symbol> _allEltProps = new Set()
    ..addAll(allHandlerKeys)
    ..addAll(_eltPropToField.keys);

/// A factory for constructing the corresponding view for each HTML Element.
/// (Typically assigned to '$'.)
class Tags implements TagsApi {
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      String tag = _allTags[inv.memberName];
      if (tag != null) {
        if (!inv.positionalArguments.isEmpty) {
          throw "position arguments not supported for html tags";
        }
        return new Elt(tag, inv.namedArguments);
      }
    }
    return super.noSuchMethod(inv);
  }
}
