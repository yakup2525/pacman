import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:pacman/feature/game/cubit/_cubit.dart';

import 'feature/feature.dart';

void main() {
  // Initialize Marionette only in debug mode
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocProvider(
        create: (_) => GameCubit(),
        child: const GamePage(),
      ),
    );
  }
}
