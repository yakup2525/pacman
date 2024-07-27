import 'package:flutter_bloc/flutter_bloc.dart';

import '/core/core.dart';

base class BaseCubit<T> extends Cubit<AppState> {
  BaseCubit(super.initialState);

  void safeEmit(T state) {
    if (isClosed) return;
    emit(state as AppState);
  }
}
