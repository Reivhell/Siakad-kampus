class Page<T> {
  const Page({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<T> items;
  final int total;
  final int page;
  final int limit;

  int get totalPages => limit == 0 ? 0 : (total + limit - 1) ~/ limit;

  Map<String, Object?> toJson(Object? Function(T) encode) => {
        'items': items.map(encode).toList(),
        'total': total,
        'page': page,
        'limit': limit,
        'total_pages': totalPages,
      };
}

class PageRequest {
  const PageRequest({this.page = 1, this.limit = 20, this.query});

  final int page;
  final int limit;
  final String? query;

  int get offset => (page - 1) * limit;

  PageRequest normalized() {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit.clamp(1, 100);
    return PageRequest(
      page: safePage,
      limit: safeLimit,
      query: query?.trim().isEmpty ?? true ? null : query!.trim(),
    );
  }
}
