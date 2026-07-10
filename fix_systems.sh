sed -i 's/void render(Canvas canvas, \[double scale = 1.0\]) {/void render(Canvas canvas, \[double scale = 1.0\]) {\n    _paint.shader = null;/g' lib/engine/systems/sprite_render_system.dart
sed -i 's/void render(Canvas canvas, \[double scale = 1.0\]) {/void render(Canvas canvas, \[double scale = 1.0\]) {\n    _paint.shader = null;/g' lib/engine/systems/tilemap_render_system.dart
