import 'package:equatable/equatable.dart';
import '../../../screens/matches_screen.dart'; // Nơi chứa class MatchedUser

abstract class MatchesState extends Equatable {
  const MatchesState();

  @override
  List<Object> get props => [];
}

class MatchesInitial extends MatchesState {}

class MatchesLoading extends MatchesState {}

class MatchesLoaded extends MatchesState {
  final List<MatchedUser> matches;
  final bool hasMore;
  final int page;
  final bool isLoadingMore;

  const MatchesLoaded({
    required this.matches,
    required this.hasMore,
    required this.page,
    required this.isLoadingMore,
  });

  @override
  List<Object> get props => [matches, hasMore, page, isLoadingMore];
}

class MatchesError extends MatchesState {
  final String message;
  const MatchesError(this.message);
}
