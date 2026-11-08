// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paged.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PageMeta _$PageMetaFromJson(Map<String, dynamic> json) => PageMeta(
  limit: (json['limit'] as num).toInt(),
  offset: (json['offset'] as num).toInt(),
  total: (json['total'] as num).toInt(),
  hasMore: json['hasMore'] as bool,
  nextCursor: json['nextCursor'] as String?,
);
