import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pacman/feature/game/cubit/_cubit.dart';
import '/core/core.dart';
import '/feature/feature.dart';
import 'dart:async';
import 'dart:math';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  static const int _numberInRow = 11;
  final int _numberOfSquares = _numberInRow * 18;

  late double _mapWidth;
  int _player = _numberInRow * 14 + 1;
  int _ghost = _numberInRow * 2 - 2;
  int _ghost2 = _numberInRow * 9 - 8;
  int _ghost3 = _numberInRow * 11 - 2;
  bool _preGame = true;
  bool _mouthClosed = false;
  int _score = 0;
  bool _paused = false;
  final List<int> _food = [];
  String _direction = "right";
  String _ghostLast = "left";
  String _ghostLast2 = "left";
  String _ghostLast3 = "down";

  List<int> _barriers = Level1.barriers;

  late GameCubit gameCubit;

  @override
  void initState() {
    _mapWidth = (MediaQuery.of(context).size.height * 6 / 7 - 19) / 18 * 11;

    gameCubit = BlocProvider.of<GameCubit>(context);
    gameCubit.gameStart();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<GameCubit, AppState>(
          builder: (context, state) {
            if (state is InitialState) {
              return const SizedBox();
            } else if (state is LoadingState) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is SuccessState) {
              return Column(
                children: [
                  _gameMap(context),
                  _dashboard(),
                ],
              );
            } else if (state is ErrorState) {
              return const Center(
                child: Text('Error'),
              );
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }

//UI
  Widget _gameMap(BuildContext context) {
    return Expanded(
      flex: 6,
      child: SizedBox(
        width: _mapWidth,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              _direction = "down";
            } else if (details.delta.dy < 0) {
              _direction = "up";
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0) {
              _direction = "right";
            } else if (details.delta.dx < 0) {
              _direction = "left";
            }
          },
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _numberOfSquares,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _numberInRow,
            ),
            itemBuilder: (BuildContext context, int index) {
              if (_mouthClosed && _player == index) {
                return Container(
                  decoration: const BoxDecoration(
                      color: Colors.yellow, shape: BoxShape.circle),
                );
              } else if (_player == index) {
                switch (_direction) {
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
              } else if (_ghost == index) {
                return const BlueGhost();
              } else if (_ghost2 == index) {
                return const RedGhost();
              } else if (_ghost3 == index) {
                return const YellowGhost();
              } else if (_barriers.contains(index)) {
                return Barrier(
                  barrierColor: Colors.blue.shade800,
                );
              } else if (_preGame || _food.contains(index)) {
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
              " Score : $_score",
              style: const TextStyle(color: Colors.white, fontSize: 23),
            ),
            GestureDetector(
              onTap: _startGame,
              child: const Text("P L A Y",
                  style: TextStyle(color: Colors.white, fontSize: 23)),
            ),
            GestureDetector(
              child: Icon(
                _paused ? Icons.play_arrow : Icons.pause,
                color: _paused
                    ? const Color.fromARGB(255, 201, 148, 148)
                    : Colors.white,
              ),
              onTap: () {
                if (!_paused) {
                  _paused = true;
                } else {
                  _paused = false;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
//

// Functions
  void _startGame() {
    if (_preGame) {
      _preGame = false;
      _getFood();

      Timer.periodic(const Duration(milliseconds: 10), (timer) {
        if (_player == _ghost || _player == _ghost2 || _player == _ghost3) {
          setState(() {
            _player = -1;
          });
          showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Center(child: Text("Game Over!")),
                  content: Text("Your Score :  $_score"),
                  actions: [
                    MaterialButton(
                      onPressed: () {
                        setState(() {
                          _player = _numberInRow * 14 + 1;
                          _ghost = _numberInRow * 2 - 2;
                          _ghost2 = _numberInRow * 9 - 1;
                          _ghost3 = _numberInRow * 11 - 2;
                          _paused = false;
                          _preGame = false;
                          _mouthClosed = false;
                          _direction = "right";
                          _food.clear();
                          _getFood();
                          _score = 0;
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
        if (!_paused) {
          _moveGhost(_ghost, _ghostLast, (newGhost, newGhostlast) {
            setState(() {
              _ghost = newGhost;
              _ghostLast = newGhostlast;
            });
          });
          _moveGhost(_ghost2, _ghostLast2, (newGhost2, newGhostlast2) {
            setState(() {
              _ghost2 = newGhost2;
              _ghostLast2 = newGhostlast2;
            });
          });
          _moveGhost(_ghost3, _ghostLast3, (newGhost3, newGhostlast3) {
            setState(() {
              _ghost3 = newGhost3;
              _ghostLast3 = newGhostlast3;
            });
          }, dontFollow: true);
        }
      });
      Timer.periodic(const Duration(milliseconds: 170), (timer) {
        setState(() {
          _mouthClosed = !_mouthClosed;
        });
        if (_food.contains(_player)) {
          setState(() {
            _food.remove(_player);
          });
          _score++;
        }

        switch (_direction) {
          case "left":
            if (!_paused) _moveLeft();
            break;
          case "right":
            if (!_paused) _moveRight();
            break;
          case "up":
            if (!_paused) _moveUp();
            break;
          case "down":
            if (!_paused) _moveDown();
            break;
        }
      });
    }
  }

  void _getFood() {
    for (int i = 0; i < _numberOfSquares; i++) {
      if (!_barriers.contains(i)) {
        _food.add(i);
      }
    }
  }

  void _moveLeft() {
    if (!_barriers.contains(_player - 1)) {
      setState(() {
        _player--;
      });
    }
  }

  void _moveRight() {
    if (!_barriers.contains(_player + 1)) {
      setState(() {
        _player++;
      });
    }
  }

  void _moveUp() {
    if (!_barriers.contains(_player - _numberInRow)) {
      setState(() {
        _player -= _numberInRow;
      });
    }
  }

  void _moveDown() {
    if (!_barriers.contains(_player + _numberInRow)) {
      setState(() {
        _player += _numberInRow;
      });
    }
  }

  void _moveGhost(
      int ghost, String ghostLast, Function(int, String) updateState,
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
          if (_player < 100) {
            possibleDirections.add("up");
          } else {
            possibleDirections.add("down");
          }
        }

        final playerPos = _player.toString();
        if (playerPos.length == 2) {
          if (_player > 10 && random.nextDouble() < 0.7) {
            if (int.parse(playerPos[1]) - int.parse(playerPos[1]) < 6) {
              possibleDirections.add("left");
            } else {
              possibleDirections.add("right");
            }
          }
        }
      }

      // Yan yönleri kontrol et
      bool canGoLeft = !_barriers.contains(ghost - 1);
      bool canGoRight = !_barriers.contains(ghost + 1);
      bool canGoUp = !_barriers.contains(ghost - _numberInRow);
      bool canGoDown = !_barriers.contains(ghost + _numberInRow);

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
            newGhost -= _numberInRow;
            moved = true;
          }
          break;
        case "down":
          if (canGoDown) {
            newGhost += _numberInRow;
            moved = true;
          }
          break;
      }
    }

    updateState(newGhost, newGhostLast);
  }
//
}
