part of core;

/// Encapsulates all operations used to update the DOM in a container for the next animation frame.
abstract class NextFrame {

  /// Installs the given html inside the container.
  void mount(String html);

  /// Hook called after mounting a Ref.
  void onRefMounted(Ref ref);

  /// Hook called after mounting a form.
  void onFormMounted(Root root, String path);

  /// Hook called after unmounted a form.
  void onFormUnmounted(String formPath);

  /// Clears any references to the DOM element with the given path.
  /// This should be called after unmounting an element.
  /// If willReplace is set, the DOM node should be kept for a subsequent
  /// replaceElement call.
  void detachElement(String path, {bool willReplace: false});

  /// Sets the element that most other methods act on.
  void visit(String path);

  /// Creates a new Element with the given HTML and replaces the current element.
  void replaceElement(String path, String html);

  void setAttribute(String key, String value);

  void removeAttribute(String key);

  void setInnerHtml(String html);

  void setInnerText(String text);

  /// Creates a new Element with the given HTML and appends it as the last child.
  void addChildElement(String childHtml);

  void removeChild(int index);
}
