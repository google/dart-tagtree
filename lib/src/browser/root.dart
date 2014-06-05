part of browser;

final $ = new HtmlTagSet();

int _rootIdCounter = 0;

/// Maps a data-path attribute to the root for that path.
Map<String, _BrowserRoot> _pathToRoot = {};

/// Returns the Root corresponding to the given CSS selectors, creating it if needed.
///
/// The selectors must point to a single container element of type HtmlElement.
render.RenderRoot getRoot(String containerSelectors) {
  HtmlElement container = querySelectorAll(containerSelectors).single;
  var prev = _findRoot(container);
  if (prev != null) {
    return prev;
  }

  var root = new _BrowserRoot(container);
  _pathToRoot[root.path] = root;
  return root;
}

render.RenderRoot _findRoot(HtmlElement container) {
  var first = container.firstChild;
  if (first == null) {
    return null;
  }
  if (first is Element) {
    String path = first.getAttribute("data-path");
    if (path != null) {
      return _pathToRoot[path];
    }
  }
  return null;
}

class _BrowserRoot extends render.RenderRoot {
  final _ElementCache eltCache;
  final Map<String, StreamSubscription> formSubscriptions = {};

  _BrowserRoot(HtmlElement container) :
    this.eltCache = new _ElementCache(container),
    super(_rootIdCounter++) {
    theme.defineElements($);
  }

  @override
  void installEventListeners() {
    _listenForEvents(this, eltCache.container);
  }

  @override
  void requestAnimationFrame(render.RenderFunc render) {
    window.animationFrame.then((t) {
      render(new _DomUpdater(this));
    });
  }

  void _listenForEvents(render.RenderRoot root, HtmlElement container) {

    handle(Event e, HandlerType type) {
      String path = _getTargetPath(e.target);
      if (path == null) {
        return;
      }
      root.dispatchEvent(new HandlerEvent(type, path, null));
    }

    container.onClick.listen((e) => handle(e, onClick));
    container.onMouseDown.listen((e) => handle(e, onMouseDown));
    container.onMouseOver.listen((e) => handle(e, onMouseOver));
    container.onMouseUp.listen((e) => handle(e, onMouseUp));
    container.onMouseOut.listen((e) => handle(e, onMouseOut));

    // Form events are tricky. We want an onChange event to fire every time
    // the value in a text box changes. The native 'input' event does this,
    // not 'change' which only fires after focus is lost.
    // TODO: support IE9 (not tested other than in Chrome).
    // (See ChangeEventPlugin in React for browser-specific workarounds.)
    container.onInput.listen((Event e) {
      String path = _getTargetPath(e.target);
      if (path == null) {
        return;
      }
      String value = _getTargetValue(e.target);
      if (value == null) {
        print("can't get value of target: ${path}");
        return;
      }
      root.dispatchEvent(new HandlerEvent(onChange, path, value));
    });

    // TODO: implement many more events.
    // TODO: remove handlers on unmount.
  }
}
