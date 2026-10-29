import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:pacman/feature/game/cubit/_cubit.dart';

import 'feature/feature.dart';
import 'core/monetization/monetization_service.dart';
import 'core/update/update_service.dart';
import 'core/update/update_gate.dart';

void main() {
  // Initialize Marionette only in debug mode
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initializeServices = true});
  final bool initializeServices;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final navigatorKey = GlobalKey<NavigatorState>();
  final updates = UpdateService();
  final game = GameCubit();
  @override
  void initState() {
    super.initState();
    if (widget.initializeServices) {
      WidgetsBinding.instance.addObserver(this);
      updates.addListener(_updateChanged);
      updates.check();
      MonetizationService.instance.start();
    }
  }

  void _updateChanged() {
    MonetizationService.instance.blocked = updates.mandatory;
    if (updates.mandatory) {
      if (!game.preGame) game.paused = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          navigatorKey.currentState?.popUntil((route) => route.isFirst);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    MonetizationService.instance.foreground =
        state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) updates.check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    updates.removeListener(_updateChanged);
    game.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: BlocProvider.value(
        value: game,
        child: widget.initializeServices
            ? UpdateGate(service: updates, child: const GamePage())
            : const GamePage(),
      ),
    );
  }
}
