TagTree
=======

TagTree is an experimental UI framework written in Dart, inspired by React.

Concepts
========

Tags
----

A [Tag] [1] is just a record:

    class GridView extends Tag {
      final Grid grid;
      final List<String> palette;
      final Function onPaint;
      const GridView({this.grid, this.palette, this.onPaint});
      
      @override
      get animator => null; // TODO: explain
    }

Like an HTML element, a Tag can have children. This is just another field.
I suggest you name it *inner*, but that's not required. You can give it
any fields you like.

Unlike an HTML element, a Tag should never change. Neither should its
descendants; the tag trees in TagTree should be deeply immutable.
(Dart doesn't enforce this, but you can give your Tags a const constructor
as a hint.)

Animators
---------

To give a Tag some behavior, you need to write an [Animator] [2].

    class ButtonDemo extends Tag {
      const ButtonDemo();
      @override
      get animator => const MyButtonAnimator();
    }

    class MyButtonAnimator extends Animator<ButtonDemo, int> {
      const ButtonAnimator();

      @override
      Place start(_) => new Place(0);

      @override
      Tag renderAt(Place<int> p, _) {

        onClick(_) {
          print("button clicked");
          p.nextState = p.nextState + 1;
        }

        return $.Div(inner: [
          $.H1(inner: "Button Demo"),
          $.Div(inner: "Clicks: ${p.state}"),
          $.Button(onClick: onClick, inner: "Click here"),
        ]);
      }
    }

As you'd expect, an animator generates an animation. An animation is just a
stream of Tags, or rather a stream of tag trees, since a Tag can have
descendants. You can think of each of these trees as one frame of the
animation. Tag Tree calls the *renderAt* method to generate each frame.

In the above example, the input (a ButtonDemo tag) doesn't change.
The Animator ignores it and generates frames at its own pace, by setting
the *nextState* property on a Place.

This shows the difference between an Animator and a regular HTML template.
A template is passive (stateless); its output doesn't change unless its
input changes. An Animator can act as a template, but it can also get input
from other places and may have internal state. An Animator's output stream
has a variable frame rate that's independent of its input stream.

The result is sort of like a slide show where some slides contain
animated gifs or videos. Advancing to the next slide will cause movement,
but the slides themselves can move on their own, too.

In a similar way, each custom Tag in TagTree has its own animation.
These animations can be nested to any number of levels and they form a
dynamic tree structure, similar to the HTML elements in a web page.

So a TagTree can be thought of as a React-like UI component library,
implementing a virtual DOM. Like in React, the virtual DOM has tags
representing regular HTML elements and custom tags that you write yourself.
But TagTree uses a different (and I think cooler) metaphor to implement
similar functionality.

Place
-----

Since the nested animations in TagTree can move on their own, we need a
way to keep track of their state. In TagTree, the state of an animation
is always stored in a [Place] [3]. This allows us to make an Animator a
const value that can be freely shared between multiple animations running
in different places.

If you want to use a more traditional object-oriented style, you can
subclass Place and think of it as a view object. TagTree isolates each
Place within an Animator, so this is just an implementation detail.
All communication between animations happens using Tag streams and
event callbacks.

This Tag-Animator-Place trio is the design pattern at the heart of a
TagTree-based user interface. Whether you use TagTree or not, I hope you
find it a useful alternative to Model-View-Controller.

Optional Features
=================

Actually, there's a third way that an animation can move: its Theme can
change. A Theme provides Animators for a bunch of Tags at once and
switching Themes will often restart any animations in progress.
(A Theme can be thought of as a way to do dependency injection.)

TagTree provides a simple JSON-based codec and basic support for RPC, so
that tag trees and their callback events can be sent over the network.
This allows a user interface to be split between client and server, using
a WebSocket. (This makes an interesting demo, but it will need more work
to be secure and reliable enough to use on something other than localhost.)

TemplateTag and AnimatedTag are convenience classes that combine a Tag and
its Animator. They're a useful shortcut when you don't care about Themes or
RPC, as is the case in most of the examples.

Examples
========

For comparison, I translated a couple of [Dart examples] [4] to TagTree,
along with all the [examples from React's front page] [5]. [PixelPaint] [6]
is a slightly larger example that can run either entirely in the browser
or client-server.

I don't have an online demo page set up yet, so for now you will need to
check out the repository and launch the demos from inside the Dart Editor.

[1]: https://github.com/google/dart-tagtree/blob/master/lib/src/core/tag.dart
[2]: https://github.com/google/dart-tagtree/blob/master/lib/src/core/animator.dart
[3]: https://github.com/google/dart-tagtree/blob/master/lib/src/core/place.dart
[4]: https://github.com/google/dart-tagtree/tree/master/example/dart-demos
[5]: https://github.com/google/dart-tagtree/tree/master/example/react-demos
[6]: https://github.com/google/dart-tagtree/tree/master/example/pixelpaint

