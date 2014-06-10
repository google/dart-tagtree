import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class Page extends View {
  final Menu menu;
  final List<View> content;
  const Page({
    this.menu: null,
    this.content: const []});
}

class _Page extends Template {
  const _Page();
  @override
  render(Page p) {
    var items = [];
    if (p.menu != null) {
      items.add(p.menu);
    }
    items.add($.Div(clazz: "content", inner: p.content));
    return $.Div(clazz: "main", inner: items);
  }
}

typedef void MenuClickFunc(String item);

class Menu extends View {
  final String title;
  final List<String> items;
  final String defaultSelected;
  final MenuClickFunc onClick;
  const Menu({this.title, this.items, this.defaultSelected, this.onClick});
  bool checked() => items != null && items.length > 0;
}

class _Menu extends Widget<Menu, String> {

  @override
  createFirstState() =>
      props.defaultSelected == null ? props.items.first : props.defaultSelected;

  String get selected => state;

  onClick(String item) {
    nextState = item;
    if (props.onClick != null) {
      props.onClick(item);
    }
  }

  @override
  View render()  {
    renderItem(String item) {
      return $.Li(clazz: item==selected ? "pure-menu-selected" : "", inner:
        $.A(href: "#", onClick: (_) => onClick(item), inner: item)
      );
    };

    var items = [];
    if (props.title != null) {
      items.add($.A(href: "#", clazz: "pure-menu-heading", inner: props.title));
    }
    items.add($.Ul(inner: props.items.map(renderItem)));

    return $.Div(clazz: "pure-menu pure-menu-open pure-menu-horizontal", inner: items);
  }

  static create() => new _Menu();
}

class LoginView extends View {
  final String email;
  final bool rememberMe;
  const LoginView({this.email: "", this.rememberMe: false});
}

class _LoginView extends Template {
  final String formClasses;
  const _LoginView(this.formClasses);

  @override
  render(LoginView v) =>
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

Theme makeTheme(String name, String loginClasses) {
    var _loginView = new _LoginView(loginClasses);
    return $.elements.extend({
        Page: const _Page(),
        Menu: _Menu.create,
        LoginView: _loginView
    });
}

final themes = {
  "Default": makeTheme("Default", "pure-form"),
  "Stacked": makeTheme("Stacked", "pure-form pure-form-stacked")
};

final frontPage = new Page(
    menu: new Menu(
        items: themes.keys.toList(),
        onClick: (String key) {
          print("clicked: ${key}");
          render(themes[key]);
        }
    ),
    content: [
      $.P(inner: "Use the above menu to change the appearance of this (non-working) form."),
      const LoginView()
    ]);

render(theme) => getRoot("#container").mount(frontPage, theme);
main() => render(themes["Default"]);
