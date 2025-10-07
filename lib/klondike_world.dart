import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';

import 'components/card.dart';
import 'components/flat_button.dart';
import 'components/foundation_pile.dart';
import 'components/stock_pile.dart';
import 'components/tableau_pile.dart';
import 'components/waste_pile.dart';

import 'klondike_game.dart';

class KlondikeWorld extends World with HasGameReference<KlondikeGame> {
  final cardGap = KlondikeGame.cardGap;
  final topGap = KlondikeGame.topGap;
  final cardSpaceWidth = KlondikeGame.cardSpaceWidth;
  final cardSpaceHeight = KlondikeGame.cardSpaceHeight;

  final stock = StockPile(position: Vector2(0.0, 0.0));
  final waste = WastePile(position: Vector2(0.0, 0.0));
  final List<FoundationPile> foundations = [];
  final List<TableauPile> tableauPiles = [];
  final List<Card> cards = [];
  late Vector2 playAreaSize;

  @override
  Future<void> onLoad() async {
    // make Flame load from assets/images by default
    Flame.images.prefix = 'assets/images/';
    await Flame.images.load('klondike-sprites.png');

    stock.position = Vector2(cardGap, topGap);
    waste.position = Vector2(cardSpaceWidth + cardGap, topGap);

    for (var i = 0; i < 4; i++) {
      foundations.add(
        FoundationPile(
          i,
          checkWin,
          position: Vector2((i + 3) * cardSpaceWidth + cardGap, topGap),
        ),
      );
    }
    for (var i = 0; i < 7; i++) {
      tableauPiles.add(
        TableauPile(
          position: Vector2(
            i * cardSpaceWidth + cardGap,
            cardSpaceHeight + topGap,
          ),
        ),
      );
    }

    // Base card for Stock (so empty stock taps behave like real cards)
    final baseCard = Card(1, 0, isBaseCard: true)
      ..position = stock.position
      ..priority = -1
      ..pile = stock;
    stock.priority = -2;

    // create deck
    for (var rank = 1; rank <= 13; rank++) {
      for (var suit = 0; suit < 4; suit++) {
        final card = Card(rank, suit)..position = stock.position;
        cards.add(card);
      }
    }

    add(stock);
    add(waste);
    addAll(foundations);
    addAll(tableauPiles);
    addAll(cards);
    add(baseCard);

    playAreaSize = Vector2(
      7 * cardSpaceWidth + cardGap,
      4 * cardSpaceHeight + topGap,
    );
    final gameMidX = playAreaSize.x / 2;

    addButton('New deal', gameMidX, Action.newDeal);
    addButton('Same deal', gameMidX + cardSpaceWidth, Action.sameDeal);
    addButton('Draw 1 or 3', gameMidX + 2 * cardSpaceWidth, Action.changeDraw);
    addButton('Have fun', gameMidX + 3 * cardSpaceWidth, Action.haveFun);

    final camera = game.camera;
    camera.viewfinder.visibleGameSize = playAreaSize;
    camera.viewfinder.position = Vector2(gameMidX, 0);
    camera.viewfinder.anchor = Anchor.topCenter;

    deal();
  }

  void addButton(String label, double buttonX, Action action) {
    final button = FlatButton(
      label,
      size: Vector2(KlondikeGame.cardWidth, 0.6 * topGap),
      position: Vector2(buttonX, topGap / 2),
      onReleased: () {
        if (action == Action.haveFun) {
          letsCelebrate();
        } else {
          game.action = action;
          game.world = KlondikeWorld();
        }
      },
    );
    add(button);
  }

  void deal() {
    assert(cards.length == 52);

    if (game.action != Action.sameDeal) {
      game.seed = Random().nextInt(KlondikeGame.maxInt);
      if (game.action == Action.changeDraw) {
        game.klondikeDraw = (game.klondikeDraw == 3) ? 1 : 3;
      }
    }
    cards.shuffle(Random(game.seed));

    // give increasing priority so later dealt cards fly above earlier ones
    var dealPriority = 1;
    for (final c in cards) {
      c.priority = dealPriority++;
    }

    // deal to 7 tableau piles
    var cardToDeal = cards.length - 1;
    var nMoving = 0;
    for (var i = 0; i < 7; i++) {
      for (var j = i; j < 7; j++) {
        final card = cards[cardToDeal--];
        card.doMove(
          tableauPiles[j].position,
          speed: 15.0,
          start: nMoving * 0.15,
          startPriority: 100 + nMoving,
          onComplete: () {
            tableauPiles[j].acquireCard(card);
            nMoving--;
            if (nMoving == 0) {
              var d = 0;
              for (final t in tableauPiles) {
                d++;
                t.flipTopCard(start: d * 0.15);
              }
            }
          },
        );
        nMoving++;
      }
    }
    for (var n = 0; n <= cardToDeal; n++) {
      stock.acquireCard(cards[n]);
    }
  }

  void checkWin() {
    var nComplete = 0;
    for (final f in foundations) {
      if (f.isFull) nComplete++;
    }
    if (nComplete == foundations.length) {
      letsCelebrate();
    }
  }

  void letsCelebrate({int phase = 1}) {
    // phase 1: gather to center; phase 2: scatter off-screen, then restart
    final cameraZoom = game.camera.viewfinder.zoom;
    final zoomedScreen = game.size / cameraZoom;
    final screenCenter = (playAreaSize - KlondikeGame.cardSize) / 2;
    final topLeft = Vector2(
      (playAreaSize.x - zoomedScreen.x) / 2 - KlondikeGame.cardWidth,
      -KlondikeGame.cardHeight,
    );
    final nCards = cards.length;
    final offH = zoomedScreen.y + KlondikeGame.cardSize.y;
    final offW = zoomedScreen.x + KlondikeGame.cardSize.x;
    final spacing = 2.0 * (offH + offW) / nCards;

    final corner = [
      Vector2(0, 0),
      Vector2(0, offH),
      Vector2(offW, offH),
      Vector2(offW, 0),
    ];
    final dir = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)];
    final len = [offH, offW, offH, offW];

    var side = 0, cardsToMove = nCards, space = len[side];
    var offPos = corner[side] + topLeft;
    var k = 0;

    while (k < nCards) {
      final idx = phase == 1 ? k : nCards - k - 1;
      final card = cards[idx];
      card.priority = idx + 1;
      if (card.isFaceDown) card.flip();

      final delay = phase == 1 ? k * 0.02 : 0.5 + k * 0.04;
      final dest = (phase == 1) ? screenCenter : offPos;

      card.doMove(
        dest,
        speed: (phase == 1) ? 15.0 : 5.0,
        start: delay,
        onComplete: () {
          cardsToMove--;
          if (cardsToMove == 0) {
            if (phase == 1) {
              letsCelebrate(phase: 2);
            } else {
              game.action = Action.newDeal;
              game.world = KlondikeWorld();
            }
          }
        },
      );
      k++;
      if (phase == 1) continue;

      offPos = offPos + dir[side] * spacing;
      space -= spacing;
      if (space < 0 && side < 3) {
        side++;
        offPos = corner[side] + topLeft - dir[side] * space;
        space = len[side] + space;
      }
    }
  }
}
