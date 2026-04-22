import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
}

class HomeLoaded extends HomeState {
  final List<dynamic> users;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const HomeLoaded({
    required this.users,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
  });
  @override
  List<Object> get props => [users, page, hasMore, isLoadingMore];
}
