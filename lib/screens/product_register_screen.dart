import 'package:flutter/material.dart';

import '../services/banchan_service.dart';

import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ProductRegisterScreen extends StatefulWidget {
  const ProductRegisterScreen({super.key});

  @override
  State<ProductRegisterScreen> createState() => _ProductRegisterScreenState();
}

class _ProductRegisterScreenState extends State<ProductRegisterScreen> {
  bool _isRegistering = false;
  // 148-3-16-4단계: 대표사진 선택 상태
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedMainImage;
  // 148-5-9-1단계: 상품 상세사진 여러 장 선택 상태
  final List<XFile> _selectedDetailImages = [];
  // 148-3-5단계: 상품명 입력 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  // 148-3-6단계: 판매가격 입력 컨트롤러
  final TextEditingController _priceController = TextEditingController();
  // 148-3-8단계: 상품 상세설명
  final TextEditingController _descriptionController = TextEditingController();

  // 148-3-7단계: 상품 카테고리
  String? _selectedCategory;

  final List<String> _categories = ['국·탕', '찌개·조림', '밑반찬', '김치', '기타'];

  // 148-5-9-1단계: 상세사진 여러 장 선택
  Future<void> _pickDetailImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isEmpty || !mounted) return;

      setState(() {
        // 기존 선택 사진은 유지하고 새 사진 추가
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
          content: Text('상세사진 ${_selectedDetailImages.length}장이 선택되었습니다.'),
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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상품등록'),
        backgroundColor: const Color(0xFF1F4D3A),
        foregroundColor: Colors.white,
      ),
      // 148-3-9단계: 상품등록 화면 스크롤 적용
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상품 기본정보',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4D3A),
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '상품명',
                hintText: '예: 할미표 파김치',
                prefixIcon: const Icon(Icons.restaurant_menu),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 148-3-6단계: 판매가격 입력
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '판매가격',
                hintText: '예: 5000',
                suffixText: '원',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 148-3-7단계: 상품 카테고리 선택
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: '상품 카테고리',
                prefixIcon: const Icon(Icons.category_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              hint: const Text('카테고리를 선택하세요'),
              items: _categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // 148-3-8단계: 상품 상세설명 입력
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              minLines: 3,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                labelText: '상품 상세설명',
                hintText: '예: 국내산 재료로 정성껏 담근 아삭한 파김치입니다.',
                alignLabelWithHint: true,
                prefixIcon: const Icon(Icons.description_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 148-3-16-3단계: 대표사진 선택 영역
            const Text(
              '상품 대표사진',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4D3A),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              // 148-3-16-4단계: 갤럭시 갤러리에서 대표사진 선택
              onPressed: () async {
                try {
                  final XFile? image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );

                  if (image == null) return;
                  if (!mounted) return;

                  setState(() {
                    _selectedMainImage = image;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('대표사진이 선택되었습니다.')),
                  );
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('사진을 선택하는 중 오류가 발생했습니다.')),
                  );
                  debugPrint('대표사진 선택 오류: $e');
                }
              },
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('대표사진 선택'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F4D3A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                side: const BorderSide(color: Color(0xFF1F4D3A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            // 148-3-16-5단계: 선택한 대표사진 미리보기
            if (_selectedMainImage != null) ...[
              const SizedBox(height: 16),

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

                    //boxfit cover 일때 미리보기 사진 짤림
                    // return Image.memory(
                    //   snapshot.data!,
                    //   width: double.infinity,
                    //   height: 220,
                    //   fit: BoxFit.cover
                    // );

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
                '선택한 대표사진 미리보기',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],

            // 148-5-9-2단계: 상품 상세사진 선택 영역
            const SizedBox(height: 28),

            const Text(
              '상품 상세사진 (선택사항)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F4D3A),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '상품 설명 아래에 표시할 사진을 여러 장 선택할 수 있습니다.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _isRegistering ? null : _pickDetailImages,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('상세사진 여러 장 선택'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F4D3A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                side: const BorderSide(color: Color(0xFF1F4D3A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_selectedDetailImages.isNotEmpty) ...[
              const SizedBox(height: 14),

              Text(
                '선택한 상세사진 ${_selectedDetailImages.length}장',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F4D3A),
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_selectedDetailImages.length, (index) {
                  final image = _selectedDetailImages[index];

                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 100,
                          height: 100,
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

                      Positioned(
                        top: 2,
                        right: 2,
                        child: IconButton(
                          onPressed: _isRegistering
                              ? null
                              : () {
                                  setState(() {
                                    _selectedDetailImages.removeAt(index);
                                  });
                                },
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: '사진 제거',
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],

            const SizedBox(height: 30),

            // 148-3-10단계: 상품등록 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isRegistering
                    ? null
                    : () async {
                        // 148-3-11단계: 상품명 필수 입력 검사
                        final name = _nameController.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('상품명을 입력해 주세요.')),
                          );
                          return;
                        }

                        // 148-3-12단계: 판매가격 입력값 검사
                        final price = int.tryParse(
                          _priceController.text.trim(),
                        );

                        if (price == null || price <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('판매가격을 올바르게 입력해 주세요.'),
                            ),
                          );
                          return;
                        }

                        // 148-3-13단계: 카테고리 필수 선택 검사
                        if (_selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('상품 카테고리를 선택해 주세요.')),
                          );
                          return;
                        }

                        // 148-3-15-2단계: 상품등록 요청 시작
                        setState(() {
                          _isRegistering = true;
                        });

                        // 148-3-17-16단계: 대표사진 서버 업로드
                        final banchanService = BanchanService();
                        String? imageUrl;

                        if (_selectedMainImage != null) {
                          imageUrl = await banchanService.uploadProductImage(
                            _selectedMainImage!,
                          );

                          if (!mounted) return;

                          // 사진 업로드에 실패하면 상품등록 중단
                          if (imageUrl == null) {
                            setState(() {
                              _isRegistering = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('대표사진 업로드에 실패했습니다. 다시 시도해 주세요.'),
                              ),
                            );
                            return;
                          }
                        }

                        // 148-3-17-16단계: 사진 주소와 상품정보 함께 등록
                        final int? productId = await banchanService
                            .registerProduct(
                              name: name,
                              price: price,
                              category: _selectedCategory!,
                              description: _descriptionController.text.trim(),
                              imageUrl: imageUrl,
                            );

                        if (!mounted) return;

                        // 148-3-15-2단계: 상품등록 요청 완료
                        setState(() {
                          _isRegistering = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              productId != null
                                  ? '상품이 정상적으로 등록되었습니다.'
                                  : '상품등록에 실패했습니다.',
                            ),
                          ),
                        );

                        if (productId != null) {
                          // 148-5-9-3-6단계: 상세사진 순서대로 업로드
                          int uploadedCount = 0;

                          for (final image in _selectedDetailImages) {
                            final success = await banchanService
                                .uploadProductDetailImage(
                                  productId: productId,
                                  imageFile: image,
                                );

                            if (success) {
                              uploadedCount++;
                            }
                          }

                          if (!mounted) return;

                          if (_selectedDetailImages.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '상세사진 $uploadedCount/${_selectedDetailImages.length}장 업로드 완료',
                                ),
                              ),
                            );
                          }

                          Navigator.pop(context, true);
                        }
                      },
                // 148-3-15-3단계: 상품등록 중 로딩 표시
                icon: _isRegistering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_circle_outline),

                label: Text(
                  _isRegistering ? '상품 등록 중...' : '상품 등록하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F4D3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
