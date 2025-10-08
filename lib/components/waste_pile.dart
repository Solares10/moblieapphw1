import 'package:flame/components.dart';

import '../klondike_game.dart';
import '../pile.dart';
import 'card.dart';

/// The face-up discard pile (to the right of the stock).
class WastePile extends PositionComponent
    with HasGameReference<KlondikeGame>
    implements Pile {
  WastePile({super.position}) : super(size: KlondikeGame.cardSize);

  /// Bottom -> top (last is the visible top card).
  final List<Card> _cards = [];

  /// Horizontal fan offset used when Draw 3 is enabled.
  final Vector2 _fanOffset = Vector2(KlondikeGame.cardWidth * 0.2, 0);

  @override
  bool canMoveCard(Card card, MoveMethod method) =>
      // Only the top card can be moved/tapped/dragged.
  _cards.isNotEmpty && card == _cards.last;

  @override
  bool canAcceptCard(Card card) => false; // Waste never accepts direct drops.

  @override
  void removeCard(Card card, MoveMethod method) {
    assert(canMoveCard(card, method));
    _cards.removeLast();
    _fanOutTopCards(); // Reposition remaining top cards.
  }

  @override
  void returnCard(Card card) {
    // Card stays on Waste; fix z-order and layout.
    card.priority = _cards.indexOf(card);
    _fanOutTopCards();
  }

  @override
  void acquireCard(Card card) {
    // Cards that arrive here are face-up.
    assert(card.isFaceUp);
    card.pile = this;
    card.position = position;
    card.priority = _cards.length;
    _cards.add(card);
    _fanOutTopCards();
  }

  /// Moves all cards out (used when recycling Waste back to Stock).
  List<Card> removeAllCards() {
    final list = _cards.toList();
    _cards.clear();
    return list;
  }

  /// In Draw 3, show up to three cards fanned to the right.
  void _fanOutTopCards() {
    if (game.klondikeDraw == 1) return; // No fan for Draw 1.

    final n = _cards.length;

    // Reset all to base position first.
    for (var i = 0; i < n; i++) {
      _cards[i].position = position;
    }

    if (n == 2) {
      _cards[1].position.add(_fanOffset);
    } else if (n >= 3) {
      _cards[n - 2].position.add(_fanOffset);
      _cards[n - 1].position.addScaled(_fanOffset, 2);
    }
  }
}
