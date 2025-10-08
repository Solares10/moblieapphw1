import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

import 'klondike_world.dart';

/// What the user chose next (used to restart or tweak the deal).
enum Action { newDeal, sameDeal, changeDraw, haveFun }

/// Root Flame game; owns the camera and the active World.
class KlondikeGame extends FlameGame<KlondikeWorld> {
  // --- Card metrics (game-space units) ---
  static const double cardGap = 175.0;      // spacing between piles
  static const double topGap = 500.0;       // space reserved for buttons
  static const double cardWidth = 1000.0;
  static const double cardHeight = 1400.0;
  static const double cardRadius = 100.0;
  static const double cardSpaceWidth = cardWidth + cardGap;
  static const double cardSpaceHeight = cardHeight + cardGap;

  // Precomputed sizes/shapes used everywhere.
  static final Vector2 cardSize = Vector2(cardWidth, cardHeight);
  static final cardRRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, cardWidth, cardHeight),
    const Radius.circular(cardRadius),
  );

  /// Small drags under this distance count as a tap (friendlier UX).
  static const double dragTolerance = cardWidth / 5;

  /// Upper bound for RNG seed (2^32 - 2).
  static const int maxInt = 0xFFFFFFFE;

  KlondikeGame() : super(world: KlondikeWorld());

  // Persist across deals so the next world knows how to start.
  int klondikeDraw = 1; // 1 or 3 cards from stock
  int seed = 1;
  Action action = Action.newDeal;
}

/// Convenience to slice a sprite out of the cached sheet.
/// (Make sure 'klondike-sprites.png' is loaded before calling.)
Sprite klondikeSprite(double x, double y, double width, double height) {
  return Sprite(
    Flame.images.fromCache('klondike-sprites.png'),
    srcPosition: Vector2(x, y),
    srcSize: Vector2(width, height),
  );
}
