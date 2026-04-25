import 'package:fatelinkfe/data/models/match_user.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final List<MatchUser> matchedUsers;
  final String errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.matchedUsers = const [],
    this.errorMessage = '',
  });

  HomeState copyWith({
    HomeStatus? status,
    List<MatchUser>? matchedUsers,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      matchedUsers: matchedUsers ?? this.matchedUsers,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
