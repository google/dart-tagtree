part of core;

/// A Template renders a view by substituting another View.
abstract class Template<V extends View> extends Animation<V,dynamic> {
  const Template();

  render(V view);

  @override
  getFirstState(_) => null; // stateless

  @override
  View expand(V view, prev, refresh) => render(view);

  @override
  bool canPlay(View nextView, Animation nextAnim) => nextAnim == this;

  @override
  bool shouldExpand(V before, V after) => true;

  // implement [CreateExpander].
  Template call() => this;
}

/// A view that renders itself using a template.
/// (It should be stateless; otherwise, use a regular View and a separate Expander for the state.)
abstract class TemplateView extends View {
  const TemplateView();

  Animation get animation => const _TemplateView();

  bool shouldRender(View prev) => true;

  View render();
}

class _TemplateView extends Template<TemplateView> {
  const _TemplateView();

  @override
  bool shouldExpand(TemplateView prev, TemplateView next) => next.shouldRender(prev);

  @override
  View render(input) => input.render();

  toString() => "_TemplateView";
}
