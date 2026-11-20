import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';

import 'admin_banner_form_screen.dart';

import 'package:halmishop_app/utils/image_url_helper.dart';

class AdminBannerScreen extends StatefulWidget {
  const AdminBannerScreen({super.key});

  @override
  State<AdminBannerScreen> createState() => _AdminBannerScreenState();
}

class _AdminBannerScreenState extends State<AdminBannerScreen> {
  // 145-27-2단계: 관리자 배너 목록 및 로딩 상태
  List<dynamic> _banners = [];
  bool _isLoading = false;

  // 145-27-4단계: 화면 진입 시 배너 목록 자동 조회
  @override
  void initState() {
    super.initState();
    _fetchAdminBanners();
  }

  // 145-27-3단계: 관리자 배너 전체 조회
  Future<void> _fetchAdminBanners() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('❌ 관리자 배너 조회: 로그인 토큰 없음');
        return;
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/admin/banners'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _banners = data;
        });

        debugPrint('🖼️ 관리자 배너 ${data.length}개 조회 완료');
      } else {
        debugPrint('❌ 관리자 배너 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 관리자 배너 조회 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 145-33-1단계: 배너 삭제 확인 팝업
  Future<bool> _confirmDeleteBanner(String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('배너 삭제'),
          content: Text(
            '"$title" 배너를 정말 삭제하시겠습니까?\n\n'
            '삭제한 배너는 복구할 수 없습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // 145-33-2단계: 관리자 배너 삭제 API
  Future<void> _deleteBanner(int bannerId, String title) async {
    // 삭제 확인 팝업
    final confirmed = await _confirmDeleteBanner(title);

    if (!confirmed || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('관리자 로그인 정보가 없습니다.');
      }

      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/admin/banners/$bannerId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('배너가 삭제되었습니다.')));

        await _fetchAdminBanners();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('배너 삭제 실패 (${response.statusCode})')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('배너 삭제 중 오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E9),
      appBar: AppBar(
        title: const Text('배너 관리'),
        backgroundColor: const Color(0xFF244C3A),
        foregroundColor: Colors.white,
      ),

      // 145-29-1단계: 관리자 배너 등록 버튼
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminBannerFormScreen(),
            ),
          );

          if (!mounted) return;

          await _fetchAdminBanners();
        },

        backgroundColor: const Color(0xFFF47B08),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text(
          '배너 등록',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF47B08)),
            )
          : _banners.isEmpty
          ? const Center(
              child: Text(
                '등록된 배너가 없습니다.',
                style: TextStyle(fontSize: 16, color: Color(0xFF244C3A)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _banners.length,
              itemBuilder: (context, index) {
                final banner = _banners[index];
                final bool visible = banner['visible'] == true;

                // 145-28-3단계: 상대 경로 배너 이미지 URL 변환
                // 149-7-39단계: 관리자 배너 이미지 URL 공통 처리
                final String imagePath = banner['imageUrl']?.toString() ?? '';
                final String imageUrl = getImageUrl(imagePath);

                return Card(
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),

                  child: ListTile(
                    // 145-32-1단계: 수정할 배너 선택

                    // 145-32-5단계: 선택한 배너 수정 화면 열기
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminBannerFormScreen(
                            banner: Map<String, dynamic>.from(banner),
                          ),
                        ),
                      );

                      if (!mounted) return;

                      await _fetchAdminBanners();
                    },

                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 72,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 72,
                            height: 56,
                            color: const Color(0xFFF1EEE6),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      banner['title']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${banner['category']} · 표시 순서 ${banner['displayOrder']}',
                    ),

                    // 145-33-3단계: 공개 상태 및 삭제 버튼
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          visible ? '공개' : '비공개',
                          style: TextStyle(
                            color: visible
                                ? const Color(0xFF244C3A)
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: '배너 삭제',
                          onPressed: () {
                            final int bannerId = banner['id'];
                            final String title =
                                banner['title']?.toString() ?? '';

                            _deleteBanner(bannerId, title);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
