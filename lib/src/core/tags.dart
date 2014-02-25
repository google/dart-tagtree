part of core;

/// An API for constructing the corresponding view for each HTML Element.
/// (Typically Tags is used instead.)
abstract class TagsApi {
  View Div({clazz, onClick, inner, innerHtml, ref});
  View Span({clazz, onClick, inner, innerHtml, ref});

  View H1({clazz, onClick, inner, innerHtml, ref});
  View H2({clazz, onClick, inner, innerHtml, ref});
  View H3({clazz, onClick, inner, innerHtml, ref});

  View Ul({clazz, onClick, inner, innerHtml, ref});
  View Li({clazz, onClick, inner, innerHtml, ref});

  View Form({clazz, onClick, onSubmit, inner, innerHtml, ref});
  View Input({clazz, onClick, onChange, value, defaultValue, ref});
  View TextArea({clazz, onClick, onChange, value, defaultValue, ref});
  View Button({clazz, onClick, inner, innerHtml, ref});
}

final Map<Symbol, String> _allTags = {
  #Div: "div",
  #Span: "span",

  #H1: "h1",
  #H2: "h2",
  #H3: "h3",

  #Ul: "ul",
  #Li: "li",

  #Form: "form",
  #Input: "input",
  #TextArea: "textarea",
  #Button: "button"
};

final Map<Symbol, String> _allAtts = {
  #clazz: "class",
  #value: "value",
};

final Map<Symbol, String> _eltPropToField = {
  #ref: "ref",
  #inner: "inner",
  #innerHtml: "innerHtml",
  #defaultValue: "defaultValue"
}
  ..addAll(_allAtts);

final Set<Symbol> _allEltProps = new Set()
    ..addAll(_allHandlers.keys)
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
