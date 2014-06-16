part of html;

/// A TagSet that includes HTML tags and events.
class HtmlTagSet extends TagSet with HtmlTags {
  HtmlTagSet() {
    for (ElementType type in _htmlTags) {
      defineElement(type);
    }
  }

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

/// A TagSet mixin that provides HTML tags.
/// TODO: implement more elements and attributes.
abstract class HtmlTags {

  View Div({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});
  View Span({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});

  View Header({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});
  View Footer({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});

  View H1({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});
  View H2({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});
  View H3({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});

  View P({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});
  View Pre({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});

  View Ul({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});
  View Li({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});

  View Table({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});
  View Tr({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});
  View Td({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner});

  View A({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, inner,
    href});
  View Img({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    width, height, src});
  View Canvas({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    width, height});

  View Form({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onSubmit,
    inner});
  View FieldSet({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner});
  View Legend({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner});
  View Label({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, forr,
    inner});
  View Input({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue, placeholder, type, min, max});
  View TextArea({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue});
  View Button({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, type,
    inner});
}

final List<ElementType> _htmlTags = () {

  const leafGlobalProps = const [
    const AttributeType(#id, "id"),
    const AttributeType(#clazz, "class"),
    const PropType(#ref, "ref"),
    onClick,
    onMouseDown,
    onMouseOver,
    onMouseUp,
    onMouseOut,
  ];

  const globalProps = const [
    const AttributeType(#id, "id"),
    const AttributeType(#clazz, "class"),
    const PropType(#ref, "ref"),
    onClick,
    onMouseDown,
    onMouseOver,
    onMouseUp,
    onMouseOut,
    innerType,
  ];

  const href = const AttributeType(#href, "href");
  const src = const AttributeType(#src, "src");
  const width = const AttributeType(#width, "width");
  const height = const AttributeType(#height, "height");
  const type = const AttributeType(#type, "type");
  const value = const AttributeType(#value, "value");
  const defaultValue = const PropType(#defaultValue, "defaultValue");
  const placeholder = const AttributeType(#placeholder, "placeholder");
  const forr = const AttributeType(#forr, "for");
  const min = const AttributeType(#min, "min");
  const max = const AttributeType(#max, "max");

  const allTypes = const [
    const ElementType(#Div, "div", globalProps),
    const ElementType(#Span, "span", globalProps),
    const ElementType(#Header, "header", globalProps),
    const ElementType(#Footer, "footer", globalProps),

    const ElementType(#H1, "h1", globalProps),
    const ElementType(#H2, "h2", globalProps),
    const ElementType(#H3, "h3", globalProps),

    const ElementType(#P, "p", globalProps),
    const ElementType(#Pre, "pre", globalProps),

    const ElementType(#Ul, "ul", globalProps),
    const ElementType(#Li, "li", globalProps),

    const ElementType(#Table, "table", globalProps),
    const ElementType(#Tr, "tr", globalProps),
    const ElementType(#Td, "td", globalProps),

    const ElementType(#A, "a", globalProps, const [href]),
    const ElementType(#Img, "img", leafGlobalProps, const [width, height, src]),
    const ElementType(#Canvas, "canvas", leafGlobalProps, const [width, height]),

    const ElementType(#Form, "form", globalProps, const [onSubmit]),
    const ElementType(#FieldSet, "fieldset", globalProps),
    const ElementType(#Legend, "legend", globalProps),
    const ElementType(#Label, "label", globalProps, const [forr]),
    const ElementType(#Input, "input", leafGlobalProps,
        const [onChange, value, defaultValue, placeholder, type, min, max]),
    const ElementType(#TextArea, "textarea", leafGlobalProps, const [onChange, value, defaultValue]),
    const ElementType(#Button, "button", globalProps, const [type])
  ];

  return allTypes;
}();
