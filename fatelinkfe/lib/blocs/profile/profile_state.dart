import 'package:equatable/equatable.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> profileData;
  const ProfileLoaded(this.profileData);
  @override
  List<Object> get props => [profileData];
}
