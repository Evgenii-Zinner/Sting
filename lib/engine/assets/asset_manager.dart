import 'dart:typed_data';
import 'dart:ui';
import 'asset_loader.dart';

/// Central repository and cache for engine assets.
/// Provides zero-allocation synchronous getters for cached assets.
class AssetManager {
  final Map<String, Image> _images = {};
  final Map<String, FragmentProgram> _shaders = {};
  final Map<String, Uint8List> _bytes = {};
  final Map<String, String> _texts = {};
  final Map<String, dynamic> _generics = {};

  // --- Synchronous Getters ---

  /// Retrieves a cached Image. Returns null if not found.
  Image? getImage(String key) => _images[key];

  /// Retrieves a cached FragmentProgram. Returns null if not found.
  FragmentProgram? getShader(String key) => _shaders[key];

  /// Retrieves cached bytes. Returns null if not found.
  Uint8List? getBytes(String key) => _bytes[key];

  /// Retrieves a cached text string. Returns null if not found.
  String? getText(String key) => _texts[key];

  /// Retrieves a generic cached asset. Returns null if not found.
  T? get<T>(String key) {
    final asset = _generics[key];
    if (asset is T) return asset;
    return null;
  }

  // --- Synchronous Setters ---

  /// Caches an Image.
  void setImage(String key, Image image) {
    _images[key] = image;
  }

  /// Caches a FragmentProgram.
  void setShader(String key, FragmentProgram shader) {
    _shaders[key] = shader;
  }

  /// Caches bytes.
  void setBytes(String key, Uint8List bytes) {
    _bytes[key] = bytes;
  }

  /// Caches a text string.
  void setText(String key, String text) {
    _texts[key] = text;
  }

  /// Caches a generic asset.
  void set<T>(String key, T asset) {
    _generics[key] = asset;
  }

  // --- Asynchronous Loaders ---

  /// Loads an Image from a file path and caches it.
  Future<Image> loadImage(String key, String filePath) async {
    final image = await AssetLoader.loadImage(filePath);
    _images[key] = image;
    return image;
  }

  /// Loads an Image from a base64 string and caches it.
  Future<Image> loadEmbeddedImage(String key, String base64String) async {
    final image = await AssetLoader.loadEmbeddedImage(base64String);
    _images[key] = image;
    return image;
  }

  /// Loads a FragmentProgram from an asset key and caches it.
  Future<FragmentProgram> loadShader(String key, String assetKey) async {
    final shader = await AssetLoader.loadShader(assetKey);
    _shaders[key] = shader;
    return shader;
  }

  /// Loads bytes from a file path and caches them.
  Future<Uint8List> loadBytes(String key, String filePath) async {
    final bytes = await AssetLoader.loadBytes(filePath);
    _bytes[key] = bytes;
    return bytes;
  }

  /// Loads text from a file path and caches it.
  Future<String> loadText(String key, String filePath) async {
    final text = await AssetLoader.loadText(filePath);
    _texts[key] = text;
    return text;
  }

  // --- Cache Lifecycle ---

  /// Checks if an asset exists in any cache.
  bool has(String key) {
    return _images.containsKey(key) ||
        _shaders.containsKey(key) ||
        _bytes.containsKey(key) ||
        _texts.containsKey(key) ||
        _generics.containsKey(key);
  }

  /// Returns the total number of cached assets.
  int get count {
    return _images.length +
        _shaders.length +
        _bytes.length +
        _texts.length +
        _generics.length;
  }

  /// Returns an iterable of all cached asset keys.
  Iterable<String> get keys {
    return _images.keys
        .followedBy(_shaders.keys)
        .followedBy(_bytes.keys)
        .followedBy(_texts.keys)
        .followedBy(_generics.keys);
  }

  /// Removes an asset from the cache.
  /// If [dispose] is true and the asset is an Image, it will be disposed.
  /// Returns true if the asset was found and removed.
  bool remove(String key, {bool dispose = true}) {
    bool removed = false;

    if (_images.containsKey(key)) {
      final image = _images.remove(key);
      if (dispose) {
        image?.dispose();
      }
      removed = true;
    }

    if (_shaders.remove(key) != null) removed = true;
    if (_bytes.remove(key) != null) removed = true;
    if (_texts.remove(key) != null) removed = true;
    if (_generics.remove(key) != null) removed = true;

    return removed;
  }

  /// Clears all caches.
  /// If [dispose] is true, all cached Images will be disposed.
  void clear({bool dispose = true}) {
    if (dispose) {
      for (final image in _images.values) {
        image.dispose();
      }
    }
    _images.clear();
    _shaders.clear();
    _bytes.clear();
    _texts.clear();
    _generics.clear();
  }
}
