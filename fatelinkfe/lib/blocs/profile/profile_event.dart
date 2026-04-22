import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  final BuildContext context;
  const LoadProfileEvent(this.context);
}
