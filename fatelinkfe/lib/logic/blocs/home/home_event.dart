import 'package:flutter/material.dart';

abstract class HomeEvent {}

class LoadRecommendationsEvent extends HomeEvent {
  final BuildContext context;
  LoadRecommendationsEvent(this.context);
}

class RefreshRecommendationsEvent extends HomeEvent {
  final BuildContext context;
  RefreshRecommendationsEvent(this.context);
}