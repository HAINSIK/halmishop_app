import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';

class AdminBannerFormScreen extends StatefulWidget {
  // 수정할 배너 정보 (등록 시에는 null)
  final Map<String, dynamic>? banner;

  const AdminBannerFormScreen({super.key, this.banner});

  @override
  State<AdminBannerFormScreen> createState() => _AdminBannerFormScreenState();
}

class _AdminBannerFormScreenState extends State<AdminBannerFormScreen> {
  // 145-30-1단계: 배너 제목 입력 컨트롤러
  final TextEditingController _titleController = TextEditingController();

  // 145-30-3단계: 배너 이미지 경로 입력
  final TextEditingController _imageUrlController = TextEditingController();

  // 145-30-5단계: 배너 표시 순서
  final TextEditingController _displayOrderController = TextEditingController(
    text: '1',
  );

  // 145-30-2단계: 배너 종류 선택
  String _selectedCategory = 'LIVE';

  // 145-30-4단계: 배너 공개 여부
  bool _isVisible = true;

  // 145-32-4단계: 수정 화면 기존 배너 정보 불러오기
  @override
  void initState() {
    super.initState();

    final banner = widget.banner;

    // 신규 등록이면 기존 기본값 유지
    if (banner == null) return;

    // 수정 모드일 때 기존 데이터 자동 입력
    _titleController.text = banner['title']?.toString() ?? '';
    _imageUrlController.text = banner['imageUrl']?.toString() ?? '';

    _selectedCategory = banner['category']?.toString() ?? 'LIVE';
    _isVisible = banner['visible'] == true;

    _displayOrderController.text = banner['displayOrder']?.toString() ?? '1';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  // 145-31-1단계: 관리자 배너 등록 API
  Future<void> _saveBanner() async {
    final String title = _titleController.text.trim();
    final String imageUrl = _imageUrlController.text.trim();
    final int? displayOrder = int.tryParse(_displayOrderController.text.trim());

    if (title.isEmpty || imageUrl.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('배너 제목과 이미지 경로를 입력해 주세요.')));
      return;
    }

    if (displayOrder == null || displayOrder < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('표시 순서는 0 이상의 숫자로 입력해 주세요.')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('관리자 로그인 정보가 없습니다.');
      }

      // 145-32-8단계: 등록 POST / 수정 PUT 구분
      final bool isEditMode = widget.banner != null;

      final String url = isEditMode
          ? '${ApiConfig.baseUrl}/api/admin/banners/${widget.banner!['id']}'
          : '${ApiConfig.baseUrl}/api/admin/banners';

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=UTF-8',
      };

      final body = jsonEncode({
        'title': title,
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'visible': _isVisible,
        'displayOrder': displayOrder,
      });

      final response =
          await (isEditMode
                  ? http.put(Uri.parse(url), headers: headers, body: body)
                  : http.post(Uri.parse(url), headers: headers, body: body))
              .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.banner == null ? '배너가 등록되었습니다.' : '배너 수정이 완료되었습니다.',
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('배너 등록 실패 (${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('배너 등록 중 오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E9),
      appBar: AppBar(
        title: Text(widget.banner == null ? '배너 등록' : '배너 수정'),

        backgroundColor: const Color(0xFF244C3A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 배너 제목
            const Text(
              '배너 제목',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF244C3A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: '예: 오늘도 젊은할미 LIVE!',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF47B08),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 2. 배너 종류
            const Text(
              '배너 종류',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF244C3A),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF47B08),
                    width: 2,
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'LIVE', child: Text('라이브 방송')),
                DropdownMenuItem(value: 'EVENT', child: Text('이벤트 / 할인')),
                DropdownMenuItem(value: 'KIMCHI', child: Text('김치 특가')),
                DropdownMenuItem(value: 'DELIVERY', child: Text('배송 / 휴무 안내')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // 3. 배너 이미지 경로
            const Text(
              '배너 이미지 경로',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF244C3A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                hintText: '/images/banners/live_banner.png',
                helperText: '서버에 등록된 배너 이미지 경로를 입력해 주세요.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF47B08),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. 배너 공개 여부
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '배너 공개 여부',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF244C3A),
                  ),
                ),
                subtitle: Text(
                  _isVisible ? '고객에게 배너가 표시됩니다.' : '관리자에게만 표시됩니다.',
                ),
                value: _isVisible,
                activeTrackColor: const Color(0xFF244C3A),
                onChanged: (value) {
                  setState(() {
                    _isVisible = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // 5. 배너 표시 순서
            const Text(
              '배너 표시 순서',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF244C3A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _displayOrderController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '예: 1',
                helperText: '숫자가 작을수록 먼저 표시됩니다.',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFF47B08),
                    width: 2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 6. 배너 등록 버튼
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _saveBanner,

                icon: const Icon(Icons.add_photo_alternate_outlined),

                label: Text(
                  widget.banner == null ? '배너 등록하기' : '변경사항 저장',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47B08),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
