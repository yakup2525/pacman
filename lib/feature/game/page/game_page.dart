import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pacman/feature/game/cubit/_cubit.dart';
import '/core/core.dart';
import '/feature/feature.dart';
import 'dart:math';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late GameCubit gameCubit;

  @override
  void initState() {
    gameCubit = BlocProvider.of<GameCubit>(context);
    gameCubit.mapWidth =
        (MediaQuery.of(context).size.height * 6 / 7 - 19) / 18 * 11;

    gameCubit.gameInitial();
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
        width: gameCubit.mapWidth,
        child: GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.delta.dy > 0) {
              gameCubit.direction = "down";
            } else if (details.delta.dy < 0) {
              gameCubit.direction = "up";
            }
          },
          onHorizontalDragUpdate: (details) {
            if (details.delta.dx > 0) {
              gameCubit.direction = "right";
            } else if (details.delta.dx < 0) {
              gameCubit.direction = "left";
            }
          },
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gameCubit.numberOfSquares,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: AppConstants.numberInRow,
            ),
            itemBuilder: (BuildContext context, int index) {
              if (gameCubit.mouthClosed && gameCubit.player == index) {
                return Container(
                  decoration: const BoxDecoration(
                      color: Colors.yellow, shape: BoxShape.circle),
                );
              } else if (gameCubit.player == index) {
                switch (gameCubit.direction) {
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
              } else if (gameCubit.ghost == index) {
                return const BlueGhost();
              } else if (gameCubit.ghost2 == index) {
                return const RedGhost();
              } else if (gameCubit.ghost3 == index) {
                return const YellowGhost();
              } else if (gameCubit.barriers.contains(index)) {
                return Barrier(
                  barrierColor: Colors.blue.shade800,
                );
              } else if (gameCubit.preGame || gameCubit.food.contains(index)) {
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
              " Score : ${gameCubit.score}",
              style: const TextStyle(color: Colors.white, fontSize: 23),
            ),
            GestureDetector(
              onTap: () {
                gameCubit.startGame(context);
              },
              child: const Text("P L A Y",
                  style: TextStyle(color: Colors.white, fontSize: 23)),
            ),
            GestureDetector(
              child: Icon(
                gameCubit.paused ? Icons.play_arrow : Icons.pause,
                color: gameCubit.paused
                    ? const Color.fromARGB(255, 201, 148, 148)
                    : Colors.white,
              ),
              onTap: () {
                if (!gameCubit.paused) {
                  gameCubit.paused = true;
                } else {
                  gameCubit.paused = false;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
//
}
