part of core;

/// A TagMaker mixin that provides HTML tags.
/// TODO: implement more elements and attributes.
abstract class HtmlTags {

  Tag Div({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  Tag Span({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  Tag Header({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  Tag Footer({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  Tag H1({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  Tag H2({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  Tag H3({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  Tag P({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  Tag Pre({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  Tag Ul({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  Tag Li({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  Tag Table({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  Tag Tr({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});
  Tag Td({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  Tag Img({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    width, height, src});
  Tag Canvas({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    width, height});

  Tag Form({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onSubmit,
    inner, innerHtml});
  Tag Input({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue, type, min, max});
  Tag TextArea({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut, onChange,
    value, defaultValue});
  Tag Button({id, clazz, ref,
    onClick, onMouseDown, onMouseOver, onMouseUp, onMouseOut,
    inner, innerHtml});

  /// The definitions of all HTML tags.
  /// (Subclasses must install them using [BaseTagMaker#defineTags].)
  List<TagDef> get htmlDefs => _htmlDefs;

  static List<TagDef> _htmlDefs = () {

    var tags = <TagDef>[];

    for (TagInterface tag in htmlProtocol.tags) {
      tags.add(new EltDef(tag.sym, tag.name, tag.props));
    }

    return tags;
  }();
}

final TagProtocol htmlProtocol = () {

  var att = (Symbol sym, String name) => new PropDef(sym, name, PropType.ATTRIBUTE);
  var handler = (Symbol sym, String name) => new PropDef(sym, name, PropType.HANDLER);
  var special = (Symbol sym, String name) => new PropDef(sym, name);

  var globalProps = [
    att(#id, "id"),
    att(#clazz, "class"),
    handler(#onClick, "onClick"),
    handler(#onMouseDown, "onMouseDown"),
    handler(#onMouseOver, "onMouseOver"),
    handler(#onMouseUp, "onMouseUp"),
    handler(#onMouseOut, "onMouseOut"),
    special(#ref, "ref"),
  ];

  var inner = special(#inner, "inner");
  var innerHtml = special(#innerHtml, "innerHtml");

  var src = att(#src, "src");
  var width = att(#width, "width");
  var height = att(#height, "height");

  var type = att(#type, "type");
  var value = att(#value, "value");
  var defaultValue = special(#defaultValue, "defaultValue");
  var min = att(#min, "min");
  var max = att(#max, "max");
  var onChange = handler(#onChange, "onChange");
  var onSubmit = handler(#onSubmit, "onSubmit");

  var leafTag = (Symbol sym, String name, [List<PropDef> moreProps = const []]) =>
      new TagInterface(sym, name,
          []..addAll(globalProps)..addAll(moreProps));

  var tag = (Symbol sym, String name, [List<PropDef> moreProps = const []]) =>
      new TagInterface(sym, name,
          []..addAll(globalProps)..add(inner)..add(innerHtml)..addAll(moreProps));

  return new TagProtocol([
    tag(#Div, "div"),
    tag(#Span, "span"),
    tag(#Header, "header"),
    tag(#Footer, "footer"),

    tag(#H1, "h1"),
    tag(#H2, "h2"),
    tag(#H3, "h3"),

    tag(#P, "p"),
    tag(#Pre, "pre"),

    tag(#Ul, "ul"),
    tag(#Li, "li"),

    tag(#Table, "table"),
    tag(#Tr, "tr"),
    tag(#Td, "td"),

    leafTag(#Img, "img", [width, height, src]),
    leafTag(#Canvas, "canvas", [width, height]),

    tag(#Form, "form", [onSubmit]),
    leafTag(#Input, "input", [onChange, value, defaultValue, type, min, max]),
    leafTag(#TextArea, "textarea", [onChange, value, defaultValue]),
    tag(#Button, "button")
  ]);
}();

final Map<Symbol, String> _htmlHandlerNames = {
  #onChange: "onChange",
  #onClick: "onClick",
  #onMouseDown: "onMouseDown",
  #onMouseOver: "onMouseOver",
  #onMouseUp: "onMouseUp",
  #onMouseOut: "onMouseOut",
  #onSubmit: "onSubmit"
};

