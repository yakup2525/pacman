import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '/core/core.dart';

final class GameCubit extends BaseCubit<AppState> {
  GameCubit() : super(const InitialState());

  final int numberOfSquares = AppConstants.numberInRow * 18;

  // Level management
  int currentLevel = 1;
  bool portalOpen = false;

  int player = Level1.playerStartPosition;
  int ghost = Level1.ghost1StartPosition;
  int ghost2 = Level1.ghost2StartPosition;
  int ghost3 = Level1.ghost3StartPosition;
  bool preGame = true;
  bool mouthClosed = false;
  int score = 0;
  bool paused = false;
  final List<int> food = [];
  String direction = "right";
  String ghostLast = "left";
  String ghostLast2 = "left";
  String ghostLast3 = "down";

  List<int> barriers = List.from(Level1.barriers);

  void gameInitial() {
    safeEmit(const SuccessState());
  }

  void setGame() {
    safeEmit(const InitialState());
    safeEmit(const SuccessState());
  }

  void changeToNextLevel() {
    if (currentLevel < 3) {
      currentLevel++;
      _resetGameForLevelChange();
    }
  }

  void changeToPreviousLevel() {
    if (currentLevel > 1) {
      currentLevel--;
      _resetGameForLevelChange();
    }
  }

  void _resetGameForLevelChange() {
    preGame = true;
    portalOpen = false;
    paused = false;
    mouthClosed = false;

    _loadLevel(currentLevel);
    setGame();
  }

// Functions
  void startGame(BuildContext context) {
    if (preGame) {
      preGame = false;
      getFood();

      Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (player == ghost || player == ghost2 || player == ghost3) {
          player = -1;
          setGame();
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Center(child: Text("Game Over!")),
                  content: Text("Your Score :  $score"),
                  actions: [
                    MaterialButton(
                      onPressed: () {
                        currentLevel = 1;
                        portalOpen = false;
                        _loadLevel(1);
                        paused = false;
                        preGame = false;
                        mouthClosed = false;
                        score = 0;
                        Navigator.pop(context);
                        setGame();
                      },
                      child: Container(
                        width: 100,
                        height: 50,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xFF0D47A1),
                              Color(0xFF1976D2),
                              Color(0xFF42A5F5),
                            ],
                          ),
                        ),
                        child: const Center(
                            child: Text(
                          'Restart',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        )),
                      ),
                    )
                  ],
                );
              });
        }
      });
      Timer.periodic(const Duration(milliseconds: 190), (timer) {
        if (!paused) {
          moveGhost(ghost, ghostLast, (newGhost, newGhostlast) {
            ghost = newGhost;
            ghostLast = newGhostlast;
            setGame();
          });
          moveGhost(ghost2, ghostLast2, (newGhost2, newGhostlast2) {
            ghost2 = newGhost2;
            ghostLast2 = newGhostlast2;
            setGame();
          });
          moveGhost(ghost3, ghostLast3, (newGhost3, newGhostlast3) {
            ghost3 = newGhost3;
            ghostLast3 = newGhostlast3;
            setGame();
          }, dontFollow: true);
        }
      });
      Timer.periodic(const Duration(milliseconds: 170), (timer) {
        mouthClosed = !mouthClosed;

        setGame();

        if (food.contains(player)) {
          food.remove(player);

          setGame();

          score++;
        }

        _checkPortalOpening();

        switch (direction) {
          case "left":
            if (!paused) moveLeft();
            break;
          case "right":
            if (!paused) moveRight();
            break;
          case "up":
            if (!paused) moveUp();
            break;
          case "down":
            if (!paused) moveDown();
            break;
        }
      });
    }
  }

  void getFood() {
    for (int i = 0; i < numberOfSquares; i++) {
      if (!barriers.contains(i)) {
        food.add(i);
      }
    }
  }

  void _checkPortalOpening() {
    if (!portalOpen && food.isEmpty) {
      portalOpen = true;
      _openPortal();
      setGame();
    }
  }

  void _openPortal() {
    final int portalPos;
    switch (currentLevel) {
      case 1:
        portalPos = Level1.portalPosition;
        break;
      case 2:
        portalPos = Level2.portalPosition;
        break;
      case 3:
        portalPos = Level3.portalPosition;
        break;
      default:
        portalPos = Level1.portalPosition;
    }
    barriers.remove(portalPos);
  }

  void _checkLevelTransition() {
    if (portalOpen) {
      final int portalPos;
      switch (currentLevel) {
        case 1:
          portalPos = Level1.portalPosition;
          break;
        case 2:
          portalPos = Level2.portalPosition;
          break;
        case 3:
          portalPos = Level3.portalPosition;
          break;
        default:
          portalPos = Level1.portalPosition;
      }

      if (player == portalPos) {
        _loadNextLevel();
      }
    }
  }

  void _loadNextLevel() {
    currentLevel++;
    portalOpen = false;

    _loadLevel(currentLevel);
  }

  void _loadLevel(int level) {
    switch (level) {
      case 1:
        barriers = List.from(Level1.barriers);
        player = Level1.playerStartPosition;
        ghost = Level1.ghost1StartPosition;
        ghost2 = Level1.ghost2StartPosition;
        ghost3 = Level1.ghost3StartPosition;
        break;
      case 2:
        barriers = List.from(Level2.barriers);
        player = Level2.playerStartPosition;
        ghost = Level2.ghost1StartPosition;
        ghost2 = Level2.ghost2StartPosition;
        ghost3 = Level2.ghost3StartPosition;
        break;
      case 3:
        barriers = List.from(Level3.barriers);
        player = Level3.playerStartPosition;
        ghost = Level3.ghost1StartPosition;
        ghost2 = Level3.ghost2StartPosition;
        ghost3 = Level3.ghost3StartPosition;
        break;
      default:
        // Level 2'den sonra tekrar level 1'e dön veya oyunu bitir
        barriers = List.from(Level1.barriers);
        player = Level1.playerStartPosition;
        ghost = Level1.ghost1StartPosition;
        ghost2 = Level1.ghost2StartPosition;
        ghost3 = Level1.ghost3StartPosition;
        currentLevel = 1;
    }

    direction = "right";
    ghostLast = "left";
    ghostLast2 = "left";
    ghostLast3 = "down";

    food.clear();
    getFood();
    setGame();
  }

  void moveLeft() {
    if (!barriers.contains(player - 1)) {
      player--;
      _checkLevelTransition();
      setGame();
    }
  }

  void moveRight() {
    if (!barriers.contains(player + 1)) {
      player++;
      _checkLevelTransition();
      setGame();
    }
  }

  void moveUp() {
    if (!barriers.contains(player - AppConstants.numberInRow)) {
      player -= AppConstants.numberInRow;
      _checkLevelTransition();
      setGame();
    }
  }

  void moveDown() {
    if (!barriers.contains(player + AppConstants.numberInRow)) {
      player += AppConstants.numberInRow;
      _checkLevelTransition();
      setGame();
    }
  }

  void moveGhost(int ghost, String ghostLast, Function(int, String) updateState,
      {bool dontFollow = false}) {
    Random random = Random();
    String newGhostLast = ghostLast;
    int newGhost = ghost;
    bool moved = false;

    while (!moved) {
      List<String> possibleDirections = [];

      // Mevcut yönu %95 olasılıkla koru, %3 olasılıkla geri dönmeyi sec
      if (random.nextDouble() > 0.03) {
        possibleDirections.add(ghostLast);
      } else {
        switch (ghostLast) {
          case "left":
            possibleDirections.add("right");
            break;
          case "right":
            possibleDirections.add("left");
            break;
          case "up":
            possibleDirections.add("down");
            break;
          case "down":
            possibleDirections.add("up");
            break;
        }
      }

      if (!dontFollow) {
        if (random.nextDouble() < 0.7) {
          if (player < 100) {
            possibleDirections.add("up");
          } else {
            possibleDirections.add("down");
          }
        }

        final playerPos = player.toString();
        if (playerPos.length == 2) {
          if (player > 10 && random.nextDouble() < 0.7) {
            if (int.parse(playerPos[1]) - int.parse(playerPos[1]) < 6) {
              possibleDirections.add("left");
            } else {
              possibleDirections.add("right");
            }
          }
        }
      }

      // Yan yönleri kontrol et
      bool canGoLeft = !barriers.contains(ghost - 1);
      bool canGoRight = !barriers.contains(ghost + 1);
      bool canGoUp = !barriers.contains(ghost - AppConstants.numberInRow);
      bool canGoDown = !barriers.contains(ghost + AppConstants.numberInRow);

      // Yan yönler varsa, %30 olasılıkla bu yönleri tercih et
      // Yan yönler tercih edilmiyorsa veya mumkun değilse, diğer yönleri ekle

      if (canGoLeft && random.nextDouble() < 0.3) {
        possibleDirections.add("left");
      }
      if (canGoRight && random.nextDouble() < 0.3) {
        possibleDirections.add("right");
      }
      if (canGoUp && random.nextDouble() < 0.3) {
        possibleDirections.add("up");
      }
      if (canGoDown && random.nextDouble() < 0.3) {
        possibleDirections.add("down");
      }

      // Hareket etmek icin mumkun yönlerden birini sec
      if (possibleDirections.isNotEmpty) {
        newGhostLast =
            possibleDirections[random.nextInt(possibleDirections.length)];
      }

      switch (newGhostLast) {
        case "left":
          if (canGoLeft) {
            newGhost--;
            moved = true;
          }
          break;
        case "right":
          if (canGoRight) {
            newGhost++;
            moved = true;
          }
          break;
        case "up":
          if (canGoUp) {
            newGhost -= AppConstants.numberInRow;
            moved = true;
          }
          break;
        case "down":
          if (canGoDown) {
            newGhost += AppConstants.numberInRow;
            moved = true;
          }
          break;
      }
    }

    updateState(newGhost, newGhostLast);
  }

//
}
