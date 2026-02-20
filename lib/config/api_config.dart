class ApiConfig {
  static const String baseUrl = 'https://api.ibola.uz';

  // Auth
  static const String login = '/admin/login';

  // Stats
  static const String stats = '/admin/stats';

  // Users
  static const String users = '/admin/users';

  // Products
  static const String products = '/admin/products';
  static String product(int id) => '/admin/products/$id';

  // Categories
  static const String categories = '/admin/categories';
  static String category(int id) => '/admin/categories/$id';

  // Orders
  static const String orders = '/admin/orders';
  static String orderStatus(int id) => '/admin/orders/$id/status';

  // Notifications
  static const String notificationsBroadcast = '/admin/notifications/broadcast';

  // Media
  static const String mediaUpload = '/admin/media/upload';
}
