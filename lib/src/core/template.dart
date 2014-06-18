part of core;

/// A Template renders a view by substituting another View.
abstract class Template<V extends View> extends Expander {
  const Template();

  @override
  View expand(V props);

  @override
  bool shouldExpand(V before, V after) => true;

  // implement CreateExpander.
  Template call() => this;
}

/// A view that renders itself using a template.
/// (It should be stateless; otherwise, use a regular View and a separate Expander for the state.)
abstract class TemplateView extends View {
  const TemplateView();

  Expander createExpander() => const _TemplateView();

  bool shouldExpand(View prev) => true;

  View render();
}

class _TemplateView extends Template<TemplateView> {
  const _TemplateView();

  @override
  bool shouldExpand(TemplateView prev, TemplateView next) => next.shouldExpand(prev);

  @override
  View expand(props) => props.render();
}
