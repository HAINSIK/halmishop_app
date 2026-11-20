import 'package:flutter/material.dart';

import '../models/banchan_model.dart';
import '../services/banchan_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

import '../services/api_config.dart';

import 'package:halmishop_app/utils/image_url_helper.dart';

class ProductEditScreen extends StatefulWidget {
  final Banchan product;

  const ProductEditScreen({super.key, required this.product});

  @override
  State<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends State<ProductEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;

  late String _selectedCategory;
  // 149-3-27단계: 상품 수정 저장 상태
  bool _isSaving = false;

  // 149-5-10단계: 상품 판매 상태
  bool _isSaleEnabled = true;
  bool _isUpdatingSaleStatus = false;

  // 149-3-32단계: 대표사진 변경 준비
  final ImagePicker _imagePicker = ImagePicker();

  // 새로 선택한 대표사진 (선택하지 않으면 기존 사진 유지)
  XFile? _selectedMainImage;

  // 149-4-3단계: 기존 상품 상세사진 목록
  List<Map<String, dynamic>> _detailImages = [];

  // 상세사진 조회 중 여부
  bool _isLoadingDetailImages = true;

  // 149-4-5단계: 새로 추가할 상세사진 목록
  final List<XFile> _selectedDetailImages = [];

  @override
  void initState() {
    super.initState();

    // 기존 상품 정보를 입력창에 자동으로 채우기
    _nameController = TextEditingController(text: widget.product.name);

    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );

    _descriptionController = TextEditingController(
      text: widget.product.description,
    );

    _selectedCategory = widget.product.category;

    // 149-5-12단계: 기존 상품의 판매 상태 불러오기
    _isSaleEnabled = widget.product.isSaleEnabled;

    // 149-4-3단계: 기존 상세사진 조회
    _loadDetailImages();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // 149-4-3단계: 기존 상세사진 불러오기
  Future<void> _loadDetailImages() async {
    final images = await BanchanService().fetchProductDetailImages(
      widget.product.id,
    );

    if (!mounted) return;

    setState(() {
      _detailImages = images;
      _isLoadingDetailImages = false;
    });
  }

