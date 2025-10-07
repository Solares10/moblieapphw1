import 'package:flame/components.dart';
import 'package:flame/events.dart';
import '../logic/card_model.dart';

class CardComponent extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameRef {
  CardComponent(this.model, {required Vector2 position})
      : super(position: position, size: Vector2(70, 100), priority: 5);

  final CardModel model;
  bool _dragging = false;

  late RectangleComponent _cardBg;
  late RectangleComponent _border;
  TextComponent? _tl; // top-left label
  TextComponent? _br; // bottom-right label (rotated)

  @override
  Future<void> onLoad() async {
    anchor = Anchor.topLeft;

    // border (slightly bigger)
    _border = RectangleComponent(
      position: Vector2.zero(),
      size: size,
      paint: Paint()..color = const Color(0xFF184E3A),
      priority: 0,
    );
    add(_border);

    // face color (white)
    _cardBg = RectangleComponent(
      position: Vector2(2, 2),
      size: size - Vector2(4, 4),
      paint: Paint()..color = const Color(0xFFF2F2F2),
      priority: 1,
    );
    add(_cardBg);

    _renderFace();
  }

  void _renderFace() {
    // Clear old labels
    _tl?.removeFromParent();
    _br?.removeFromParent();

    if (model.faceUp) {
      final color = model.isRed ? const Color(0xFFB71C1C) : const Color(0xFF0D47A1);
      final label = '${model.rankLabel}${model.suitSymbol}';

      _tl = TextComponent(
        text: label,
        position: Vector2(6, 4),
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 16,
            height: 1.0,
            color: color,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
          ),
        ),
        priority: 2,
      )..anchor = Anchor.topLeft;
      add(_tl!);

      _br = TextComponent(
        text: label,
        position: size - Vector2(6, 4),
        textRenderer: TextPaint(
          style: TextStyle(
            fontSize: 16,
            height: 1.0,
            color: color,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
          ),
        ),
        priority: 2,
      )
        ..anchor = Anchor.bottomRight
        ..angle = 3.14159265; // upside-down
      add(_br!);

      // light pattern in the middle (just to look less plain)
      // you can remove this if you want
      final pip = RectangleComponent(
        position: Vector2(size.x / 2 - 8, size.y / 2 - 8),
        size: Vector2(16, 16),
        paint: Paint()..color = color.withOpacity(0.15),
        priority: 1,
      );
      _cardBg.add(pip);
    } else {
      // back of card
      _cardBg.paint.color = const Color(0xFF1565C0);
      // add a simple grid pattern
      for (double x = 6; x < size.x - 6; x += 8) {
        final bar = RectangleComponent(
          position: Vector2(x, 6),
          size: Vector2(2, size.y - 12),
          paint: Paint()..color = const Color(0xFF0D47A1),
          priority: 2,
        );
        _cardBg.add(bar);
      }
    }
  }

  // Tap to flip
  @override
  void onTapDown(TapDownEvent event) {
    model.faceUp = !model.faceUp;
    // reset face/background color
    _cardBg.paint.color = const Color(0xFFF2F2F2);
    _cardBg.children.clear();
    _renderFace();
  }

  // Dragging
  @override
  void onDragStart(DragStartEvent event) {
    priority = 100;
    _dragging = true;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_dragging) position += event.localDelta;
  }

  @override
  void onDragEnd(DragEndEvent event) {
    _dragging = false;
    priority = 5;
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    _dragging = false;
    priority = 5;
  }
}
