import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fatelinkfe/data/repositories/home_repository.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository homeRepository;

  HomeBloc({required this.homeRepository}) : super(const HomeState()) {
    on<LoadRecommendationsEvent>(_onLoadRecommendations);
    on<RefreshRecommendationsEvent>(_onRefreshRecommendations);
  }

  Future<void> _onLoadRecommendations(
    LoadRecommendationsEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));
    try {
      final users = await homeRepository.fetchRecommendations(
        context: event.context,
      );
      emit(state.copyWith(status: HomeStatus.loaded, matchedUsers: users));
    } catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: "Lỗi tải danh sách tương hợp",
        ),
      );
    }
  }

  Future<void> _onRefreshRecommendations(
    RefreshRecommendationsEvent event,
    Emitter<HomeState> emit,
  ) async {
    // Khi kéo xuống Refresh, ta không đổi status thành Loading nữa để tránh bị chớp xóa màn hình,
    // vì RefreshIndicator đã có sẵn animation xoay tròn rồi.
    try {
      final users = await homeRepository.fetchRecommendations(
        context: event.context,
      );
      emit(state.copyWith(status: HomeStatus.loaded, matchedUsers: users));
    } catch (e) {
      emit(
        state.copyWith(
          status: HomeStatus.error,
          errorMessage: "Không thể làm mới danh sách",
        ),
      );
    }
  }
}
