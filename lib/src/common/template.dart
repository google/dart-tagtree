part of common;

/// A Template is a stateless animator.
/// It generates one animation frame for each input tag.
/// For each possible input, it should return the same output.
abstract class Template<IN extends Tag> extends Animator<IN,dynamic> {
  const Template();

  /// Returns the output tag tree corresponding to the given input.
  Tag render(IN inputTag);

  @override
  Place start(IN firstTag) => new Place(false);

  @override
  Tag renderAt(Place p, IN currentTag) => render(currentTag);
}

/// A TemplateTag is a Tag that by default, always expands to the same output.
abstract class TemplateTag extends Tag {
  const TemplateTag();

  /// Returns the output.
  Tag render();

  /// Returns false to skip rendering this tag for better performance.
  /// (Typically this is when the previous tag is the same.)
  shouldRender(Tag prevInput) => true;

  get animator => const _TemplateTag();
}

class _TemplateTag extends Template<TemplateTag> {
  const _TemplateTag();

  @override
  bool shouldRender(TemplateTag prev, TemplateTag next) => next.shouldRender(prev);

  @override
  Tag render(input) => input.render();

  toString() => "_TemplateTag";
}