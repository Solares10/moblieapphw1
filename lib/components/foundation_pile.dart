import 'dart:ui';
import 'package:flame/components.dart';

import '../klondike_game.dart';
import '../pile.dart';
import '../suit.dart';
import 'card.dart';

/// A foundation pile: build A→K in the same suit. Cards are placed here in order.
/// - You can only move the *top* card off (and not by tap).
class FoundationPile extends PositionComponent implements Pile {
  FoundationPile(int intSuit, this.checkWin, {super.position})
      : suit = Suit.fromInt(intSuit),
        super(size: KlondikeGame.cardSize);

  final VoidCallback checkWin;     // called when all 13 cards are stacked
  final Suit suit;                 // which suit this foundation accepts
  final List<Card> _cards = [];    // bottom→top

  bool get isFull => _cards.length == 13;

  @override
  bool canMoveCard(Card card, MoveMethod method) =>
      _cards.isNotEmpty && card == _cards.last && method != MoveMethod.tap;
  // Only the top card can move, and not via tap (drag only).

  @override
  bool canAcceptCard(Card card) {
    final topRank = _cards.isEmpty ? 0 : _cards.last.rank.value;
    // Must match suit and be exactly the next rank (A=1 … K=13), no attached stack.
    return card.suit == suit &&
        card.rank.value == topRank + 1 &&
        card.attachedCards.isEmpty;
  }

  @override
  void removeCard(Card card, MoveMethod method) {
    assert(canMoveCard(card, method));
    _cards.removeLast();
  }

  @override
  void returnCard(Card card) {
    // Snap back to pile position and z-order
    card.position = position;
    card.priority = _cards.indexOf(card);
  }

  @override
  void acquireCard(Card card) {
    assert(card.isFaceUp);
    card.position = position;
    card.priority = _cards.length; // top-most
    card.pile = this;
    _cards.add(card);
    if (isFull) checkWin();        // notify world if this foundation is complete
  }

  // --- Rendering (simple outline + faint suit icon) ---

  final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const Color(0x50ffffff);

  // Slightly different darkness for red/black suits, blended over background
  late final _suitPaint = Paint()
    ..color = suit.isRed ? const Color(0x3a000000) : const Color(0x64000000)
    ..blendMode = BlendMode.luminosity;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(KlondikeGame.cardRRect, _borderPaint);
    suit.sprite.render(
      canvas,
      position: size / 2,
      anchor: Anchor.center,
      size: Vector2.all(KlondikeGame.cardWidth * 0.6),
      overridePaint: _suitPaint,
    );
  }
}
