import 'package:equatable/equatable.dart';
import '../../../screens/matches_screen.dart';

abstract class MatchesEvent extends Equatable {
  const MatchesEvent();

  @override
  List<Object> get props => [];
}

class LoadMatches extends MatchesEvent {}

class LoadMoreMatches extends MatchesEvent {}

class UnmatchUserEvent extends MatchesEvent {
  final MatchedUser user;
  const UnmatchUserEvent(this.user);
}