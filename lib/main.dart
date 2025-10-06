import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(GameWidget(game: TestGame()));
}

class TestGame extends FlameGame {
  @override
  Future<void> onLoad() async {
    // Draw a big green rectangle so we absolutely see something.
    add(RectangleComponent()
      ..size = Vector2(size.x * 0.6, size.y * 0.4)
      ..position = Vector2(size.x * 0.2, size.y * 0.3)
      ..paint = Paint()..color = const Color(0xFF228B22));
    // Add a label
    add(TextComponent(
      text: 'Flame Render OK',
      position: Vector2(24, 24),
      textRenderer: TextPaint(style: const TextStyle(fontSize: 28, color: Colors.white)),
    ));
  }

  @override
  Color backgroundColor() => const Color(0xFF0B6E4F);
}
