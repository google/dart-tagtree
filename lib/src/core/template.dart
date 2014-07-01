part of core;

/// A Template renders a tag as a "shadow" tag tree.
abstract class Template<T extends Tag> extends Animator<T,dynamic> {
  const Template();

  render(T currentTag);

  @override
  Place start(T firstTag) => new Place(false);

  @override
  Tag renderAt(Place p, T currentTag) => render(currentTag);
}

/// A tag that acts as a template, rendering a single frame.
abstract class TemplateTag extends Tag {
  const TemplateTag();

  get animator => const _TemplateTag();
  shouldRender(Tag prev) => true;

  Tag render();
}

class _TemplateTag extends Template<TemplateTag> {
  const _TemplateTag();

  @override
  bool shouldRender(TemplateTag prev, TemplateTag next) => next.shouldRender(prev);

  @override
  Tag render(input) => input.render();

  toString() => "_TemplateTag";
}
