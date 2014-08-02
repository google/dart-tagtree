TagTree
=======

TagTree is an experimental UI framework written in Dart, inspired by React.

Attention conservation notice
-----------------------------

If you're looking for a UI framework to use in a production Dart application,
you can stop reading now.

If you're curious about the design of a React-like framework, how to model it
with Dart's classes and types, or how to do RPC in Dart, you might find this
article and the code it describes of interest.

Concepts
========

The three classes at the heart of TagTree are *Tag,* *Animator,* and *Place.*
You might think of them as an alternative to Model-View-Controller.

Tags
----

A [Tag] [1] is just a class that implements a record:

    class GridView extends Tag {
      final Grid grid;
      final List<String> palette;
      final Function onPaint;
      const GridView({this.grid, this.palette, this.onPaint});
      
      @override
      get animator => null; // TODO: explain
    }

In this example, the GridView tag has three attributes, which are just Dart
fields. The *grid* and *palette* attributes contain data to be used by the
tag, and *onPaint* is an event handler. Unlike an HTML element, these
attributes can be various Dart types, not just strings.

Like an HTML element, a Tag can have children. GridView doesn't have
any children, but if it did, they would go in another field named
*inner*. But that's just a convention; a Tag can have any fields you like.

Unlike an HTML element, a Tag should never change. Neither should its
descendants; the tag trees in TagTree should be deeply immutable, with
the exception of event handlers that can point to functions that
operate on mutable objects.
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
      const MyButtonAnimator();

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

The *input* to an animator is another stream, usually a tag. Or rather,
a stream of tags, which is how TagTree represents a tag that changes.

In the above example, the input (a ButtonDemo tag) has no fields and
doesn't change, so MyButtonAnimator ignores it and generates new animation
frames at its own pace, by setting the *nextState* property on a Place.

This shows the difference between an Animator and a regular HTML template.
A template is passive (stateless); its output doesn't change unless its
input changes. An Animator could act as a template that expands each input
Tag. But it can also get input in other ways and may have internal state.
An Animator's output stream has a variable frame rate that's independent of
its input stream.

The result is sort of like a slide show where some slides contain
animated gifs or videos. The screen changes when you advance to the
next slide, but the slides themselves can move on their own, too.

In a similar way, each custom Tag in TagTree is rendered as a separate
animation. These animations can be nested to any number of levels and they form a
dynamic tree structure, similar to the HTML elements in a web page.

So a TagTree can be thought of as a React-like UI component library,
implementing a virtual DOM. Like in React, the virtual DOM has tags
representing regular HTML elements and custom tags that you write yourself.
But TagTree uses a different metaphor to implement
similar functionality.

Place
-----

Since the nested animations in TagTree can move on their own, we need a
way to keep track of their state. In TagTree, the state of an animation
is always stored in a [Place] [3]. This allows TagTree to freely share
animators between multiple animations running in different places.

If you want to use a more traditional object-oriented style, you can
subclass Place and think of it as a widget object. TagTree isolates each
Place within an Animator, so this is just an implementation detail.
All communication between animations happens using Tag streams and
event callbacks.

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

Getting in Touch
================

Email: brian+tagtree@slesinsky.org

Google Plus: https://plus.google.com/+BrianSlesinsky

Twitter: @skybrian

[1]: https://github.com/google/dart-tagtree/blob/master/lib/src/core/tag.dart
[2]: https://github.com/google/dart-tagtree/blob/master/lib/src/core/animator.dart
[3]: https://github.com/google/dart-tagtree/blob/master/lib/src/core/place.dart
[4]: https://github.com/google/dart-tagtree/tree/master/example/dart-demos
[5]: https://github.com/google/dart-tagtree/tree/master/example/react-demos
[6]: https://github.com/google/dart-tagtree/tree/master/example/pixelpaint

