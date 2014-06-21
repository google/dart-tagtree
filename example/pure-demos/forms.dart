import 'package:tagtree/core.dart';
import 'package:tagtree/browser.dart';

class Page extends TemplateView {
  final Menu menu;
  final List<View> content;
  const Page({this.menu, this.content});

  @override
  render() {
    var items = [];
    if (menu != null) {
      items.add(menu);
    }
    items.add($.Div(clazz: "content", inner: content));
    return $.Div(clazz: "main", inner: items);
  }
}

typedef void OnMenuClick(String item);

class Menu extends View {
  final String title;
  final List<String> items;
  final String defaultSelected;
  final OnMenuClick onClick;

  const Menu({this.title, this.items, this.defaultSelected, this.onClick});

  @override
  bool checked() => items != null && items.length > 0;

  createExpander() => new _Menu();
}

class _Menu extends Widget<Menu, String> {

  @override
  createFirstState() =>
      view.defaultSelected == null ? view.items.first : view.defaultSelected;

  String get selected => state;

  onClick(String item) {
    nextState = item;
    if (view.onClick != null) {
      view.onClick(item);
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
    if (view.title != null) {
      items.add($.A(href: "#", clazz: "pure-menu-heading", inner: view.title));
    }
    items.add($.Ul(inner: view.items.map(renderItem)));

    return $.Div(clazz: "pure-menu pure-menu-open pure-menu-horizontal", inner: items);
  }
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
  expand(LoginView v) =>
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
    return new Theme({
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
          render(themes[key]);
        }
    ),
    content: [
      $.P(inner: "Use the above menu to change the appearance of this (non-working) form."),
      const LoginView()
    ]);

render(theme) => getRoot("#container").mount(frontPage, theme);
main() => render(themes["Default"]);
