part of render;

/// A callback for rendering an animation frame.
/// (The supplied DomUpdater is only valid until the end of the function call
/// and shouldn't be cached.)
typedef void RenderFunc(DomUpdater dom);

/// An abstract API for updating the DOM.
/// This API allows the core to avoid any direct dependency on dart:html.
/// (See the implementation in src/browser/dom.dart.)
abstract class DomUpdater {

  /// Sets the inner HTML of the container element.
  void mount(String html);

  /// Attaches the given ref to the DOM.
  void mountRef(String path, ref);

  /// Starts listening to form events.
  void mountForm(String path);

  /// Removes any event handlers or refs to the DOM element with the given path,
  /// in preparation for unmounting the Tag.
  /// If willReplace is set, the element cache's reference to the DOM node should
  /// be kept for a subsequent replaceElement call. Otherwise, it can be cleared.
  void detachElement(String path, ref, {bool willReplace: false});

  /// Creates a new Element with the given HTML and replaces the current element.
  void replaceElement(String path, String html);

  void setAttribute(String path, String key, String value);

  void removeAttribute(String path, String key);

  void setInnerHtml(String path, String html);

  void setInnerText(String path, String text);

  /// Creates a new element with the given HTML and appends it as the last child.
  void addChildElement(String path, String childHtml);

  void removeChild(String path, int index);
}
