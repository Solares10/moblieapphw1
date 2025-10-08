import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';

import '../klondike_game.dart';
import '../klondike_world.dart';
import '../pile.dart';
import '../rank.dart';
import '../suit.dart';
import 'foundation_pile.dart';
import 'stock_pile.dart';
import 'tableau_pile.dart';

/// A single playing card:
/// - draws itself (front/back)
/// - handles drag & tap interactions
/// - knows which pile it belongs to
class Card extends PositionComponent
    with DragCallbacks, TapCallbacks, HasWorldReference<KlondikeWorld> {
  Card(int intRank, int intSuit, {this.isBaseCard = false})
      : rank = Rank.fromInt(intRank),
        suit = Suit.fromInt(intSuit),
        super(size: KlondikeGame.cardSize);

  final Rank rank;
  final Suit suit;
  Pile? pile;

  /// Outline-only “base” card (used on stock to catch taps; not playable).
  final bool isBaseCard;

  // Face state and interaction flags.
  bool _faceUp = false;
  bool _isAnimatedFlip = false;
  bool _isFaceUpView = false;
  bool _isDragging = false;
  Vector2 _whereCardStarted = Vector2.zero();

  // If dragging a run from tableau, the extra cards follow this one.
  final List<Card> attachedCards = [];

  bool get isFaceUp => _faceUp;
  bool get isFaceDown => !_faceUp;

  void flip() {
    // If flipping with animation, visual state drives truth; otherwise toggle.
    if (_isAnimatedFlip) {
      _faceUp = _isFaceUpView;
    } else {
      _faceUp = !_faceUp;
      _isFaceUpView = _faceUp;
    }
  }

  @override
  String toString() => rank.label + suit.label;

  // -------- Rendering --------

  @override
  void render(Canvas canvas) {
    if (isBaseCard) {
      _renderBaseCard(canvas);
      return;
    }
    _isFaceUpView ? _renderFront(canvas) : _renderBack(canvas);
  }

  // --- Back (shared art) ---

  static final Paint backBackgroundPaint = Paint()..color = const Color(0xff380c02);
  static final Paint backBorderPaint1 = Paint()
    ..color = const Color(0xffdbaf58)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
  static final Paint backBorderPaint2 = Paint()
    ..color = const Color(0x5CEF971B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 35;
  static final RRect cardRRect = RRect.fromRectAndRadius(
    KlondikeGame.cardSize.toRect(),
    const Radius.circular(KlondikeGame.cardRadius),
  );
  static final RRect backRRectInner = cardRRect.deflate(40);
  static final Sprite flameSprite = klondikeSprite(1367, 6, 357, 501);

  void _renderBack(Canvas canvas) {
    canvas.drawRRect(cardRRect, backBackgroundPaint);
    canvas.drawRRect(cardRRect, backBorderPaint1);
    canvas.drawRRect(backRRectInner, backBorderPaint2);
    flameSprite.render(canvas, position: size / 2, anchor: Anchor.center);
  }

  void _renderBaseCard(Canvas canvas) {
    canvas.drawRRect(cardRRect, backBorderPaint1);
  }

  // --- Front (rank/suit pips & face cards) ---

  static final Paint frontBackgroundPaint = Paint()..color = const Color(0xff000000);
  static final Paint redBorderPaint = Paint()
    ..color = const Color(0xffece8a3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
  static final Paint blackBorderPaint = Paint()
    ..color = const Color(0xff7ab2e8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10;
  static final blueFilter = Paint()
    ..colorFilter = const ColorFilter.mode(Color(0x880d8bff), BlendMode.srcATop);

  // Sprites are sliced from the shared sprite sheet (see klondikeSprite()).
  static final Sprite redJack = klondikeSprite(81, 565, 562, 488);
  static final Sprite redQueen = klondikeSprite(717, 541, 486, 515);
  static final Sprite redKing = klondikeSprite(1305, 532, 407, 549);
  static final Sprite blackJack = klondikeSprite(81, 565, 562, 488)..paint = blueFilter;
  static final Sprite blackQueen = klondikeSprite(717, 541, 486, 515)..paint = blueFilter;
  static final Sprite blackKing = klondikeSprite(1305, 532, 407, 549)..paint = blueFilter;

  void _renderFront(Canvas canvas) {
    canvas.drawRRect(cardRRect, frontBackgroundPaint);
    canvas.drawRRect(cardRRect, suit.isRed ? redBorderPaint : blackBorderPaint);

    final rankSprite = suit.isBlack ? rank.blackSprite : rank.redSprite;
    final suitSprite = suit.sprite;

    // Corner indicators + mirrored bottom.
    _drawSprite(canvas, rankSprite, 0.1, 0.08);
    _drawSprite(canvas, suitSprite, 0.1, 0.18, scale: 0.5);
    _drawSprite(canvas, rankSprite, 0.1, 0.08, rotate: true);
    _drawSprite(canvas, suitSprite, 0.1, 0.18, scale: 0.5, rotate: true);

    // Pips / face art by rank.
    switch (rank.value) {
      case 1:
        _drawSprite(canvas, suitSprite, 0.5, 0.5, scale: 2.5);
      case 2:
        _drawSprite(canvas, suitSprite, 0.5, 0.25);
        _drawSprite(canvas, suitSprite, 0.5, 0.25, rotate: true);
      case 3:
        _drawSprite(canvas, suitSprite, 0.5, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.5);
        _drawSprite(canvas, suitSprite, 0.5, 0.2, rotate: true);
      case 4:
        _drawSprite(canvas, suitSprite, 0.3, 0.25);
        _drawSprite(canvas, suitSprite, 0.7, 0.25);
        _drawSprite(canvas, suitSprite, 0.3, 0.25, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.25, rotate: true);
      case 5:
        _drawSprite(canvas, suitSprite, 0.3, 0.25);
        _drawSprite(canvas, suitSprite, 0.7, 0.25);
        _drawSprite(canvas, suitSprite, 0.3, 0.25, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.25, rotate: true);
        _drawSprite(canvas, suitSprite, 0.5, 0.5);
      case 6:
        _drawSprite(canvas, suitSprite, 0.3, 0.25);
        _drawSprite(canvas, suitSprite, 0.7, 0.25);
        _drawSprite(canvas, suitSprite, 0.3, 0.5);
        _drawSprite(canvas, suitSprite, 0.7, 0.5);
        _drawSprite(canvas, suitSprite, 0.3, 0.25, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.25, rotate: true);
      case 7:
        _drawSprite(canvas, suitSprite, 0.3, 0.2);
        _drawSprite(canvas, suitSprite, 0.7, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.35);
        _drawSprite(canvas, suitSprite, 0.3, 0.5);
        _drawSprite(canvas, suitSprite, 0.7, 0.5);
        _drawSprite(canvas, suitSprite, 0.3, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.2, rotate: true);
      case 8:
        _drawSprite(canvas, suitSprite, 0.3, 0.2);
        _drawSprite(canvas, suitSprite, 0.7, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.35);
        _drawSprite(canvas, suitSprite, 0.3, 0.5);
        _drawSprite(canvas, suitSprite, 0.7, 0.5);
        _drawSprite(canvas, suitSprite, 0.3, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.5, 0.35, rotate: true);
      case 9:
        _drawSprite(canvas, suitSprite, 0.3, 0.2);
        _drawSprite(canvas, suitSprite, 0.7, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.3);
        _drawSprite(canvas, suitSprite, 0.3, 0.4);
        _drawSprite(canvas, suitSprite, 0.7, 0.4);
        _drawSprite(canvas, suitSprite, 0.3, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.3, 0.4, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.4, rotate: true);
      case 10:
        _drawSprite(canvas, suitSprite, 0.3, 0.2);
        _drawSprite(canvas, suitSprite, 0.7, 0.2);
        _drawSprite(canvas, suitSprite, 0.5, 0.3);
        _drawSprite(canvas, suitSprite, 0.3, 0.4);
        _drawSprite(canvas, suitSprite, 0.7, 0.4);
        _drawSprite(canvas, suitSprite, 0.3, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.2, rotate: true);
        _drawSprite(canvas, suitSprite, 0.5, 0.3, rotate: true);
        _drawSprite(canvas, suitSprite, 0.3, 0.4, rotate: true);
        _drawSprite(canvas, suitSprite, 0.7, 0.4, rotate: true);
      case 11:
        _drawSprite(canvas, suit.isRed ? redJack : blackJack, 0.5, 0.5);
      case 12:
        _drawSprite(canvas, suit.isRed ? redQueen : blackQueen, 0.5, 0.5);
      case 13:
        _drawSprite(canvas, suit.isRed ? redKing : blackKing, 0.5, 0.5);
    }
  }

  /// Helper to draw a sprite at a relative position inside the card,
  /// optionally mirrored to the bottom.
  void _drawSprite(
      Canvas canvas,
      Sprite sprite,
      double relativeX,
      double relativeY, {
        double scale = 1,
        bool rotate = false,
      }) {
    if (rotate) {
      canvas.save();
      canvas.translate(size.x / 2, size.y / 2);
      canvas.rotate(pi);
      canvas.translate(-size.x / 2, -size.y / 2);
    }
    sprite.render(
      canvas,
      position: Vector2(relativeX * size.x, relativeY * size.y),
      anchor: Anchor.center,
      size: sprite.srcSize.scaled(scale),
    );
    if (rotate) {
      canvas.restore();
    }
  }

  // -------- Dragging --------

  @override
  void onTapCancel(TapCancelEvent event) {
    if (pile is StockPile) {
      _isDragging = false;
      handleTapUp(); // treat quick press on stock as tap
    }
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (pile is StockPile) {
      _isDragging = false;
      return;
    }
    _whereCardStarted = position.clone();
    attachedCards.clear();
    if (pile?.canMoveCard(this, MoveMethod.drag) ?? false) {
      _isDragging = true;
      priority = 100; // lift above others
      if (pile is TableauPile) {
        // If dragging a run, collect the cards on top so they follow.
        final extra = (pile! as TableauPile).cardsOnTop(this);
        for (final c in extra) {
          c.priority = attachedCards.length + 101;
          attachedCards.add(c);
        }
      }
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_isDragging) return;
    final delta = event.localDelta;
    position.add(delta);
    for (final c in attachedCards) {
      c.position.add(delta);
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (!_isDragging) return;
    _isDragging = false;

    // Short drag ≈ tap (return to start then try foundation auto-move).
    final shortDrag =
        (position - _whereCardStarted).length < KlondikeGame.dragTolerance;
    if (shortDrag && attachedCards.isEmpty) {
      doMove(_whereCardStarted, onComplete: () {
        pile!.returnCard(this);
        handleTapUp();
      });
      return;
    }

    // Check what pile is under the card center.
    final dropPiles = parent!
        .componentsAtPoint(position + size / 2)
        .whereType<Pile>()
        .toList();

    if (dropPiles.isNotEmpty && dropPiles.first.canAcceptCard(this)) {
      pile!.removeCard(this, MoveMethod.drag);
      if (dropPiles.first is TableauPile) {
        (dropPiles.first as TableauPile).dropCards(this, attachedCards);
        attachedCards.clear();
      } else {
        final dropPosition = (dropPiles.first as FoundationPile).position;
        doMove(dropPosition, onComplete: () {
          dropPiles.first.acquireCard(this);
        });
      }
      return;
    }

    // Invalid drop → snap back (and return attached run too).
    doMove(_whereCardStarted, onComplete: () {
      pile!.returnCard(this);
    });
    for (final c in attachedCards) {
      final offset = c.position - position;
      c.doMove(_whereCardStarted + offset, onComplete: () {
        pile!.returnCard(c);
      });
    }
    attachedCards.clear();
  }

  // -------- Tapping --------

  @override
  void onTapUp(TapUpEvent event) {
    handleTapUp();
  }

  /// Tap-to-autoplay to a foundation if legal; on stock, deal cards.
  void handleTapUp() {
    if (pile?.canMoveCard(this, MoveMethod.tap) ?? false) {
      final suitIndex = suit.value;
      if (world.foundations[suitIndex].canAcceptCard(this)) {
        pile!.removeCard(this, MoveMethod.tap);
        doMove(world.foundations[suitIndex].position, onComplete: () {
          world.foundations[suitIndex].acquireCard(this);
        });
      }
    } else if (pile is StockPile) {
      world.stock.handleTapUp(this);
    }
  }

  // -------- Effects / Animation --------

  /// Smooth move with optional delay and curve.
  void doMove(
      Vector2 to, {
        double speed = 10.0,
        double start = 0.0,
        int startPriority = 100,
        Curve curve = Curves.easeOutQuad,
        VoidCallback? onComplete,
      }) {
    final dt = (to - position).length / (speed * size.x);
    add(
      CardMoveEffect(
        to,
        EffectController(duration: dt, startDelay: start, curve: curve),
        transitPriority: startPriority,
        onComplete: onComplete,
      ),
    );
  }

  /// Move then flip face-up when arriving (used during dealing/stock).
  void doMoveAndFlip(
      Vector2 to, {
        double speed = 10.0,
        double start = 0.0,
        Curve curve = Curves.easeOutQuad,
        VoidCallback? whenDone,
      }) {
    final dt = (to - position).length / (speed * size.x);
    priority = 100;
    add(
      MoveToEffect(
        to,
        EffectController(duration: dt, startDelay: start, curve: curve),
        onComplete: () {
          turnFaceUp(onComplete: whenDone);
        },
      ),
    );
  }

  /// Flip animation: scale to thin edge, switch face, scale back.
  void turnFaceUp({
    double time = 0.3,
    double start = 0.0,
    VoidCallback? onComplete,
  }) {
    _isAnimatedFlip = true;
    anchor = Anchor.topCenter;
    position += Vector2(width / 2, 0);
    priority = 100;
    add(
      ScaleEffect.to(
        Vector2(scale.x / 100, scale.y),
        EffectController(
          startDelay: start,
          curve: Curves.easeOutSine,
          duration: time / 2,
          onMax: () {
            _isFaceUpView = true;
          },
          reverseDuration: time / 2,
          onMin: () {
            _isAnimatedFlip = false;
            _faceUp = true;
            anchor = Anchor.topLeft;
            position -= Vector2(width / 2, 0);
          },
        ),
        onComplete: onComplete,
      ),
    );
  }
}

/// Move effect that also temporarily raises the card’s draw order.
class CardMoveEffect extends MoveToEffect {
  CardMoveEffect(
      super.destination,
      super.controller, {
        super.onComplete,
        this.transitPriority = 100,
      });

  final int transitPriority;

  @override
  void onStart() {
    super.onStart();
    parent?.priority = transitPriority; // draw on top while traveling
  }
}
