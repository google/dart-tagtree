import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class ThemeDemo extends AnimatedTag<String> {
  final Map<String, Theme> themes;
  final List<Tag> content;
  const ThemeDemo({this.themes, this.content});

  @override
  start() => new Place(themes.keys.first);

  @override
  renderAt(Place<String> p) {
    var selected = p.state;

    onClick(String item) {
      p.nextState = item;
    }

    TopMenu menu = new TopMenu(items: themes.keys.toList(), selected: selected, onClick: onClick);
    Theme theme = themes[selected];

    return $.Div(clazz: "main", inner: [
      menu,
      new ThemeTag(theme, $.Div(clazz: "content", inner: content))
    ]);
  }
}

typedef void OnMenuClick(String item);

class TopMenu extends TemplateTag {
  final String title;
  final List<String> items;
  final String selected;
  final OnMenuClick onClick;

  const TopMenu({this.title, this.items, this.selected, this.onClick});

  @override
  bool checked() => items != null && items.length > 0;

  @override
  Tag render()  {
    itemClick(String item) {
      if (onClick != null) {
        onClick(item);
      }
    }

    renderItem(String item) {
      return $.Li(clazz: item==selected ? "pure-menu-selected" : "", inner:
        $.A(href: "#", onClick: (_) => itemClick(item), inner: item)
      );
    };

    var itemList = [];
    if (title != null) {
      itemList.add($.A(href: "#", clazz: "pure-menu-heading", inner: title));
    }
    itemList.add($.Ul(inner: items.map(renderItem)));

    return $.Div(clazz: "pure-menu pure-menu-open pure-menu-horizontal", inner: itemList);
  }
}

class LoginForm extends Tag {
  final String email;
  final bool rememberMe;

  const LoginForm({this.email: "", this.rememberMe: false});

  @override
  get animator => null; // provided by theme
}

class _LoginForm extends Template {
  final String formClasses;
  const _LoginForm(this.formClasses);

  @override
  render(LoginForm v) =>
    $.Form(clazz: formClasses, inner:
      $.FieldSet(inner: [
        $.Input(type: "email", placeholder: "Email", defaultValue: v.email), " ",
        $.Input(type: "password", placeholder: "Password"), " ",

        $.Label(forr: "remember", inner: [
          $.Input(id: "remember", type: "checkbox",
              defaultValue: v.rememberMe ? "checked" : ""),
          " Remember me ",
        ]), " ",
        $.Button(type: "submit", clazz: "pure-button pure-button-primary", inner: "Sign in")
      ])
    );
}

final themeDemo = new ThemeDemo(
    themes: {
      "Default": new Theme(const {LoginForm: const _LoginForm("pure-form")}),
      "Stacked": new Theme(const {LoginForm: const _LoginForm("pure-form pure-form-stacked")})
    },
    content: [
      $.P(inner: "Use the above menu to change the appearance of this (non-working) form."),
      const LoginForm()
    ]);

main() => getRoot("#container").mount(themeDemo);
