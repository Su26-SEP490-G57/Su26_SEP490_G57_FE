/// Generic API response wrapper — mirrors BE response shape
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  final bool success;
  final String message;
  final T? data;
  final List<String>? errors;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.pageSize,
  });

  final List<T> items;
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final int pageSize;

  bool get hasNextPage => currentPage < totalPages;
  bool get hasPreviousPage => currentPage > 1;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      items: (json['items'] as List<dynamic>)
          .map((e) => fromJsonT(e as Map<String, dynamic>))
          .toList(),
      totalItems: json['totalItems'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }
}
