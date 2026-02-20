import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  List<dynamic> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = await ApiService().getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
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

  void _addCategory() {
    showDialog(
      context: context,
      builder: (_) => CategoryDialog(
        onSave: (data) async {
          try {
            await ApiService().createCategory(data);
            _loadCategories();
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

  void _editCategory(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (_) => CategoryDialog(
        category: category,
        onSave: (data) async {
          try {
            await ApiService().updateCategory(category['id'], data);
            _loadCategories();
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

  void _deleteCategory(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure? This will also delete all products in this category.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService().deleteCategory(id);
                _loadCategories();
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
              const Text('Categories', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text('${_categories.length} categories', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  IconButton(icon: const Icon(Icons.refresh), onPressed: _loadCategories, tooltip: 'Refresh'),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _addCategory,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Category'),
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
                    ElevatedButton(onPressed: _loadCategories, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Icon')),
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Products')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _categories.map((c) {
                        final category = Map<String, dynamic>.from(c);
                        final iconUrl = category['icon'] as String?;
                        return DataRow(cells: [
                          DataCell(Text('${category['id']}')),
                          DataCell(
                            iconUrl != null && iconUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      iconUrl.startsWith('http') ? iconUrl : '${ApiConfig.baseUrl}$iconUrl',
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 36),
                                    ),
                                  )
                                : const Icon(Icons.category, size: 36, color: Colors.grey),
                          ),
                          DataCell(Text(category['name'] ?? '')),
                          DataCell(Text('${category['count'] ?? 0}')),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _editCategory(category),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteCategory(category['id']),
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryDialog extends StatefulWidget {
  final Map<String, dynamic>? category;
  final Function(Map<String, dynamic>) onSave;

  const CategoryDialog({super.key, this.category, required this.onSave});

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _nameUzController;
  late TextEditingController _nameRuController;

  // Icon upload state
  int? _iconId;
  String? _iconUrl;
  PlatformFile? _pickedFile;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?['name'] ?? '');
    _nameUzController = TextEditingController(text: widget.category?['name_uz'] ?? '');
    _nameRuController = TextEditingController(text: widget.category?['name_ru'] ?? '');
    _iconUrl = widget.category?['icon'];
  }

  Future<void> _pickAndUploadIcon() async {
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
        _iconId = response['id'];
        _iconUrl = response['url'];
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
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon upload section
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: _uploading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildIconPreview(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _uploading ? null : _pickAndUploadIcon,
                  icon: const Icon(Icons.upload),
                  label: Text(_iconUrl != null ? 'Change Icon' : 'Upload Icon'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 16),
              TextField(controller: _nameUzController, decoration: const InputDecoration(labelText: 'Name (UZ)')),
              const SizedBox(height: 16),
              TextField(controller: _nameRuController, decoration: const InputDecoration(labelText: 'Name (RU)')),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name is required')),
              );
              return;
            }
            final data = <String, dynamic>{'name': name};
            if (_iconId != null) data['icon_id'] = _iconId;
            final nameUz = _nameUzController.text.trim();
            final nameRu = _nameRuController.text.trim();
            if (nameUz.isNotEmpty) data['name_uz'] = nameUz;
            if (nameRu.isNotEmpty) data['name_ru'] = nameRu;

            Navigator.pop(context);
            widget.onSave(data);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildIconPreview() {
    // Show picked file bytes
    if (_pickedFile?.bytes != null) {
      return Image.memory(_pickedFile!.bytes!, fit: BoxFit.contain);
    }
    // Show existing icon URL
    if (_iconUrl != null && _iconUrl!.isNotEmpty) {
      final url = _iconUrl!.startsWith('http') ? _iconUrl! : '${ApiConfig.baseUrl}$_iconUrl';
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.broken_image, size: 40, color: Colors.grey), Text('Failed to load')],
          ),
        ),
      );
    }
    // No icon
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image, size: 40, color: Colors.grey),
          SizedBox(height: 8),
          Text('No icon', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
