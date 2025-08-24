import 'package:tripthread/models/user.dart';

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
    };
  }
}

class PaginatedUsers {
  final List<User> users;
  final Pagination pagination;

  const PaginatedUsers({
    required this.users,
    required this.pagination,
  });

  factory PaginatedUsers.fromJson(Map<String, dynamic> json) {
    return PaginatedUsers(
      users: (json['users'] as List).map((e) => User.fromJson(e)).toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'users': users.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}
