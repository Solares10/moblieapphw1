import 'dart:ui';

import 'package:flame/components.dart';

import '../klondike_game.dart';
import '../pile.dart';
import 'card.dart';
import 'waste_pile.dart';

class StockPile extends PositionComponent
    with HasGameReference<KlondikeGame>
    implements Pile {
  StockPile({super.position}) : super(size: KlondikeGame.cardSize);

  final List<Card> _cards = [];

  @override
  bool canMoveCard(Card card, MoveMethod method) => false;

  @override
  bool canAcceptCard(Card card) => false;

  @override
  void removeCard(Card card, MoveMethod method) =>
      throw StateError('cannot remove cards');

  @override
  void returnCard(Card card) => card.priority = _cards.indexOf(card);

  @override
  void acquireCard(Card card) {
    assert(card.isFaceDown);
    card.pile = this;
    card.position = position;
    card.priority = _cards.length;
    _cards.add(card);
  }

  void handleTapUp(Card card) {
    final wastePile = parent!.firstChild<WastePile>()!;
    if (_cards.isEmpty) {
      assert(card.isBaseCard);
      card.position = position;
      wastePile.removeAllCards().reversed.forEach((c) {
        c.flip();
        acquireCard(c);
      });
    } else {
      for (var i = 0; i < game.klondikeDraw; i++) {
        if (_cards.isNotEmpty) {
          final c = _cards.removeLast();
          c.doMoveAndFlip(wastePile.position, whenDone: () {
            wastePile.acquireCard(c);
          });
        }
      }
    }
  }

  // rendering
  final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const Color(0xFF3F5B5D);
  final _circlePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 100
    ..color = const Color(0x883F5B5D);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(KlondikeGame.cardRRect, _borderPaint);
    canvas.drawCircle(
      Offset(width / 2, height / 2),
      KlondikeGame.cardWidth * 0.3,
      _circlePaint,
    );
  }
}