  // 149-4-9-7단계: 등록된 상세사진 개별 삭제
  Future<void> _deleteDetailImage(int imageId) async {
    if (_isSaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('상세사진 삭제'),
        content: const Text(
          '이 상세사진을 삭제하시겠습니까?\n'
          '삭제하면 상품 상세화면에서 더 이상 표시되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    final success = await BanchanService().deleteProductDetailImage(
      productId: widget.product.id,
      imageId: imageId,
    );

    if (!mounted) return;

    if (success) {
      await _loadDetailImages();
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? '상세사진이 삭제되었습니다.' : '상세사진 삭제에 실패했습니다.')),
    );
  }

  // 149-4-10-6단계: 상세사진 순서를 한 칸 이동
  Future<void> _moveDetailImage(int index, int direction) async {
    if (_isSaving || _isLoadingDetailImages) return;

    final targetIndex = index + direction;

    // 첫 번째 사진을 앞으로, 마지막 사진을 뒤로 이동하지 않도록 제한
    if (index < 0 ||
        index >= _detailImages.length ||
        targetIndex < 0 ||
        targetIndex >= _detailImages.length) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // 현재 순서를 복사한 후 두 사진의 위치 교환
    final reorderedImages = List<Map<String, dynamic>>.from(_detailImages);

    final temp = reorderedImages[index];
    reorderedImages[index] = reorderedImages[targetIndex];
    reorderedImages[targetIndex] = temp;

    // 변경된 사진 ID 순서 추출
    final imageIds = reorderedImages
        .map((image) => image['id'] as int)
        .toList();

    // 서버에 변경된 순서 저장
    final success = await BanchanService().reorderProductDetailImages(
      productId: widget.product.id,
      imageIds: imageIds,
    );

    if (!mounted) return;

    if (success) {
      // 서버 저장 성공 시에만 화면 순서 변경
      setState(() {
        _detailImages = reorderedImages;
      });
    }

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '상세사진 순서가 변경되었습니다.' : '상세사진 순서 변경에 실패했습니다.'),
      ),
    );
  }

  // 149-4-5단계: 상세사진 여러 장 선택
  Future<void> _pickDetailImages() async {
    if (_isSaving) return;

    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isEmpty || !mounted) return;

      setState(() {
        final existingPaths = _selectedDetailImages
            .map((image) => image.path)
            .toSet();

        for (final image in images) {
          if (existingPaths.add(image.path)) {
            _selectedDetailImages.add(image);
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('새 상세사진 ${_selectedDetailImages.length}장이 선택되었습니다.'),
        ),
      );
    } catch (e) {
      debugPrint('상세사진 선택 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상세사진을 선택하는 중 오류가 발생했습니다.')));
    }
  }

  // 149-3-34단계: 새로운 대표사진 선택
  Future<void> _pickMainImage() async {
    if (_isSaving) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      setState(() {
        _selectedMainImage = image;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('새 대표사진이 선택되었습니다.')));
    } catch (e) {
      debugPrint('대표사진 선택 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진을 선택하는 중 오류가 발생했습니다.')));
    }
  }

  // 149-3-27단계: 상품 기본 정보 저장
  Future<void> _saveProduct() async {
    if (_isSaving) return;

    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim());
    final description = _descriptionController.text.trim();

    // 입력값 확인
    if (name.isEmpty || price == null || price < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('상품명과 올바른 판매 가격을 입력해 주세요.')));
      return;
    }

    if (_selectedCategory.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('상품 카테고리를 선택해 주세요.')));
      return;
    }

    setState(() => _isSaving = true);

    final banchanService = BanchanService();

    // 기본값은 기존 대표사진 주소
    String imageUrl = widget.product.imageUrl;

    // 새 대표사진을 선택한 경우에만 서버 업로드
    if (_selectedMainImage != null) {
      final uploadedUrl = await banchanService.uploadProductImage(
        _selectedMainImage!,
      );

      if (!mounted) return;

      // 업로드 실패 시 상품 수정 중단
      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('대표사진 업로드에 실패했습니다. 다시 시도해 주세요.')),
        );
        return;
      }

      imageUrl = uploadedUrl;
    }

    // 상품 정보와 대표사진 주소를 함께 저장
    final success = await banchanService.updateProduct(
      productId: widget.product.id,
      name: name,
      price: price,
      category: _selectedCategory,
      description: description,
      imageUrl: imageUrl,
    );

    if (!mounted) return;

    if (success) {
      // 149-4-7단계: 새 상세사진 서버 업로드
      int uploadedCount = 0;

      for (final image in _selectedDetailImages) {
        final uploaded = await banchanService.uploadProductDetailImage(
          productId: widget.product.id,
          imageFile: image,
        );

        if (uploaded) {
          uploadedCount++;
        }

        if (!mounted) return;
      }

      if (!mounted) return;

      if (_selectedDetailImages.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '상품 정보 저장 완료 · 상세사진 '
              '$uploadedCount/${_selectedDetailImages.length}장 업로드',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('상품 정보가 수정되었습니다.')));
      }

      Navigator.pop(context, true);
      return;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상품 수정에 실패했습니다. 다시 시도해 주세요.')),
      );
    }
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 149-5-13단계: 상품 판매 중지 및 판매 재개
  Future<void> _changeSaleStatus(bool saleEnabled) async {
    if (_isUpdatingSaleStatus || _isSaving) {
      return;
    }

    setState(() {
      _isUpdatingSaleStatus = true;
    });

    try {
      final success = await BanchanService().updateProductSaleStatus(
        productId: widget.product.id,
        saleEnabled: saleEnabled,
      );

      if (!mounted) return;

      if (success) {
        setState(() {
          _isSaleEnabled = saleEnabled;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(saleEnabled ? '상품 판매가 재개되었습니다.' : '상품 판매가 중지되었습니다.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('판매 상태 변경에 실패했습니다.')));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('판매 상태 변경 오류: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingSaleStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF2),
      appBar: AppBar(
        title: const Text('상품 정보 수정'),
        backgroundColor: const Color(0xFF1F4D3A),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '상품 기본 정보',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 149-3-33단계: 현재 등록된 대표사진 표시
              const Text(
                '현재 상품 대표사진',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F4D3A),
                ),
              ),

              const SizedBox(height: 12),

              if (widget.product.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),

                  child: Image.network(
                    // 149-7-39단계: 공통 이미지 URL 처리
                    getImageUrl(widget.product.imageUrl),

                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.contain,

                    errorBuilder: (context, error, stackTrace) {
                      debugPrint('❌ 대표사진 로딩 실패');
                      debugPrint('이미지 URL: ${widget.product.imageUrl}');
                      debugPrint('오류 내용: $error');

                      return const SizedBox(
                        height: 180,
                        child: Center(child: Text('대표사진을 불러올 수 없습니다.')),
                      );
                    },
                  ),
                )
              else
                const SizedBox(
                  height: 180,
                  child: Center(child: Text('등록된 대표사진이 없습니다.')),
                ),

              const SizedBox(height: 24),

              // 149-3-34단계: 대표사진 변경 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickMainImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('대표사진 변경'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F4D3A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF1F4D3A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 149-3-35단계: 새 대표사진 미리보기
              if (_selectedMainImage != null) ...[
                const Text(
                  '새로 선택한 대표사진',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4D3A),
                  ),
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder<Uint8List>(
                    future: _selectedMainImage!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(
                          height: 180,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      return Image.memory(
                        snapshot.data!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  '※ 상품 정보 저장 시 새 대표사진으로 변경될 예정입니다.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),

                const SizedBox(height: 20),
              ],

              // 149-4-4단계: 기존 상품 상세사진 표시
              const SizedBox(height: 24),

              const Text(
                '등록된 상품 상세사진',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F4D3A),
                ),
              ),

              const SizedBox(height: 12),

              if (_isLoadingDetailImages)
                const Center(child: CircularProgressIndicator())
              else if (_detailImages.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      '등록된 상세사진이 없습니다.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _detailImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final image = entry.value;
                    final imageUrl = image['imageUrl']?.toString() ?? '';

                    // 149-7-39단계: 상세사진 공통 이미지 URL 처리
                    final fullImageUrl = getImageUrl(imageUrl);

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            fullImageUrl,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('상세사진 표시 오류: $error');
                              return const SizedBox(
                                width: 110,
                                height: 110,
                                child: Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              );
                            },
                          ),
                        ),

                        // 등록된 상세사진 삭제 버튼
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    final imageId = image['id'];
                                    if (imageId is int) {
                                      _deleteDetailImage(imageId);
                                    }
                                  },
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            tooltip: '상세사진 삭제',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),

                        // 149-4-10-7단계: 상세사진 순서 이동 버튼
                        Positioned(
                          bottom: 2,
                          left: 2,
                          right: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 왼쪽으로 한 칸 이동
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                child: IconButton(
                                  onPressed: (_isSaving || index == 0)
                                      ? null
                                      : () => _moveDetailImage(index, -1),
                                  icon: const Icon(Icons.chevron_left),
                                  color: const Color(0xFF1F4D3A),
                                  tooltip: '왼쪽으로 이동',
                                  iconSize: 22,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),

                              // 오른쪽으로 한 칸 이동
                              Material(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                child: IconButton(
                                  onPressed:
                                      (_isSaving ||
                                          index == _detailImages.length - 1)
                                      ? null
                                      : () => _moveDetailImage(index, 1),
                                  icon: const Icon(Icons.chevron_right),
                                  color: const Color(0xFF1F4D3A),
                                  tooltip: '오른쪽으로 이동',
                                  iconSize: 22,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),

              const SizedBox(height: 24),

              // 149-4-5단계: 상세사진 추가 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : _pickDetailImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('상세사진 추가'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F4D3A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF1F4D3A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 149-4-6단계: 새로 선택한 상세사진 미리보기
              if (_selectedDetailImages.isNotEmpty) ...[
                const Text(
                  '새로 추가할 상세사진',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F4D3A),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '선택한 사진 ${_selectedDetailImages.length}장',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),

                const SizedBox(height: 12),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(_selectedDetailImages.length, (
                    index,
                  ) {
                    final image = _selectedDetailImages[index];

                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 110,
                            height: 110,
                            child: FutureBuilder<Uint8List>(
                              future: image.readAsBytes(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                );
                              },
                            ),
                          ),
                        ),

                        // 선택한 사진을 목록에서 제거
                        Positioned(
                          top: 2,
                          right: 2,
                          child: IconButton(
                            onPressed: _isSaving
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDetailImages.removeAt(index);
                                    });
                                  },
                            icon: const Icon(
                              Icons.cancel,
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                            tooltip: '선택 취소',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    );
                  }),
                ),

                const SizedBox(height: 12),

                const Text(
                  '※ 선택한 사진은 상품 정보 저장 시 추가될 예정입니다.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),

                const SizedBox(height: 20),
              ],

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '상품명',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '판매 가격',
                  suffixText: '원',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '상품 상세 설명',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: '상품 카테고리',
                  border: OutlineInputBorder(),
                ),
                items: [
                  ...{'국·탕', '찌개·조림', '밑반찬', '김치', '기타', _selectedCategory}.map(
                    (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // 149-5-14단계: 상품 판매 상태 관리
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1F4D3A).withValues(alpha: 0.2),
                  ),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _isSaleEnabled ? '판매 중' : '판매 중지',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isSaleEnabled
                          ? const Color(0xFF1F4D3A)
                          : Colors.red,
                    ),
                  ),
                  subtitle: Text(
                    _isSaleEnabled ? '현재 판매 가능한 상품입니다.' : '현재 판매가 중지된 상품입니다.',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _isSaleEnabled,
                  activeColor: const Color(0xFF1F4D3A),
                  onChanged: (_isUpdatingSaleStatus || _isSaving)
                      ? null
                      : (value) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: Text(value ? '상품 판매 재개' : '상품 판매 중지'),
                              content: Text(
                                value
                                    ? '이 상품의 판매를 다시 시작하시겠습니까?'
                                    : '이 상품의 판매를 중지하시겠습니까?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('확인'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed != true || !mounted) {
                            return;
                          }

                          await _changeSaleStatus(value);
                        },
                ),
              ),

              const SizedBox(height: 24),

              // 149-3-28단계: 상품 수정 저장 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F4D3A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '상품 정보 저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
