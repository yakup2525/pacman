import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pacman/feature/game/cubit/_cubit.dart';
import '/core/core.dart';
import '/feature/feature.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '/core/monetization/monetization_service.dart';
import '/core/update/update_service.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with WidgetsBindingObserver {
  late GameCubit gameCubit;
  late double _mapWidth;

  @override
  void initState() {
    gameCubit = BlocProvider.of<GameCubit>(context);

    WidgetsBinding.instance.addObserver(this);
    MonetizationService.instance.addListener(_privacyChanged);
    gameCubit.gameInitial();
    super.initState();
  }

  void _privacyChanged() {
    if (MonetizationService.instance.privacyUiActive && !gameCubit.preGame) {
      gameCubit.paused = true;
    }
  }

  @override
  void dispose() {
    MonetizationService.instance.removeListener(_privacyChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    MonetizationService.instance.foreground = resumed;
    if (!resumed && !gameCubit.preGame) gameCubit.paused = true;
    if (resumed) {
      MonetizationService.instance.preload();
      if (gameCubit.preGame) {
        MonetizationService.instance.retryConsentIfNeeded();
      }
    }
  }

  Future<void> _settings() async {
    if (!gameCubit.preGame) gameCubit.paused = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Settings & privacy'),
        content: ListenableBuilder(
          listenable: MonetizationService.instance,
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: () async {
                  var opened = false;
                  try {
                    opened = await launchUrl(
                      Uri.parse(privacyPolicyUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {
                    /* Report failure. */
                  }
                  if (!opened && dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Could not open the policy. Please try again.',
                        ),
                      ),
                    );
                  }
                },
              ),
              if (MonetizationService.instance.privacyRequired)
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text('Privacy Choices'),
                  onTap: () async {
                    final success = await MonetizationService.instance
                        .privacyChoices();
                    if (!success && dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Privacy choices are unavailable. Please try again.',
                          ),
                        ),
                      );
                    }
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _mapWidth = (MediaQuery.of(context).size.height * 6 / 7 - 19) / 18 * 11;
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
              return const Center(child: CircularProgressIndicator());
            } else if (state is SuccessState) {
              return Column(
                children: [
                  // _levelIndicator(),
                  _gameMap(context),
                  _dashboard(),
                ],
              );
            } else if (state is ErrorState) {
              return const Center(child: Text('Error'));
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
    );
  }

  //UI

  // ignore: unused_element
  Widget _levelIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              gameCubit.changeToPreviousLevel();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_ios,
                color: gameCubit.currentLevel > 1
                    ? Colors.white
                    : Colors.grey.shade700,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "LEVEL ${gameCubit.currentLevel}",
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              gameCubit.changeToNextLevel();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_forward_ios,
                color: gameCubit.currentLevel < 3
                    ? Colors.white
                    : Colors.grey.shade700,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isPortal(int index) {
    if (!gameCubit.portalOpen) return false;

    final int portalPos;
    switch (gameCubit.currentLevel) {
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

    return index == portalPos;
  }

  Widget _buildPortal() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.purple.shade300,
            Colors.blue.shade400,
            Colors.cyan.shade300,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.stars, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _gameMap(BuildContext context) {
    return Expanded(
      flex: 6,
      child: SizedBox(
        width: _mapWidth,
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
                    color: Colors.yellow,
                    shape: BoxShape.circle,
                  ),
                );
              } else if (gameCubit.player == index) {
                switch (gameCubit.direction) {
                  case "left":
                    return Transform.rotate(angle: pi, child: const MyPlayer());
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
                return Barrier(barrierColor: Colors.blue.shade800);
              } else if (_isPortal(index)) {
                return _buildPortal();
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
            IconButton(
              tooltip: "Settings & privacy",
              onPressed: _settings,
              icon: const Icon(Icons.settings, color: Colors.white),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  "Score: ${gameCubit.score}",
                  style: const TextStyle(color: Colors.white, fontSize: 23),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                if (!MonetizationService.instance.privacyUiActive) {
                  gameCubit.startGame(context);
                }
              },
              style: TextButton.styleFrom(
                minimumSize: const Size(80, 48),
                foregroundColor: Colors.white,
              ),
              child: const Text("P L A Y", style: TextStyle(fontSize: 23)),
            ),
            IconButton(
              tooltip: gameCubit.paused ? 'Resume game' : 'Pause game',
              icon: Icon(
                gameCubit.paused ? Icons.play_arrow : Icons.pause,
                color: gameCubit.paused
                    ? const Color.fromARGB(255, 201, 148, 148)
                    : Colors.white,
              ),
              onPressed: () {
                if (MonetizationService.instance.privacyUiActive) return;
                gameCubit.paused = !gameCubit.paused;
              },
            ),
          ],
        ),
      ),
    );
  }

  //
}
