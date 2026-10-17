import 'package:equatable/equatable.dart';

import '../../../../../core/app/failure.dart';
import '../../../domain/entities/support_content.dart';

/// `loading` and `failure` mean there is nothing to show; once content is
/// on screen the status stays `loaded`, whatever a refresh does.
enum HelpSupportStatus { initial, loading, loaded, failure }

class HelpSupportState extends Equatable {
  const HelpSupportState({
    this.status = HelpSupportStatus.initial,
    this.content = const SupportContent(),
    this.failure,
    this.isStale = false,
    this.isRefreshing = false,
  });

  final HelpSupportStatus status;

  /// The channels and questions on screen.
  final SupportContent content;

  /// Why the last load failed.
  final Failure? failure;

  /// [content] is the saved copy, not yet replaced by the server's.
  final bool isStale;

  /// The server is being asked behind content on screen.
  final bool isRefreshing;

  bool get isLoading => status == HelpSupportStatus.loading;

  bool get isBusy => isLoading || isRefreshing;

  HelpSupportState copyWith({
    HelpSupportStatus? status,
    SupportContent? content,
    Failure? Function()? failure,
    bool? isStale,
    bool? isRefreshing,
  }) {
    return HelpSupportState(
      status: status ?? this.status,
      content: content ?? this.content,
      failure: failure != null ? failure() : this.failure,
      isStale: isStale ?? this.isStale,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [status, content, failure, isStale, isRefreshing];
}
