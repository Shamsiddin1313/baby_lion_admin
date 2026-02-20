import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _adminToken = '';

  void setToken(String token) {
    _adminToken = token;
  }

  String get token => _adminToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Admin-Token': _adminToken,
      };

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: queryParams);
  }

  // ========================
  // Auth
  // ========================

  Future<bool> login(String token) async {
    _adminToken = token;
    final response = await http.post(
      _uri(ApiConfig.login),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return true;
    }
    _adminToken = '';
    return false;
  }

  // ========================
  // Stats
  // ========================

  Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(_uri(ApiConfig.stats), headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load stats: ${response.statusCode}');
  }

  // ========================
  // Users
  // ========================

  Future<List<dynamic>> getUsers({int limit = 50, int offset = 0, String? search}) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    final response = await http.get(_uri(ApiConfig.users, params), headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load users: ${response.statusCode}');
  }

  // ========================
  // Products
  // ========================

  Future<List<dynamic>> getProducts({int limit = 50, int offset = 0, String? search, int? categoryId}) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['category_id'] = categoryId.toString();
    final response = await http.get(_uri(ApiConfig.products, params), headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load products: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri(ApiConfig.products),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create product: ${response.body}');
  }

  Future<void> updateProduct(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(ApiConfig.product(id)),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update product: ${response.body}');
    }
  }

  Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      _uri(ApiConfig.product(id)),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }

  // ========================
  // Categories
  // ========================

  Future<List<dynamic>> getCategories() async {
    final response = await http.get(_uri(ApiConfig.categories), headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load categories: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> createCategory(Map<String, dynamic> data) async {
    final response = await http.post(
      _uri(ApiConfig.categories),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create category: ${response.body}');
  }

  Future<void> updateCategory(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      _uri(ApiConfig.category(id)),
      headers: _headers,
      body: json.encode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update category: ${response.body}');
    }
  }

  Future<void> deleteCategory(int id) async {
    final response = await http.delete(
      _uri(ApiConfig.category(id)),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }

  // ========================
  // Orders
  // ========================

  Future<List<dynamic>> getOrders({int limit = 50, int offset = 0, String? status}) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null && status.isNotEmpty) params['status'] = status;
    final response = await http.get(_uri(ApiConfig.orders, params), headers: _headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load orders: ${response.statusCode}');
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    final response = await http.put(
      _uri(ApiConfig.orderStatus(orderId), {'status': status}),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update order status: ${response.body}');
    }
  }

  // ========================
  // Notifications
  // ========================

  Future<Map<String, dynamic>> broadcastNotification(String title, String message) async {
    final response = await http.post(
      _uri(ApiConfig.notificationsBroadcast, {'title': title, 'message': message}),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to send notification: ${response.body}');
  }

  // ========================
  // Media Upload
  // ========================

  Future<Map<String, dynamic>> uploadImage(List<int> bytes, String filename) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mediaUpload}');
    final request = http.MultipartRequest('POST', uri);
    request.headers['X-Admin-Token'] = _adminToken;
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
      contentType: MediaType('image', filename.split('.').last),
    ));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to upload image: ${response.body}');
  }
}
