import 'dart:ui';

import 'package:flame/components.dart';

import '../klondike_game.dart';
import '../pile.dart';
import 'card.dart';

/// A tableau pile (one of the 7 columns in Klondike).
/// - Accepts descending, alternating-color runs (K down to A).
/// - Can move a face-up tail (card + any cards stacked on top of it).
class TableauPile extends PositionComponent implements Pile {
  TableauPile({super.position}) : super(size: KlondikeGame.cardSize);

  /// Cards from bottom -> top (last is visually on top).
  final List<Card> _cards = [];

  /// Small/large vertical spacing for face-down / face-up “fanning”.
  final Vector2 _fanOffset1 = Vector2(0, KlondikeGame.cardHeight * 0.05);
  final Vector2 _fanOffset2 = Vector2(0, KlondikeGame.cardHeight * 0.2);

  @override
  bool canMoveCard(Card card, MoveMethod method) =>
      // Drag can move any face-up tail; tap only if it's the top card.
  card.isFaceUp && (method == MoveMethod.drag || card == _cards.last);

  @override
  bool canAcceptCard(Card card) {
    if (_cards.isEmpty) {
      // Empty tableau only accepts a King.
      return card.rank.value == 13;
    } else {
      // Otherwise: alternate colors and strictly descending ranks.
      final top = _cards.last;
      return card.suit.isRed == !top.suit.isRed &&
          card.rank.value == top.rank.value - 1;
    }
  }

  @override
  void removeCard(Card card, MoveMethod method) {
    assert(_cards.contains(card) && card.isFaceUp);
    // Remove the card and any cards stacked on top of it.
    final idx = _cards.indexOf(card);
    _cards.removeRange(idx, _cards.length);

    // If a face-down card becomes exposed, flip it; otherwise relayout.
    if (_cards.isNotEmpty && _cards.last.isFaceDown) {
      flipTopCard();
      return;
    }
    layOutCards();
  }

  @override
  void returnCard(Card card) {
    // Put card back where it belongs and fix draw order.
    card.priority = _cards.indexOf(card);
    layOutCards();
  }

  @override
  void acquireCard(Card card) {
    // Add to top, then recompute positions and sizes.
    card.pile = this;
    card.priority = _cards.length;
    _cards.add(card);
    layOutCards();
  }

  /// Drop a run (firstCard + optional attached cards) onto this pile,
  /// animating each card to its new position.
  void dropCards(Card firstCard, [List<Card> attachedCards = const []]) {
    final list = [firstCard, ...attachedCards];
    Vector2 nextPos = _cards.isEmpty ? position : _cards.last.position;
    var toMove = list.length;

    for (final c in list) {
      c.pile = this;
      c.priority = _cards.length;

      // Offset grows as the stack grows (larger for face-up cards).
      if (_cards.isNotEmpty) {
        nextPos = nextPos + (c.isFaceDown ? _fanOffset1 : _fanOffset2);
      }

      _cards.add(c);
      c.doMove(nextPos, startPriority: c.priority, onComplete: () {
        toMove--;
        if (toMove == 0) calculateHitArea(); // expand hit-area after all moved
      });
    }
  }

  /// Flip the newly exposed top card, then relayout.
  void flipTopCard({double start = 0.1}) {
    assert(_cards.last.isFaceDown);
    _cards.last.turnFaceUp(start: start, onComplete: layOutCards);
  }

  /// Compute positions/priorities for the whole column and resize its hit box.
  void layOutCards() {
    if (_cards.isEmpty) {
      calculateHitArea();
      return;
    }
    _cards[0].position.setFrom(position);
    _cards[0].priority = 0;

    for (var i = 1; i < _cards.length; i++) {
      _cards[i].priority = i;
      _cards[i].position
        ..setFrom(_cards[i - 1].position)
        ..add(_cards[i - 1].isFaceDown ? _fanOffset1 : _fanOffset2);
    }
    calculateHitArea();
  }

  /// Make the interactive area tall enough to include the fanned stack.
  void calculateHitArea() {
    height = KlondikeGame.cardHeight * 1.5 +
        (_cards.length < 2 ? 0.0 : _cards.last.y - _cards.first.y);
  }

  /// Returns the list of cards stacked on top of [card] (not including it).
  List<Card> cardsOnTop(Card card) {
    assert(card.isFaceUp && _cards.contains(card));
    final idx = _cards.indexOf(card);
    return _cards.getRange(idx + 1, _cards.length).toList();
  }

  // --- Rendering: faint rounded-rect outline as the pile base ---

  final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const Color(0x50ffffff);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(KlondikeGame.cardRRect, _borderPaint);
  }
}
