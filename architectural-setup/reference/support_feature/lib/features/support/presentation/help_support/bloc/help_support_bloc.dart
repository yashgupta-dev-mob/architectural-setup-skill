import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/usecases/usecase.dart';
import '../../../domain/usecases/get_cached_support_content.dart';
import '../../../domain/usecases/get_support_content.dart';
import 'help_support_event.dart';
import 'help_support_state.dart';

export 'help_support_event.dart';
export 'help_support_state.dart';

/// Owns the Help & Support page: the saved content first, then the
/// server's.
class HelpSupportBloc extends Bloc<HelpSupportEvent, HelpSupportState> {
  HelpSupportBloc({
    required GetCachedSupportContent getCachedSupportContent,
    required GetSupportContent getSupportContent,
  }) : _getCached = getCachedSupportContent,
       _getContent = getSupportContent,
       super(const HelpSupportState()) {
    on<HelpSupportStarted>(_onStarted);
    on<HelpSupportRefreshed>((event, emit) => _refresh(emit));
  }

  final GetCachedSupportContent _getCached;
  final GetSupportContent _getContent;

  Future<void> _onStarted(
    HelpSupportStarted event,
    Emitter<HelpSupportState> emit,
  ) async {
    final cached = await _getCached(const NoParams());
    cached.match((_) {}, (content) {
      if (content.isEmpty) return;
      emit(
        state.copyWith(
          status: HelpSupportStatus.loaded,
          content: content,
          isStale: true,
        ),
      );
    });
    await _refresh(emit);
  }

  Future<void> _refresh(Emitter<HelpSupportState> emit) async {
    if (state.isBusy) return;
    final hasContent = state.status == HelpSupportStatus.loaded;
    emit(
      hasContent
          ? state.copyWith(isRefreshing: true, failure: () => null)
          : state.copyWith(
              status: HelpSupportStatus.loading,
              failure: () => null,
            ),
    );

    final result = await _getContent(const NoParams());
    result.match(
      (failure) => emit(
        hasContent
            ? state.copyWith(isRefreshing: false, failure: () => failure)
            : state.copyWith(
                status: HelpSupportStatus.failure,
                failure: () => failure,
              ),
      ),
      (content) => emit(
        state.copyWith(
          status: HelpSupportStatus.loaded,
          content: content,
          isStale: false,
          isRefreshing: false,
        ),
      ),
    );
  }
}
