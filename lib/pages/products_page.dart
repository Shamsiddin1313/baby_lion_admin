import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List<dynamic> _products = [];
  List<dynamic> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService().getProducts(limit: 200),
        ApiService().getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _products = results[0];
        _categories = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _addProduct() {
    showDialog(
      context: context,
      builder: (_) => ProductDialog(
        categories: _categories,
        onSave: (data) async {
          try {
            await ApiService().createProduct(data);
            _loadData();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (_) => ProductDialog(
        product: product,
        categories: _categories,
        onSave: (data) async {
          try {
            await ApiService().updateProduct(product['id'], data);
            _loadData();
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _deleteProduct(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService().deleteProduct(id);
                _loadData();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _categoryName(int? categoryId) {
    if (categoryId == null) return '-';
    final cat = _categories.where((c) => c['id'] == categoryId).firstOrNull;
    return cat?['name'] ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Products', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text('${_products.length} products', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData, tooltip: 'Refresh'),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Image')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Count')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Rating')),
                      DataColumn(label: Text('Recommended')),
                      DataColumn(label: Text('Out of Stock')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _products.map((p) {
                      final product = Map<String, dynamic>.from(p);
                      final imageUrl = product['image'] as String?;
                      return DataRow(cells: [
                        DataCell(Text('${product['id']}')),
                        DataCell(
                          imageUrl != null && imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    imageUrl.startsWith('http') ? imageUrl : '${ApiConfig.baseUrl}$imageUrl',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                                  ),
                                )
                              : const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                        ),
                        DataCell(Text(product['name'] ?? '')),
                        DataCell(Text('${product['price'] ?? 0}')),
                        DataCell(Text('${product['count'] ?? 0}')),
                        DataCell(Text(_categoryName(product['category_id']))),
                        DataCell(Text('${product['rating'] ?? 0}')),
                        DataCell(Icon(
                          product['recommended'] == true ? Icons.check : Icons.close,
                          color: product['recommended'] == true ? Colors.green : Colors.grey,
                        )),
                        DataCell(Icon(
                          product['out_of_stock'] == true ? Icons.warning : Icons.check,
                          color: product['out_of_stock'] == true ? Colors.red : Colors.green,
                        )),
                        DataCell(Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editProduct(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(product['id']),
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductDialog extends StatefulWidget {
  final Map<String, dynamic>? product;
  final List<dynamic> categories;
  final Function(Map<String, dynamic>) onSave;

  const ProductDialog({super.key, this.product, required this.categories, required this.onSave});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  late TextEditingController _nameController;
  late TextEditingController _nameUzController;
  late TextEditingController _nameRuController;
  late TextEditingController _priceController;
  late TextEditingController _countController;
  late TextEditingController _descriptionController;
  late TextEditingController _descriptionUzController;
  late TextEditingController _descriptionRuController;
  late TextEditingController _featuresController;
  late TextEditingController _ageOrSizeController;
  int? _categoryId;
  bool _recommended = false;

  // Image upload state
  int? _imageId;
  String? _imageUrl;
  PlatformFile? _pickedFile;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?['name'] ?? '');
    _nameUzController = TextEditingController(text: p?['name_uz'] ?? '');
    _nameRuController = TextEditingController(text: p?['name_ru'] ?? '');
    _priceController = TextEditingController(text: p?['price']?.toString() ?? '');
    _countController = TextEditingController(text: p?['count']?.toString() ?? '0');
    _descriptionController = TextEditingController(text: p?['description'] ?? '');
    _descriptionUzController = TextEditingController(text: p?['description_uz'] ?? '');
    _descriptionRuController = TextEditingController(text: p?['description_ru'] ?? '');
    final features = p?['features'];
    _featuresController = TextEditingController(
      text: features is List ? features.join(', ') : '',
    );
    _ageOrSizeController = TextEditingController(text: p?['age_or_size']?.toString() ?? '');
    _categoryId = p?['category_id'];
    _recommended = p?['recommended'] ?? false;
    _imageUrl = p?['image'];
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() {
      _pickedFile = file;
      _uploading = true;
    });

    try {
      final response = await ApiService().uploadImage(file.bytes!, file.name);
      if (!mounted) return;
      setState(() {
        _imageId = response['id'];
        _imageUrl = response['url'];
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image upload section
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: _uploading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildImagePreview(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickAndUploadImage,
                  icon: const Icon(Icons.upload),
                  label: Text(_imageUrl != null ? 'Change Image' : 'Upload Image'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _nameUzController, decoration: const InputDecoration(labelText: 'Name (UZ)'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _nameRuController, decoration: const InputDecoration(labelText: 'Name (RU)'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price *'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _countController, decoration: const InputDecoration(labelText: 'Count'), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                initialValue: _categoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...widget.categories.map((c) => DropdownMenuItem(
                        value: c['id'] as int,
                        child: Text(c['name'] ?? ''),
                      )),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _descriptionUzController, decoration: const InputDecoration(labelText: 'Description (UZ)'), maxLines: 2)),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _descriptionRuController, decoration: const InputDecoration(labelText: 'Description (RU)'), maxLines: 2)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _featuresController, decoration: const InputDecoration(labelText: 'Features (comma separated)')),
              const SizedBox(height: 12),
              TextField(controller: _ageOrSizeController, decoration: const InputDecoration(labelText: 'Age or Size'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Recommended'),
                value: _recommended,
                onChanged: (v) => setState(() => _recommended = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            final price = double.tryParse(_priceController.text);
            if (name.isEmpty || price == null || price <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name and valid price are required')),
              );
              return;
            }
            final features = _featuresController.text.trim().isEmpty
                ? <String>[]
                : _featuresController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
            final data = <String, dynamic>{
              'name': name,
              'price': price,
              'count': int.tryParse(_countController.text) ?? 0,
              'category_id': _categoryId,
              'description': _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
              'features': features,
              'recommended': _recommended,
              'age_or_size': int.tryParse(_ageOrSizeController.text),
            };
            if (_imageId != null) data['image_id'] = _imageId;
            final nameUz = _nameUzController.text.trim();
            final nameRu = _nameRuController.text.trim();
            final descUz = _descriptionUzController.text.trim();
            final descRu = _descriptionRuController.text.trim();
            if (nameUz.isNotEmpty) data['name_uz'] = nameUz;
            if (nameRu.isNotEmpty) data['name_ru'] = nameRu;
            if (descUz.isNotEmpty) data['description_uz'] = descUz;
            if (descRu.isNotEmpty) data['description_ru'] = descRu;

            Navigator.pop(context);
            widget.onSave(data);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    // Show picked file bytes if available
    if (_pickedFile?.bytes != null) {
      return Image.memory(_pickedFile!.bytes!, fit: BoxFit.contain);
    }
    // Show existing image URL
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      final url = _imageUrl!.startsWith('http') ? _imageUrl! : '${ApiConfig.baseUrl}$_imageUrl';
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.broken_image, size: 48, color: Colors.grey), Text('Failed to load')],
          ),
        ),
      );
    }
    // No image
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey),
          SizedBox(height: 8),
          Text('No image', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
