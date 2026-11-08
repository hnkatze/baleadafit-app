import 'package:json_annotation/json_annotation.dart';

part 'paged.g.dart';

/// Pagination metadata the API sends next to a list payload.
@JsonSerializable(createToJson: false)
class PageMeta {
  const PageMeta({
    required this.limit,
    required this.offset,
    required this.total,
    required this.hasMore,
    this.nextCursor,
  });

  factory PageMeta.fromJson(Map<String, dynamic> json) =>
      _$PageMetaFromJson(json);

  final int limit;
  final int offset;
  final int total;
  final bool hasMore;
  final String? nextCursor;
}

/// A page of [T] plus the [meta] the API returns with it.
class Paged<T> {
  const Paged({required this.items, required this.meta});

  final List<T> items;
  final PageMeta meta;
}
