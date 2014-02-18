part of core;

/// Encapsulates all operations used to update the DOM in a container for the next animation frame.
abstract class NextFrame {

  /// Installs the given HTML into the container element.
  void mount(String html);

  /// Performs any DOM fixups needed for a mounted element.
  /// This should be called after mount() for each mounted element.
  void attachElement(ViewTree tree, String path, String tag);

  /// Clears any references to the DOM element with the given path.
  /// This should be called after unmounting an element.
  void detachElement(String path);

  /// Sets the element that most other methods act on.
  set currentElement(String path);

  /// Creates a new Element with the given HTML and replaces the current element.
  void replaceElement(String html);

  void setAttribute(String key, String value);

  void removeAttribute(String key);

  void setInnerHtml(String html);

  void setInnerText(String text);

  /// Creates a new Element with the given HTML and appends it as the last child.
  void addChildElement(String childHtml);

  void removeChild(int index);

  void replaceChildElement(int index, String newHtml);
}
