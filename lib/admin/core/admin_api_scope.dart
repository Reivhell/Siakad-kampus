import 'package:flutter/widgets.dart';

import '../../shared/api_client.dart';
import '../../shared/auth_service.dart';

class AdminApiScope extends InheritedWidget {
  const AdminApiScope({
    super.key,
    required this.apiClient,
    required this.auth,
    required this.userLabel,
    required super.child,
  });

  final ApiClient? apiClient;
  final AuthService? auth;
  final String userLabel;

  static AdminApiScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminApiScope>();

  static ApiClient? clientOf(BuildContext context) => maybeOf(context)?.apiClient;

  @override
  bool updateShouldNotify(AdminApiScope oldWidget) =>
      apiClient != oldWidget.apiClient ||
      auth != oldWidget.auth ||
      userLabel != oldWidget.userLabel;
}
