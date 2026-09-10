import 'package:equatable/equatable.dart';

enum MeetingDocumentKind { announcement, minutes }

class MeetingDocument extends Equatable {
  const MeetingDocument({
    required this.id,
    required this.kind,
    required this.label,
    required this.sourceUrl,
  });

  final String id;
  final MeetingDocumentKind kind;
  final String label;
  final String sourceUrl;

  @override
  List<Object?> get props => [id, kind, label, sourceUrl];
}
