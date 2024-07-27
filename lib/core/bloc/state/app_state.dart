// ignore: depend_on_referenced_packages
import 'package:equatable/equatable.dart';

abstract class AppState<T> extends Equatable {
  const AppState();

  @override
  List<Object?> get props => [];
}

class InitialState<T> extends AppState<T> {
  final T? param;
  const InitialState({this.param});
  @override
  List<Object?> get props => [param];
}

class LoadingState<T> extends AppState<T> {
  final T? param;
  const LoadingState({this.param});
  @override
  List<Object?> get props => [param];
}

class SuccessState<T> extends AppState<T> {
  final T? param;
  const SuccessState({this.param});
  @override
  List<Object?> get props => [param];
}

class ErrorState<AppError> extends AppState<AppError> {
  final AppError error;
  const ErrorState(this.error);

  @override
  List<Object?> get props => [error];
}
