import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object> get props => [];
}

class LoadHomeUsers extends HomeEvent {
  final BuildContext context;
  const LoadHomeUsers(this.context);
}

class LoadMoreHomeUsers extends HomeEvent {
  final BuildContext context;
  const LoadMoreHomeUsers(this.context);
}
