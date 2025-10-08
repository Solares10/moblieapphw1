import 'dart:ui';
import 'package:flame/components.dart';

import '../klondike_game.dart';
import '../pile.dart';
import 'card.dart';
import 'waste_pile.dart';

/// The Stock pile (the face-down deck).
/// - Holds face-down cards only.
/// - Tap behavior deals to Waste; tapping when empty recycles Waste back.
class StockPile extends PositionComponent
    with HasGameReference<KlondikeGame> // gives access to `game` (draw count, etc.)
    implements Pile {
  StockPile({super.position}) : super(size: KlondikeGame.cardSize);

  /// Cards in bottom→top order (last element is the visible top).
  final List<Card> _cards = [];

  // Cards are never moved out by user (only by tap logic below).
  @override
  bool canMoveCard(Card card, MoveMethod method) => false;

  // You never drop cards onto the Stock.
  @override
  bool canAcceptCard(Card card) => false;

  // Removing from Stock via Pile API is illegal; handled internally.
  @override
  void removeCard(Card card, MoveMethod method) =>
      throw StateError('cannot remove cards');

  // If a drag started and got cancelled, restore z-order.
  @override
  void returnCard(Card card) => card.priority = _cards.indexOf(card);

  // Push a face-down card onto the stock's top.
  @override
  void acquireCard(Card card) {
    assert(card.isFaceDown);
    card.pile = this;
    card.position = position;
    card.priority = _cards.length;
    _cards.add(card);
  }

  /// Called when the user taps the Stock (or the base-card sitting on it).
  /// - If stock is empty: flip Waste back into Stock (recycling).
  /// - Otherwise: deal `game.klondikeDraw` cards to the Waste with animations.
  void handleTapUp(Card card) {
    final wastePile = parent!.firstChild<WastePile>()!;
    if (_cards.isEmpty) {
      // Recycle: base card should be present to catch the tap.
      assert(card.isBaseCard);
      card.position = position; // ensure base card stays aligned
      // Move all Waste cards back, flipping to face-down as they return.
      for (final c in wastePile.removeAllCards().reversed) {
        c.flip();
        acquireCard(c);
      }
    } else {
      // Deal 1 or 3 cards from Stock to Waste (face-up with a small move).
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

  // --- Rendering: outlined rounded-rect with a circle hint icon ---

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
