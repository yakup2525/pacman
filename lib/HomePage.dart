import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pacman/ghost.dart';
import 'package:pacman/ghost2.dart';
import 'package:pacman/ghost3.dart';
import 'package:pacman/path.dart';
import 'package:pacman/barrier.dart';
import 'package:pacman/player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static int numberInRow = 11;
  int numberOfSquares = numberInRow * 18;
  int player = numberInRow * 14 + 1;
  int ghost = numberInRow * 2 - 2;
  int ghost2 = numberInRow * 9 - 8;
  int ghost3 = numberInRow * 11 - 2;
  bool preGame = true;
  bool mouthClosed = false;
  int score = 0;
  bool paused = false;

  List<int> barriers = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    15,
    21,
    22,
    24,
    26,
    28,
    30,
    32,
    33,
    35,
    39,
    41,
    43,
    44,
    46,
    47,
    48,
    50,
    52,
    54,
    55,
    61,
    65,
    66,
    68,
    69,
    70,
    72,
    74,
    76,
    77,
    79,
    85,
    87,
    88,
    90,
    92,
    93,
    94,
    96,
    98,
    99,
    101,
    103,
    104,
    105,
    107,
    109,
    110,
    112,
    120,
    121,
    123,
    125,
    126,
    127,
    129,
    131,
    132,
    140,
    142,
    143,
    145,
    146,
    148,
    149,
    151,
    153,
    154,
    159,
    162,
    164,
    165,
    167,
    168,
    169,
    170,
    172,
    173,
    175,
    176,
    186,
    187,
    188,
    189,
    190,
    191,
    192,
    193,
    194,
    195,
    196,
    197,
  ];

  List<int> food = [];
  String direction = "right";
  String ghostLast = "left";
  String ghostLast2 = "left";
  String ghostLast3 = "down";

  void startGame() {
    if (preGame) {
      preGame = false;
      getFood();

      Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (player == ghost || player == ghost2 || player == ghost3) {
          setState(() {
            player = -1;
          });
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
                        setState(() {
                          player = numberInRow * 14 + 1;
                          ghost = numberInRow * 2 - 2;
                          ghost2 = numberInRow * 9 - 1;
                          ghost3 = numberInRow * 11 - 2;
                          paused = false;
                          preGame = false;
                          mouthClosed = false;
                          direction = "right";
                          food.clear();
                          getFood();
                          score = 0;
                          Navigator.pop(context);
                        });
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
            setState(() {
              ghost = newGhost;
              ghostLast = newGhostlast;
            });
          });
          moveGhost(ghost2, ghostLast2, (newGhost2, newGhostlast2) {
            setState(() {
              ghost2 = newGhost2;
              ghostLast2 = newGhostlast2;
            });
          });
          moveGhost(ghost3, ghostLast3, (newGhost3, newGhostlast3) {
            setState(() {
              ghost3 = newGhost3;
              ghostLast3 = newGhostlast3;
            });
          }, dontFollow: true);
        }
      });
      Timer.periodic(const Duration(milliseconds: 170), (timer) {
        setState(() {
          mouthClosed = !mouthClosed;
        });
        if (food.contains(player)) {
          setState(() {
            food.remove(player);
          });
          score++;
        }

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

  void restart() {
    startGame();
  }

  void getFood() {
    for (int i = 0; i < numberOfSquares; i++) {
      if (!barriers.contains(i)) {
        food.add(i);
      }
    }
  }

  void moveLeft() {
    if (!barriers.contains(player - 1)) {
      setState(() {
        player--;
      });
    }
  }

  void moveRight() {
    if (!barriers.contains(player + 1)) {
      setState(() {
        player++;
      });
    }
  }

  void moveUp() {
    if (!barriers.contains(player - numberInRow)) {
      setState(() {
        player -= numberInRow;
      });
    }
  }

  void moveDown() {
    if (!barriers.contains(player + numberInRow)) {
      setState(() {
        player += numberInRow;
      });
    }
  }

  void moveGhost(int ghost, String ghostLast, Function(int, String) updateState, {bool dontFollow = false}) {
    Random random = Random();
    String newGhostLast = ghostLast;
    int newGhost = ghost;
    bool moved = false;

    while (!moved) {
      List<String> possibleDirections = [];

      // Mevcut yönü %95 olasılıkla koru, %3 olasılıkla geri dönmeyi seç
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
      bool canGoUp = !barriers.contains(ghost - numberInRow);
      bool canGoDown = !barriers.contains(ghost + numberInRow);

      // Yan yönler varsa, %30 olasılıkla bu yönleri tercih et
      // if ((canGoLeft || canGoRight) && random.nextDouble() < 0.3) {
      //   if (canGoLeft) possibleDirections.add("left");
      //   if (canGoRight) possibleDirections.add("right");
      // }
      // Yan yönler tercih edilmiyorsa veya mümkün değilse, diğer yönleri ekle

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

      // Hareket etmek için mümkün yönlerden birini seç
      if (possibleDirections.isNotEmpty) {
        newGhostLast = possibleDirections[random.nextInt(possibleDirections.length)];
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
            newGhost -= numberInRow;
            moved = true;
          }
          break;
        case "down":
          if (canGoDown) {
            newGhost += numberInRow;
            moved = true;
          }
          break;
      }
    }

    updateState(newGhost, newGhostLast);
  }

  // void moveGhost(
  //     int ghost, String ghostLast, Function(int, String) updateState) {
  //   Random random = Random();
  //   List<String> directions = ["left", "right", "up", "down"];
  //   String newGhostLast = ghostLast;
  //   int newGhost = ghost;
  //   bool moved = false;

  //   while (!moved) {
  //     // Mevcut yönü %70 olasılıkla koru, %30 olasılıkla rastgele yeni bir yön seç
  //     if (random.nextDouble() > 0.3) {
  //       newGhostLast = ghostLast;
  //     } else {
  //       newGhostLast = directions[random.nextInt(directions.length)];
  //     }

  //     switch (newGhostLast) {
  //       case "left":
  //         if (!barriers.contains(ghost - 1)) {
  //           newGhost--;
  //           moved = true;
  //         }
  //         break;
  //       case "right":
  //         if (!barriers.contains(ghost + 1)) {
  //           newGhost++;
  //           moved = true;
  //         }
  //         break;
  //       case "up":
  //         if (!barriers.contains(ghost - numberInRow)) {
  //           newGhost -= numberInRow;
  //           moved = true;
  //         }
  //         break;
  //       case "down":
  //         if (!barriers.contains(ghost + numberInRow)) {
  //           newGhost += numberInRow;
  //           moved = true;
  //         }
  //         break;
  //     }
  //   }

  //   updateState(newGhost, newGhostLast);
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            _gameMap(context),
            _dashboard(),
          ],
        ),
      ),
    );
  }

  Widget _gameMap(BuildContext context) {
    return Expanded(
      flex: 6,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 0) {
            direction = "down";
          } else if (details.delta.dy < 0) {
            direction = "up";
          }
        },
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx > 0) {
            direction = "right";
          } else if (details.delta.dx < 0) {
            direction = "left";
          }
        },
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: numberOfSquares,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: numberInRow),
          itemBuilder: (BuildContext context, int index) {
            if (mouthClosed && player == index) {
              return Container(
                decoration: const BoxDecoration(color: Colors.yellow, shape: BoxShape.circle),
              );
            } else if (player == index) {
              switch (direction) {
                case "left":
                  return Transform.rotate(
                    angle: pi,
                    child: const MyPlayer(),
                  );
                case "right":
                  return const MyPlayer();
                case "up":
                  return Transform.rotate(
                    angle: 3 * pi / 2,
                    child: const MyPlayer(),
                  );
                case "down":
                  return Transform.rotate(
                    angle: pi / 2,
                    child: const MyPlayer(),
                  );
                default:
                  return const MyPlayer();
              }
            } else if (ghost == index) {
              return const BlueGhost();
            } else if (ghost2 == index) {
              return const RedGhost();
            } else if (ghost3 == index) {
              return const YellowGhost();
            } else if (barriers.contains(index)) {
              return Barrier(
                barrierColor: Colors.blue.shade800,
              );
            } else if (preGame || food.contains(index)) {
              return const Path(
                innerColor: Colors.yellow,
                outerColor: Colors.black,
                child: SizedBox(),
              );
            } else {
              return const Path(
                innerColor: Colors.black,
                outerColor: Colors.black,
                child: SizedBox(),
              );
            }
          },
        ),
      ),
    );
  }

  Expanded _dashboard() {
    return Expanded(
      child: SizedBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              " Score : $score",
              style: const TextStyle(color: Colors.white, fontSize: 23),
            ),
            GestureDetector(
              onTap: startGame,
              child: const Text("P L A Y", style: TextStyle(color: Colors.white, fontSize: 23)),
            ),
            GestureDetector(
              child: Icon(
                paused ? Icons.play_arrow : Icons.pause,
                color: paused ? const Color.fromARGB(255, 201, 148, 148) : Colors.white,
              ),
              onTap: () {
                if (!paused) {
                  paused = true;
                } else {
                  paused = false;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
