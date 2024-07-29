import '/core/core.dart';

final class GameCubit extends BaseCubit<AppState> {
  GameCubit() : super(const InitialState());

  void gameStart() {
    safeEmit(const SuccessState());
  }

  void setGame() {
    safeEmit(const InitialState());
    safeEmit(const SuccessState());
  }
}
