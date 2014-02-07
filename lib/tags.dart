part of viewlet;

/// An API for constructing the corresponding view for each HTML Element.
/// (Typically Tags is used instead.)
abstract class TagsApi {
  View Div({clazz, onClick, inner});
  View Span({clazz, onClick, inner});

  View H1({clazz, onClick, inner});
  View H2({clazz, onClick, inner});
  View H3({clazz, onClick, inner});

  View Ul({clazz, onClick, inner});
  View Li({clazz, onClick, inner});

  View Form({clazz, onClick, onSubmit, inner});
  View Input({clazz, onClick, onChange, value, inner});
  View Button({clazz, onClick, inner});
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
  #Button: "button"
};

Map<Symbol, String> allAtts = {
  #clazz: "class",
  #value: "value"
};

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