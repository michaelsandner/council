import 'package:equatable/equatable.dart';

class VoteResult extends Equatable {
  const VoteResult({
    required this.summary,
    this.inFavour,
    this.against,
    this.present,
  });

  final String summary;
  final int? inFavour;
  final int? against;
  final int? present;

  bool get hasCounts => inFavour != null || against != null;

  @override
  List<Object?> get props => [summary, inFavour, against, present];
}
