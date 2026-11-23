import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final ProductModel? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  late String _unit;
  late bool _isAvailable;
  bool _isSaving = false;
  String _existingImageUrl = '';
  XFile? _pickedFile;
  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    final ProductModel? product = widget.product;
    _nameController = TextEditingController(text: product?.name ?? '');
    _descriptionController = TextEditingController(
      text: product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(0),
    );
    _quantityController = TextEditingController(
      text: product == null ? '' : _formatQuantity(product.quantity),
    );
    _unit = product?.unit ?? AppConstants.productUnits.first;
    _isAvailable = product?.isAvailable ?? true;
    _existingImageUrl = product?.imageUrl ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (picked == null) {
      return;
    }

    final Uint8List bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _pickedFile = picked;
      _pickedBytes = bytes;
    });
  }

  void _removeImage() {
    setState(() {
      _pickedFile = null;
      _pickedBytes = null;
      _existingImageUrl = '';
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AuthProvider authProvider = context.read<AuthProvider>();

    if (authProvider.userModel == null) {
      await authProvider.refreshUserModel();
      if (!mounted) {
        return;
      }
    }

    final user = authProvider.userModel;
    if (user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your farmer profile is not available.'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final double price = double.parse(_priceController.text.trim());
    final double quantity = double.parse(_quantityController.text.trim());

    setState(() {
      _isSaving = true;
    });

    try {
      String imageUrl = _existingImageUrl;
      if (_pickedFile != null) {
        imageUrl = await StorageService().uploadProductImage(
          _pickedFile!,
          user.uid,
        );
      }

      final DateTime now = DateTime.now();
      final bool isAvailable = _isAvailable && quantity > 0;

      if (widget.product == null) {
        final ProductModel product = ProductModel(
          id: '',
          farmerId: user.uid,
          farmerName: user.name,
          farmerPhone: user.phone,
          farmerLocation: user.location,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          quantity: quantity,
          unit: _unit,
          imageUrl: imageUrl,
          isAvailable: isAvailable,
          createdAt: now,
          updatedAt: now,
        );
        await ProductService().createProduct(product);
      } else {
        final ProductModel product = widget.product!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          quantity: quantity,
          unit: _unit,
          imageUrl: imageUrl,
          isAvailable: isAvailable,
          updatedAt: now,
        );
        await ProductService().updateProduct(widget.product!.id, product.toMap());
      }

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Product updated successfully.'
                : 'Product published successfully.',
          ),
        ),
      );
      navigator.pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Could not save product: $error'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _buildImagePicker(),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Product name',
                        hintText: 'e.g. Fresh spinach',
                        prefixIcon: Icon(Icons.eco_outlined),
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixText: 'TZS ',
                              prefixIcon: Icon(Icons.sell_outlined),
                            ),
                            validator: (String? value) {
                              final double? price = double.tryParse(
                                value?.trim() ?? '',
                              );
                              if (price == null || price <= 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              suffixText: _unit,
                              prefixIcon: const Icon(
                                Icons.inventory_2_outlined,
                              ),
                            ),
                            validator: (String? value) {
                              final double? quantity = double.tryParse(
                                value?.trim() ?? '',
                              );
                              if (quantity == null || quantity < 0) {
                                return 'Enter a valid quantity';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        prefixIcon: Icon(Icons.scale_outlined),
                      ),
                      items: AppConstants.productUnits
                          .map(
                            (String unit) => DropdownMenuItem<String>(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() {
                            _unit = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Tell buyers about your produce...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Available for purchase'),
                      subtitle: const Text(
                        'Turn off to hide this product from the marketplace.',
                      ),
                      value: _isAvailable,
                      activeThumbColor: AppConstants.primaryColor,
                      onChanged: (bool value) {
                        setState(() {
                          _isAvailable = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.isEditing
                                  ? 'Save changes'
                                  : 'Publish product',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    final bool hasImage = _pickedBytes != null || _existingImageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
          onTap: _isSaving ? null : _pickImage,
          child: Container(
            height: 190,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              border: Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: hasImage
                ? _pickedBytes != null
                      ? Image.memory(
                          _pickedBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : CachedNetworkImage(
                          imageUrl: _existingImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (BuildContext context, String url) =>
                              _imagePlaceholder(),
                          errorWidget:
                              (
                                BuildContext context,
                                String url,
                                Object error,
                              ) => _imagePlaceholder(),
                        )
                : _imagePlaceholder(),
          ),
        ),
        if (hasImage)
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextButton.icon(
                  onPressed: _isSaving ? null : _pickImage,
                  icon: const Icon(Icons.photo_outlined, size: 18),
                  label: const Text('Change photo'),
                ),
                TextButton.icon(
                  onPressed: _isSaving ? null : _removeImage,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 40,
            color: AppConstants.primaryColor.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap to upload a product photo',
            style: TextStyle(
              color: AppConstants.primaryColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
