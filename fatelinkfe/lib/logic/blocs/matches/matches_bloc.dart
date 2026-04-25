import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../presentation/screens/matches_screen.dart'; // Lấy MatchedUser
import 'matches_event.dart';
import 'matches_state.dart';
import '../../../data/repositories/matches_repository.dart';

class MatchesBloc extends Bloc<MatchesEvent, MatchesState> {
  final MatchesRepository repository;

  MatchesBloc({required this.repository}) : super(MatchesInitial()) {
    on<LoadMatches>(_onLoadMatches);
    on<LoadMoreMatches>(_onLoadMoreMatches);
    on<UnmatchUserEvent>(_onUnmatchUser);
  }

  Future<void> _onLoadMatches(
    LoadMatches event,
    Emitter<MatchesState> emit,
  ) async {
    emit(MatchesLoading());
    try {
      final matches = await repository.fetchMatches(page: 1);
      emit(
        MatchesLoaded(
          matches: matches,
          hasMore: matches.length >= 10,
          page: 1,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(MatchesError(e.toString()));
    }
  }

  Future<void> _onLoadMoreMatches(
    LoadMoreMatches event,
    Emitter<MatchesState> emit,
  ) async {
    if (state is MatchesLoaded) {
      final currentState = state as MatchesLoaded;
      if (!currentState.hasMore || currentState.isLoadingMore) return;

      emit(
        MatchesLoaded(
          matches: currentState.matches,
          hasMore: currentState.hasMore,
          page: currentState.page,
          isLoadingMore: true, // Kích hoạt loading bottom
        ),
      );

      try {
        final newMatches = await repository.fetchMatches(
          page: currentState.page + 1,
        );
        emit(
          MatchesLoaded(
            matches: currentState.matches + newMatches,
            hasMore: newMatches.length >= 10,
            page: currentState.page + 1,
            isLoadingMore: false,
          ),
        );
      } catch (e) {
        // Nếu lỗi, trả về state cũ
        emit(
          MatchesLoaded(
            matches: currentState.matches,
            hasMore: false,
            page: currentState.page,
            isLoadingMore: false,
          ),
        );
      }
    }
  }

  Future<void> _onUnmatchUser(
    UnmatchUserEvent event,
    Emitter<MatchesState> emit,
  ) async {
    if (state is MatchesLoaded) {
      final currentState = state as MatchesLoaded;
      // Xóa user khỏi danh sách để UI update ngay lập tức (Optimistic UI)
      final updatedMatches = currentState.matches
          .where((u) => u.id != event.user.id)
          .toList();
      emit(
        MatchesLoaded(
          matches: updatedMatches,
          hasMore: currentState.hasMore,
          page: currentState.page,
          isLoadingMore: currentState.isLoadingMore,
        ),
      );
      // TODO: Call API unmatch ở đây
    }
  }
}
