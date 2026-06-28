import 'dart:ui';

/// An ECS component for rendering text to the screen.
///
/// Since it stores [String] and [Paragraph] objects, it cannot be perfectly
/// flat like [Float32List]-backed components. However, to adhere to the zero
/// allocations per frame constraint, it caches the [Paragraph] and [Offset].
/// These are only rebuilt when text or coordinates change (indicated by [isDirty]).
class TextRender {
  String _text;
  double _x;
  double _y;
  int _color;
  double _fontSize;

  bool _isDirty = true;
  Paragraph? _cachedParagraph;
  Offset _cachedOffset;

  /// Creates a new [TextRender] component.
  TextRender({
    String text = '',
    double x = 0,
    double y = 0,
    int color = 0xFFFFFFFF,
    double fontSize = 14.0,
  })  : _text = text,
        _x = x,
        _y = y,
        _color = color,
        _fontSize = fontSize,
        _cachedOffset = Offset(x, y);

  /// The text string to render.
  String get text => _text;
  set text(String value) {
    if (_text != value) {
      _text = value;
      _isDirty = true;
    }
  }

  /// The x-coordinate on the screen.
  double get x => _x;
  set x(double value) {
    if (_x != value) {
      _x = value;
      _cachedOffset = Offset(_x, _y);
    }
  }

  /// The y-coordinate on the screen.
  double get y => _y;
  set y(double value) {
    if (_y != value) {
      _y = value;
      _cachedOffset = Offset(_x, _y);
    }
  }

  /// The color of the text as a 32-bit ARGB integer.
  int get color => _color;
  set color(int value) {
    if (_color != value) {
      _color = value;
      _isDirty = true;
    }
  }

  /// The font size of the text.
  double get fontSize => _fontSize;
  set fontSize(double value) {
    if (_fontSize != value) {
      _fontSize = value;
      _isDirty = true;
    }
  }

  /// Whether the paragraph needs to be rebuilt.
  bool get isDirty => _isDirty;

  /// Clears the dirty flag. Should be called by the rendering system after rebuilding.
  void clearDirty() {
    _isDirty = false;
  }

  /// Gets the cached paragraph.
  Paragraph? get cachedParagraph => _cachedParagraph;

  /// Sets the cached paragraph.
  set cachedParagraph(Paragraph? value) {
    _cachedParagraph = value;
  }

  /// Gets the cached offset.
  Offset get cachedOffset => _cachedOffset;
}
