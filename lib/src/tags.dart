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

Map<Symbol, String> allTags = {
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

Map<Symbol, String> allAtts = {
  #clazz: "class",
  #value: "value",
};

Set<Symbol> allEltProps = new Set()..addAll(allAtts.keys)..addAll(allHandlers.keys)
  ..addAll([#ref, #inner, #innerHtml, #defaultValue]);

/// A factory for constructing the corresponding view for each HTML Element.
/// (Typically assigned to '$'.)
class Tags implements TagsApi {
  noSuchMethod(Invocation inv) {
    if (inv.isMethod) {
      String tag = allTags[inv.memberName];
      if (tag != null) {
        if (!inv.positionalArguments.isEmpty) {
          throw "position arguments not supported for html tags";
        }
        return new Elt(tag, inv.namedArguments);
      }
    }
    throw new NoSuchMethodError(this,
        inv.memberName, inv.positionalArguments, inv.namedArguments);
  }
}