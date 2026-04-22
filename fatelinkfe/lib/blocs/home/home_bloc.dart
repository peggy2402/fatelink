import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_event.dart';
import 'home_state.dart';
import '../../repositories/home_repository.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository repository;

  HomeBloc({required this.repository}) : super(HomeInitial()) {
    on<LoadHomeUsers>(_onLoadHomeUsers);
    on<LoadMoreHomeUsers>(_onLoadMoreHomeUsers);
  }

  Future<void> _onLoadHomeUsers(
    LoadHomeUsers event,
    Emitter<HomeState> emit,
  ) async {
    emit(HomeLoading());
    try {
      final users = await repository.fetchRecommendations(
        page: 1,
        context: event.context,
      );
      emit(HomeLoaded(users: users, page: 1, hasMore: users.length >= 10));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> _onLoadMoreHomeUsers(
    LoadMoreHomeUsers event,
    Emitter<HomeState> emit,
  ) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      if (!currentState.hasMore || currentState.isLoadingMore) return;

      emit(
        HomeLoaded(
          users: currentState.users,
          page: currentState.page,
          hasMore: currentState.hasMore,
          isLoadingMore: true,
        ),
      );
      try {
        final newUsers = await repository.fetchRecommendations(
          page: currentState.page + 1,
          context: event.context,
        );
        emit(
          HomeLoaded(
            users: currentState.users + newUsers,
            page: currentState.page + 1,
            hasMore: newUsers.length >= 10,
            isLoadingMore: false,
          ),
        );
      } catch (e) {
        emit(
          HomeLoaded(
            users: currentState.users,
            page: currentState.page,
            hasMore: false,
            isLoadingMore: false,
          ),
        );
      }
    }
  }
}
