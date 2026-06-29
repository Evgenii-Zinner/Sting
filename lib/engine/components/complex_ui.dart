import 'dart:ui';

/// An ECS component for rendering complex UI elements (buttons, panels) to the screen.
///
/// Stores [String], [Paragraph], [Path], and [Paint] objects. It cannot be
/// perfectly flat like [Float32List]-backed components. However, to adhere to the zero
/// allocations per frame constraint, it caches the [Paragraph], [Path], [Paint] and [Offset].
/// These are only rebuilt when state changes (indicated by [isDirty]).
class ComplexUI {
  double _x;
  double _y;
  double _width;
  double _height;
  int _backgroundColor;
  String _text;
  int _textColor;
  double _fontSize;
  double _borderRadius;

  bool _isDirty = true;
  Paragraph? _cachedParagraph;
  Path? _cachedPath;
  Paint? _cachedPaint;
  Offset _cachedOffset;

  /// Creates a new [ComplexUI] component.
  ComplexUI({
    double x = 0,
    double y = 0,
    double width = 100,
    double height = 50,
    int backgroundColor = 0xFF888888,
    String text = '',
    int textColor = 0xFFFFFFFF,
    double fontSize = 14.0,
    double borderRadius = 0.0,
  })  : _x = x,
        _y = y,
        _width = width,
        _height = height,
        _backgroundColor = backgroundColor,
        _text = text,
        _textColor = textColor,
        _fontSize = fontSize,
        _borderRadius = borderRadius,
        _cachedOffset = Offset(x, y);

  /// The x-coordinate on the screen.
  double get x => _x;
  set x(double value) {
    if (_x != value) {
      _x = value;
      _cachedOffset = Offset(_x, _y);
      _isDirty = true;
    }
  }

  /// The y-coordinate on the screen.
  double get y => _y;
  set y(double value) {
    if (_y != value) {
      _y = value;
      _cachedOffset = Offset(_x, _y);
      _isDirty = true;
    }
  }

  /// Sets the cached text offset specifically for text rendering (centered).
  void updateCachedOffset(double x, double y) {
    if (_cachedOffset.dx != x || _cachedOffset.dy != y) {
      _cachedOffset = Offset(x, y);
    }
  }

  /// The width of the UI element.
  double get width => _width;
  set width(double value) {
    if (_width != value) {
      _width = value;
      _isDirty = true;
    }
  }

  /// The height of the UI element.
  double get height => _height;
  set height(double value) {
    if (_height != value) {
      _height = value;
      _isDirty = true;
    }
  }

  /// The background color as a 32-bit ARGB integer.
  int get backgroundColor => _backgroundColor;
  set backgroundColor(int value) {
    if (_backgroundColor != value) {
      _backgroundColor = value;
      _isDirty = true;
    }
  }

  /// The text string to render.
  String get text => _text;
  set text(String value) {
    if (_text != value) {
      _text = value;
      _isDirty = true;
    }
  }

  /// The color of the text as a 32-bit ARGB integer.
  int get textColor => _textColor;
  set textColor(int value) {
    if (_textColor != value) {
      _textColor = value;
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

  /// The border radius for rounded corners.
  double get borderRadius => _borderRadius;
  set borderRadius(double value) {
    if (_borderRadius != value) {
      _borderRadius = value;
      _isDirty = true;
    }
  }

  /// Whether the cached objects need to be rebuilt.
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

  /// Gets the cached path.
  Path? get cachedPath => _cachedPath;

  /// Sets the cached path.
  set cachedPath(Path? value) {
    _cachedPath = value;
  }

  /// Gets the cached paint.
  Paint? get cachedPaint => _cachedPaint;

  /// Sets the cached paint.
  set cachedPaint(Paint? value) {
    _cachedPaint = value;
  }

  /// Gets the cached offset.
  Offset get cachedOffset => _cachedOffset;
}
