import 'package:equatable/equatable.dart';

abstract class MainEvent extends Equatable {
  const MainEvent();
  @override
  List<Object> get props => [];
}

class InitMainEvent extends MainEvent {}

class ChangeTabEvent extends MainEvent {
  final int tabIndex;
  const ChangeTabEvent(this.tabIndex);

  @override
  List<Object> get props => [tabIndex];
}
