part of core;

class ViewEvent {
  final Symbol handlerKey;
  final String path;
  ViewEvent(this.handlerKey, this.path);
}

class ChangeEvent extends ViewEvent {
  final value;
  ChangeEvent(String path, this.value) : super(#onChange, path);
}

typedef EventHandler(ViewEvent e);

Map<Symbol, Map<String, EventHandler>> allHandlers = {
  #onChange: {},
  #onClick: {},
  #onSubmit: {}
};
