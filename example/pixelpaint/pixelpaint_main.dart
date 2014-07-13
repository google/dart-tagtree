import 'package:tagtree/browser.dart';
import 'pixelpaint.dart';

main() =>
    getRoot("#container")
      .mount(const PixelPaintApp());
