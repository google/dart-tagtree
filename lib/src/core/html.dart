part of core;

/// A set of tags that may be used to construct a tag tree.
/// Automatically includes HTML tags.
class HtmlTagSet extends TagSet with HtmlTags {
  HtmlTagSet() {
    for (var tag in htmlTags) {
      addTag(tag.type.symbol, tag);
    }
  }

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

/// A TagSet mixin that provides HTML tags.
/// TODO: implement more elements and attributes.
abstract class HtmlTags {

  TagNode Div({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  TagNode Span({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  TagNode Header({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  TagNode Footer({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  TagNode H1({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  TagNode H2({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  TagNode H3({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  TagNode P({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  TagNode Pre({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  TagNode Ul({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  TagNode Li({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  TagNode Table({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  TagNode Tr({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  TagNode Td({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  TagNode Img({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    width, height, src});
  TagNode Canvas({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    width, height});

  TagNode Form({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onSubmit,
    inner, innerHtml});
  TagNode Input({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue, type, min, max});
  TagNode TextArea({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue});
  TagNode Button({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  /// The definitions of all HTML tags.
  /// (Subclasses must install them using [BaseTagMaker#defineTag].)
  List<Tag> get htmlTags => _htmlTags;
}

final List<Tag> _htmlTags = () {

  const leafGlobalProps = const [
    const AttributeType(#id, "id"),
    const AttributeType(#clazz, "class"),
    onClick,
    onMouseDown,
    onMouseOver,
    onMouseUp,
    onMouseOut,
    const PropType(#ref, "ref"),
  ];

  const globalProps = const [
    const AttributeType(#id, "id"),
    const AttributeType(#clazz, "class"),
    onClick,
    onMouseDown,
    onMouseOver,
    onMouseUp,
    onMouseOut,
    const PropType(#ref, "ref"),
    const PropType(#inner, "inner"),
    const PropType(#innerHtml, "innerHtml")
  ];

  const inner = const PropType(#inner, "inner");
  const innerHtml = const PropType(#innerHtml, "innerHtml");

  const src = const AttributeType(#src, "src");
  const width = const AttributeType(#width, "width");
  const height = const AttributeType(#height, "height");

  const type = const AttributeType(#type, "type");
  const value = const AttributeType(#value, "value");
  const defaultValue = const PropType(#defaultValue, "defaultValue");
  const min = const AttributeType(#min, "min");
  const max = const AttributeType(#max, "max");

  const allTypes = const [
    const TagType(#Div, "div", globalProps),
    const TagType(#Span, "span", globalProps),
    const TagType(#Header, "header", globalProps),
    const TagType(#Footer, "footer", globalProps),

    const TagType(#H1, "h1", globalProps),
    const TagType(#H2, "h2", globalProps),
    const TagType(#H3, "h3", globalProps),

    const TagType(#P, "p", globalProps),
    const TagType(#Pre, "pre", globalProps),

    const TagType(#Ul, "ul", globalProps),
    const TagType(#Li, "li", globalProps),

    const TagType(#Table, "table", globalProps),
    const TagType(#Tr, "tr", globalProps),
    const TagType(#Td, "td", globalProps),

    const TagType(#Img, "img", leafGlobalProps, const [width, height, src]),
    const TagType(#Canvas, "canvas", leafGlobalProps, const [width, height]),

    const TagType(#Form, "form", globalProps, const [onSubmit]),
    const TagType(#Input, "input", leafGlobalProps,
        const [onChange, value, defaultValue, type, min, max]),
    const TagType(#TextArea, "textarea", leafGlobalProps, const [onChange, value, defaultValue]),
    const TagType(#Button, "button", globalProps)
  ];

  return allTypes.map((t) => new ElementTag(t)).toList();
}();
