import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import '../../../data/repositories/profile_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository repository;

  ProfileBloc({required this.repository}) : super(ProfileInitial()) {
    on<LoadProfileEvent>(_onLoadProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final rawData = await repository.fetchUserProfile(event.context);
      
      // Chuẩn hoá dữ liệu ngay tại Bloc: bóc tách lớp vỏ 'data' từ NestJS Backend
      final userData = rawData['data'] ?? rawData['user'] ?? rawData;
      emit(ProfileLoaded(userData));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}
