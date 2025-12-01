import 'package:equatable/equatable.dart';
import 'package:ommo/services/hive/recent_search/model/recent_search_model.dart';

class RecentSearchState extends Equatable {
  final List<RecentSearchModel> searches;
  final bool isLoading;

  const RecentSearchState({this.searches = const [], this.isLoading = false});

  RecentSearchState copyWith({
    List<RecentSearchModel>? searches,
    bool? isLoading,
  }) {
    return RecentSearchState(
      searches: searches ?? this.searches,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [searches, isLoading];
}
