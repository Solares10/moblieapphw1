import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/text.dart';
import 'package:flutter/material.dart';

/// A very simple flat-style button built from Flame components.
/// - Shows a text label centered
/// - Changes background component when pressed
class FlatButton extends ButtonComponent {
  FlatButton(
      String text, {
        super.size,         // expected in game units
        super.onReleased,   // callback when button is released
        super.position,     // top-left by default unless anchor changed
      }) : super(
    // Visuals for up/down states (custom component below)
    button: ButtonBackground(const Color(0xffece8a3)),
    buttonDown: ButtonBackground(Colors.red),
    // Child: centered text label
    children: [
      TextComponent(
        text: text,
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 0.5 * size!.y,      // scale text by button height
            fontWeight: FontWeight.bold,
            color: const Color(0xffdbaf58),
          ),
        ),
        position: size / 2.0,             // center the text
        anchor: Anchor.center,
      ),
    ],
    anchor: Anchor.center,                 // position is the center point
  );
}

/// Draws the rounded-rect outline used as the button’s background.
class ButtonBackground extends PositionComponent with HasAncestor<FlatButton> {
  final _paint = Paint()..style = PaintingStyle.stroke;

  late double cornerRadius;

  ButtonBackground(Color color) {
    _paint.color = color;                        // outline color
  }

  @override
  void onMount() {
    super.onMount();
    size = ance
