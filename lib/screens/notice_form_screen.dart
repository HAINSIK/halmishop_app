import 'package:flutter/material.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';

class NoticeFormScreen extends StatefulWidget {
  final Map<String, dynamic>? notice;

  const NoticeFormScreen({super.key, this.notice});

  @override
  State<NoticeFormScreen> createState() => _NoticeFormScreenState();
}

class _NoticeFormScreenState extends State<NoticeFormScreen> {
  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _contentController = TextEditingController();

  bool _isVisible = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final notice = widget.notice;

    if (notice != null) {
      _titleController.text = notice['title']?.toString() ?? '';

      _contentController.text = notice['content']?.toString() ?? '';

      _isVisible = notice['visible'] == true;
    }
  }

  Future<void> _saveNotice() async {
    if (_isSaving) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('제목과 내용을 모두 입력해 주세요.')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (!mounted) return;

      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인 정보가 없습니다. 다시 로그인해 주세요.')),
        );
        return;
      }

      final noticeId = widget.notice?['id'];

      final url = noticeId == null
          ? '${ApiConfig.baseUrl}/api/admin/notices'
          : '${ApiConfig.baseUrl}/api/admin/notices/$noticeId';

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'title': title,
        'content': content,
        'visible': _isVisible,
      });

      final response =
          await (noticeId == null
                  ? http.post(Uri.parse(url), headers: headers, body: body)
                  : http.put(Uri.parse(url), headers: headers, body: body))
              .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ 공지사항 등록 성공');

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('공지사항이 등록되었습니다.')));

        Navigator.pop(context, true);
      } else {
        debugPrint('❌ 공지사항 등록 실패: ${response.statusCode}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공지사항 등록 실패 (${response.statusCode})')),
        );
      }
    } catch (e) {
      debugPrint('❌ 공지사항 등록 오류: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('서버 연결 중 오류가 발생했습니다.')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF244C3A),
        foregroundColor: Colors.white,

        title: Text(
          widget.notice == null ? '공지사항 등록' : '공지사항 수정',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '공지사항 제목',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF244C3A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              maxLength: 100,
              decoration: InputDecoration(
                hintText: '공지사항 제목을 입력하세요',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '공지사항 내용',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF244C3A),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _contentController,
              maxLines: 10,
              minLines: 6,
              decoration: InputDecoration(
                hintText: '공지사항 내용을 입력하세요',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text(
                '공지사항 공개',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF244C3A),
                ),
              ),
              subtitle: Text(_isVisible ? '고객에게 공개됩니다.' : '관리자만 확인할 수 있습니다.'),
              value: _isVisible,
              activeThumbColor: const Color(0xFFF47B08),
              onChanged: (value) {
                setState(() {
                  _isVisible = value;
                });
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveNotice,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF47B08),
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
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        widget.notice == null ? '공지사항 등록' : '수정사항 저장',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
