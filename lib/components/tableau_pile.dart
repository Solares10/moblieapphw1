import 'dart:ui';

import 'package:flame/components.dart';

import '../klondike_game.dart';
import '../pile.dart';
import 'card.dart';

class TableauPile extends PositionComponent implements Pile {
  TableauPile({super.position}) : super(size: KlondikeGame.cardSize);

  final List<Card> _cards = [];
  final Vector2 _fanOffset1 = Vector2(0, KlondikeGame.cardHeight * 0.05);
  final Vector2 _fanOffset2 = Vector2(0, KlondikeGame.cardHeight * 0.2);

  @override
  bool canMoveCard(Card card, MoveMethod method) =>
      card.isFaceUp && (method == MoveMethod.drag || card == _cards.last);

  @override
  bool canAcceptCard(Card card) {
    if (_cards.isEmpty) {
      return card.rank.value == 13;
    } else {
      final top = _cards.last;
      return card.suit.isRed == !top.suit.isRed &&
          card.rank.value == top.rank.value - 1;
    }
  }

  @override
  void removeCard(Card card, MoveMethod method) {
    assert(_cards.contains(card) && card.isFaceUp);
    final idx = _cards.indexOf(card);
    _cards.removeRange(idx, _cards.length);
    if (_cards.isNotEmpty && _cards.last.isFaceDown) {
      flipTopCard();
      return;
    }
    layOutCards();
  }

  @override
  void returnCard(Card card) {
    card.priority = _cards.indexOf(card);
    layOutCards();
  }

  @override
  void acquireCard(Card card) {
    card.pile = this;
    card.priority = _cards.length;
    _cards.add(card);
    layOutCards();
  }

  void dropCards(Card firstCard, [List<Card> attachedCards = const []]) {
    final list = [firstCard, ...attachedCards];
    Vector2 nextPos = _cards.isEmpty ? position : _cards.last.position;
    var toMove = list.length;
    for (final c in list) {
      c.pile = this;
      c.priority = _cards.length;
      if (_cards.isNotEmpty) {
        nextPos = nextPos + (c.isFaceDown ? _fanOffset1 : _fanOffset2);
      }
      _cards.add(c);
      c.doMove(nextPos, startPriority: c.priority, onComplete: () {
        toMove--;
        if (toMove == 0) calculateHitArea();
      });
    }
  }

  void flipTopCard({double start = 0.1}) {
    assert(_cards.last.isFaceDown);
    _cards.last.turnFaceUp(start: start, onComplete: layOutCards);
  }

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

  void calculateHitArea() {
    height = KlondikeGame.cardHeight * 1.5 +
        (_cards.length < 2 ? 0.0 : _cards.last.y - _cards.first.y);
  }

  List<Card> cardsOnTop(Card card) {
    assert(card.isFaceUp && _cards.contains(card));
    final idx = _cards.indexOf(card);
    return _cards.getRange(idx + 1, _cards.length).toList();
  }

  // rendering
  final _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..color = const Color(0x50ffffff);

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(KlondikeGame.cardRRect, _borderPaint);
  }
}
