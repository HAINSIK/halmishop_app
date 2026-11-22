import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';

import 'notice_form_screen.dart';

class AdminNoticeScreen extends StatefulWidget {
  const AdminNoticeScreen({super.key});

  @override
  State<AdminNoticeScreen> createState() => _AdminNoticeScreenState();
}

class _AdminNoticeScreenState extends State<AdminNoticeScreen> {
  List<dynamic> _notices = [];
  bool _isLoading = false;

  Future<void> _fetchAdminNotices() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('❌ 관리자 공지사항 조회: 로그인 토큰 없음');
        return;
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/admin/notices'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        debugPrint('🔍 공지사항 API 원본 데이터: $data');

        setState(() {
          _notices = data;
        });

        debugPrint('📢 관리자 공지사항 ${data.length}개 조회 완료');
      } else {
        debugPrint('❌ 관리자 공지사항 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 관리자 공지사항 조회 오류: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteNotice(int noticeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (!mounted) return;

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다.')));
        return;
      }

      final response = await http
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/admin/notices/$noticeId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        debugPrint('✅ 공지사항 삭제 성공: $noticeId');

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('공지사항이 삭제되었습니다.')));

        await _fetchAdminNotices();
      } else {
        debugPrint('❌ 공지사항 삭제 실패: ${response.statusCode}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공지사항 삭제 실패 (${response.statusCode})')),
        );
      }
    } catch (e) {
      debugPrint('❌ 공지사항 삭제 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('서버 연결 중 오류가 발생했습니다.')));
    }
  }

  // 151-36-1단계: 공지사항 푸시 중복 발송 요청 방지
  bool _isSendingNoticePush = false;
  // 151-35-3단계: 관리자 공지사항 푸시 발송 API
  Future<void> _sendNoticePush(int noticeId) async {
    // 151-36-2단계: 발송 중 중복 요청 차단
    if (_isSendingNoticePush) {
      debugPrint('⚠️ 공지사항 푸시 발송이 이미 진행 중입니다.');
      return;
    }

    _isSendingNoticePush = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('❌ 푸시 발송 실패: 로그인 정보 없음');
        return;
      }

      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/admin/notices/$noticeId/send-push',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 30));

      final message = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        debugPrint('✅ 공지사항 푸시 발송 요청 성공: $message');
      } else if (response.statusCode == 409) {
        debugPrint('⚠️ 이미 푸시 발송 처리된 공지사항: $message');
      } else {
        debugPrint('❌ 공지사항 푸시 발송 실패 (${response.statusCode}): $message');
      }

      // 151-36-3단계: 관리자에게 발송 결과 안내
      if (!mounted) return;

      String resultMessage;

      if (response.statusCode == 200) {
        resultMessage = '푸시 발송 요청이 완료되었습니다.\n$message';
      } else if (response.statusCode == 409) {
        resultMessage = '이미 푸시 발송 처리된 공지사항입니다.';
      } else {
        resultMessage =
            '푸시 발송에 실패했습니다.\n'
            'HTTP 상태: ${response.statusCode}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultMessage),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('❌ 공지사항 푸시 발송 오류: $e');
    } finally {
      // 발송 요청이 끝나면 다시 버튼 사용 가능
      _isSendingNoticePush = false;
    }
  }

  // 146-3-11-1단계: 장터홈 대표 공지 지정
  Future<void> _setHomeFeaturedNotice(int noticeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('로그인 정보가 없습니다.')));
        return;
      }

      final response = await http
          .put(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/admin/notices/$noticeId/home-featured',
            ),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('장터홈 대표 공지가 설정되었습니다!')));

        // 변경된 대표 공지 상태 다시 조회
        await _fetchAdminNotices();
      } else {
        final message = utf8.decode(response.bodyBytes);

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('대표 공지 설정 실패: $message')));
      }
    } catch (e) {
      debugPrint('❌ 대표 공지 설정 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('서버 연결 중 오류가 발생했습니다.')));
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAdminNotices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF244C3A),
        foregroundColor: Colors.white,
        title: const Text(
          '공지사항 관리',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFF47B08)),
            )
          : _notices.isEmpty
          ? const Center(
              child: Text(
                '등록된 공지사항이 없습니다.',
                style: TextStyle(fontSize: 16, color: Color(0xFF244C3A)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notice = _notices[index];

                return Card(
                  color: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFFF8F4E9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(
                            notice['title']?.toString() ?? '공지사항',
                            style: const TextStyle(
                              color: Color(0xFF244C3A),
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: Text(
                              notice['content']?.toString() ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.6,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),

                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('닫기'),
                            ),

                            // 146-3-11-2단계: 장터홈 대표 공지 지정 버튼
                            if (notice['visible'] == true &&
                                notice['homeFeatured'] != true)
                              TextButton.icon(
                                onPressed: () async {
                                  final noticeId = notice['id'] as int;

                                  Navigator.pop(context);

                                  await _setHomeFeaturedNotice(noticeId);
                                },
                                icon: const Icon(Icons.star_outline),
                                label: const Text('홈 대표 지정'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF244C3A),
                                ),
                              ),

                            TextButton.icon(
                              onPressed: () async {
                                Navigator.pop(context);

                                final result = await Navigator.push<bool>(
                                  this.context,
                                  MaterialPageRoute(
                                    builder: (context) => NoticeFormScreen(
                                      notice: Map<String, dynamic>.from(notice),
                                    ),
                                  ),
                                );

                                if (!mounted) return;

                                if (result == true) {
                                  await _fetchAdminNotices();
                                }
                              },
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('수정'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFF47B08),
                              ),
                            ),

                            // 151-35-1단계: 관리자 공지사항 푸시 발송 버튼
                            if (notice['visible'] == true)
                              TextButton.icon(
                                onPressed: () async {
                                  final noticeId = notice['id'] as int;

                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      backgroundColor: const Color(0xFFF8F4E9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      title: const Text(
                                        '📢 공지사항 푸시 발송',
                                        style: TextStyle(
                                          color: Color(0xFF244C3A),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      content: const Text(
                                        '이 공지사항을 전체 고객에게 푸시 알림으로 발송하시겠습니까?\n\n'
                                        '발송 후에는 취소할 수 없으며, 동일한 공지사항은 중복 발송할 수 없습니다.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                          child: const Text('취소'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFF47B08,
                                            ),
                                            foregroundColor: Colors.white,
                                          ),
                                          child: const Text('발송하기'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed != true || !mounted) return;

                                  // 151-35-4단계: 관리자 확인 후 실제 푸시 발송 API 호출
                                  debugPrint('📢 공지사항 푸시 발송 시작: $noticeId');

                                  await _sendNoticePush(noticeId);
                                },
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                ),
                                label: const Text('푸시 발송'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFF47B08),
                                ),
                              ),

                            TextButton.icon(
                              onPressed: () async {
                                final noticeId = notice['id'];

                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('공지사항 삭제'),
                                    content: const Text(
                                      '정말 이 공지사항을 삭제하시겠습니까?\n'
                                      '삭제한 공지사항은 복구할 수 없습니다.',
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
                                        child: const Text(
                                          '삭제',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed != true || !context.mounted) {
                                  return;
                                }

                                Navigator.pop(context);

                                await _deleteNotice(noticeId as int);
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('삭제'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      );
                    },

                    leading: Icon(
                      notice['visible'] == true
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: notice['visible'] == true
                          ? const Color(0xFF244C3A)
                          : Colors.grey,
                    ),
                    title: Text(
                      notice['title']?.toString() ?? '공지사항',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF244C3A),
                      ),
                    ),
                    subtitle: Text(
                      notice['visible'] == true ? '공개' : '비공개',
                      style: TextStyle(
                        color: notice['visible'] == true
                            ? const Color(0xFF244C3A)
                            : Colors.grey,
                      ),
                    ),
                    // 146-3-11-3단계: 장터홈 대표 공지 표시
                    trailing: notice['homeFeatured'] == true
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Color(0xFFF47B08),
                                size: 20,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '홈 대표',
                                style: TextStyle(
                                  color: Color(0xFFF47B08),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const NoticeFormScreen()),
          );

          if (!mounted) return;

          if (result == true) {
            await _fetchAdminNotices();
          }
        },

        backgroundColor: const Color(0xFFF47B08),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          '공지사항 등록',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
