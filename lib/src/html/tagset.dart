part of html;

/// A TagSet that includes HTML tags and events.
class HtmlTagSet extends TagSet with HtmlTags {
  HtmlTagSet() {
    for (ElementTag tag in htmlTags) {
      var maker = (Map<String, dynamic> props) {
        return new ElementNode(tag, props);
      };
      var handlerTypes = tag.type.props.where((t) => t is HandlerType);
      addTag(tag.type.name, maker, handlerTypes: handlerTypes);

      var namedProps = <Symbol, String>{};
      for (var propType in tag.type.props) {
        namedProps[propType.sym] = propType.name;
      }
      addMethod(tag.type.symbol, tag.type.name, namedProps);
    }
  }

  // Suppress warnings
  noSuchMethod(Invocation inv) => super.noSuchMethod(inv);
}

/// A TagSet mixin that provides HTML tags.
/// TODO: implement more elements and attributes.
abstract class HtmlTags {

  ElementNode Div({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  ElementNode Span({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  ElementNode Header({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  ElementNode Footer({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  ElementNode H1({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  ElementNode H2({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  ElementNode H3({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  ElementNode P({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  ElementNode Pre({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  ElementNode Ul({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  ElementNode Li({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  ElementNode Table({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  ElementNode Tr({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  ElementNode Td({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  ElementNode Img({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    width, height, src});
  ElementNode Canvas({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    width, height});

  ElementNode Form({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onSubmit,
    inner, innerHtml});
  ElementNode Input({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue, type, min, max});
  ElementNode TextArea({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue});
  ElementNode Button({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  /// The definitions of all HTML tags.
  /// (Subclasses must install them using [BaseTagMaker#defineTag].)
  List<ElementTag> get htmlTags => _htmlTags;
}

final List<ElementTag> _htmlTags = () {

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

  const inner = const MixedContentType(#inner, "inner");
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
