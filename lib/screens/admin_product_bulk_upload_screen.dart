import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'dart:typed_data';
// 153-9-5-2단계: 엑셀 미리보기 JSON 응답 처리
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';

class AdminProductBulkUploadScreen extends StatefulWidget {
  const AdminProductBulkUploadScreen({super.key});

  @override
  State<AdminProductBulkUploadScreen> createState() =>
      _AdminProductBulkUploadScreenState();
}

class _AdminProductBulkUploadScreenState
    extends State<AdminProductBulkUploadScreen> {
  PlatformFile? _excelFile;
  PlatformFile? _zipFile;
  // 153-9-5-3단계: 엑셀 미리보기 상태 관리
  bool _isPreviewing = false;

  Map<String, dynamic>? _excelPreviewResult;

  Uint8List? _previewedExcelBytes;

  // 153-9-5-4단계: 엑셀 파일 변경 시 미리보기 초기화
  Future<void> _pickExcel() async {
    if (_isPreviewing || _isUploading) return;

    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (file == null || !mounted) return;
    if (_isPreviewing || _isUploading) return;

    setState(() {
      _excelFile = file;

      // 기존 미리보기 결과 초기화
      _excelPreviewResult = null;

      // 기존 검증 완료 파일 데이터 초기화
      _previewedExcelBytes = null;
    });
  }

  Future<void> _pickZip() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (file == null || !mounted) return;

    setState(() {
      _zipFile = file;
    });
  }

  bool _isUploading = false;

  // 153-9-5-5단계: 엑셀 미리보기 API 호출
  Future<void> _previewExcel() async {
    if (_excelFile == null || _isPreviewing || _isUploading) {
      return;
    }

    final selectedFile = _excelFile!;

    setState(() {
      _isPreviewing = true;
      _excelPreviewResult = null;
      _previewedExcelBytes = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/products/excel-preview');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final fileBytes = await selectedFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: selectedFile.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      final result =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        setState(() {
          _excelPreviewResult = result;

          // 오류가 없는 경우에만 최종 등록용 파일 보관
          if (result['errorCount'] == 0) {
            _previewedExcelBytes = fileBytes;
          }
        });
      } else {
        throw Exception(result['message'] ?? '엑셀 미리보기에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('미리보기 오류: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPreviewing = false;
        });
      }
    }
  }

  // 153-9-5-8-6단계: 최종 상품 등록 확인 팝업
  Future<void> _confirmExcelRegistration() async {
    if (_isUploading || _isPreviewing) return;

    final result = _excelPreviewResult;

    if (result == null ||
        result['errorCount'] != 0 ||
        _previewedExcelBytes == null) {
      return;
    }

    final totalCount = result['totalCount'] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('상품 일괄등록 확인'),
        content: Text(
          '검증이 완료된 상품 $totalCount개를 등록하시겠습니까?\n\n'
          '등록을 완료하면 실제 상품 데이터가 서버에 저장됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF214D36),
              foregroundColor: Colors.white,
            ),
            child: const Text('상품 등록'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _registerPreviewedExcel();
  }

  // 153-9-5-8-4단계: 검증 완료된 엑셀 상품 최종 등록
  Future<void> _registerPreviewedExcel() async {
    if (_isUploading || _isPreviewing) return;

    final result = _excelPreviewResult;
    final fileBytes = _previewedExcelBytes;
    final selectedFile = _excelFile;

    // 미리보기 검증 완료 여부 확인
    if (result == null ||
        fileBytes == null ||
        selectedFile == null ||
        result['errorCount'] != 0) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/products/excel-upload');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // 미리보기에서 검증한 파일 데이터를 그대로 사용
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: selectedFile.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      final responseData =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final registeredCount = responseData['registeredCount'] ?? 0;

        // 등록 완료 후 엑셀 선택 및 미리보기 초기화
        setState(() {
          _excelFile = null;
          _excelPreviewResult = null;
          _previewedExcelBytes = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상품 $registeredCount개가 정상적으로 등록되었습니다.'),
            backgroundColor: const Color(0xFF214D36),
          ),
        );
      } else {
        // 등록 실패 시 다시 검증하도록 처리
        setState(() {
          _excelPreviewResult = null;
          _previewedExcelBytes = null;
        });

        throw Exception(responseData['message'] ?? '상품 등록에 실패했습니다.');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _excelPreviewResult = null;
        _previewedExcelBytes = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('상품 등록 오류: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _uploadFile({
    required PlatformFile file,
    required String endpoint,
  }) async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        throw Exception('로그인이 필요합니다.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      final fileBytes = await file.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: file.name),
      );
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('파일 등록이 완료되었습니다.')));
      } else {
        throw Exception('등록 실패 (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('업로드 오류: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF214D36);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF4),
      appBar: AppBar(
        title: const Text('상품 일괄등록'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 153-9-5-8-2단계: 엑셀 미리보기 버튼 연결
          _uploadCard(
            title: '1. 엑셀 상품 일괄등록',
            description:
                '엑셀 파일을 선택한 후 미리보기 및 사전 검증을 진행해 주세요.\n'
                '오류가 없는 경우에만 상품을 등록할 수 있습니다.',
            icon: Icons.table_chart,
            fileName: _excelFile?.name,
            onSelect: _pickExcel,
            onUpload: _previewExcel,
            buttonText: '미리보기 및 사전 검증',
          ),

          // 153-9-5-6-3단계: 엑셀 미리보기 결과 표시
          if (_excelPreviewResult != null) ...[
            const SizedBox(height: 16),
            _buildExcelPreviewCard(),
          ],

          const SizedBox(height: 16),
          _uploadCard(
            title: '2. ZIP 상품사진 일괄등록',
            description:
                '【ZIP 압축 방법】\n'
                '① 여러 상품 폴더를 하나의 ZIP으로 압축\n'
                '② 상품 폴더 하나를 ZIP으로 압축\n'
                '③ 폴더 없이 사진만 ZIP으로 압축\n\n'
                '※ 상품 폴더를 압축하는 경우 내부 폴더명과 '
                '상품의 사진폴더명이 같아야 합니다.\n'
                '※ 사진만 압축하는 경우 ZIP 파일명(.zip 제외)과 '
                '상품의 사진폴더명이 같아야 합니다.\n\n'
                '【사진 등록 규칙】\n'
                '• 01번은 대표사진, 02번부터는 상세사진\n'
                '• 사진 번호는 01번부터 연속으로 지정\n'
                '• 기존 사진이 등록된 상품은 중복 등록 불가\n'
                '• 최상위 사진과 상품 폴더 혼합 압축 불가\n'
                '• ZIP 최대 100MB, 사진 한 장당 최대 10MB',
            icon: Icons.folder_zip,
            fileName: _zipFile?.name,
            onSelect: _pickZip,
            onUpload: () {
              if (_zipFile != null) {
                _uploadFile(
                  file: _zipFile!,
                  endpoint: '/api/products/zip-images',
                );
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            '엑셀 상품등록을 먼저 완료한 뒤 '
            'ZIP 상품사진을 등록해 주세요.',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // 153-9-5-6-1단계: 엑셀 미리보기 요약 항목
  Widget _previewCountItem({
    required String title,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              '$count개',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 153-9-5-6-2단계: 엑셀 미리보기 결과 카드
  Widget _buildExcelPreviewCard() {
    final result = _excelPreviewResult;

    if (result == null) {
      return const SizedBox.shrink();
    }

    final totalCount = (result['totalCount'] as num?)?.toInt() ?? 0;
    final validCount = (result['validCount'] as num?)?.toInt() ?? 0;
    final errorCount = (result['errorCount'] as num?)?.toInt() ?? 0;

    // 153-9-5-7-2단계: 상품별 미리보기 목록 가져오기
    final products = (result['products'] as List? ?? [])
        .map((product) => Map<String, dynamic>.from(product as Map))
        .toList();

    const green = Color(0xFF214D36);

    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fact_check, color: green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '엑셀 미리보기 결과',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _previewCountItem(
                  title: '전체 상품',
                  count: totalCount,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 8),
                _previewCountItem(
                  title: '정상 상품',
                  count: validCount,
                  color: green,
                ),
                const SizedBox(width: 8),
                _previewCountItem(
                  title: '오류 상품',
                  count: errorCount,
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  errorCount == 0 ? Icons.check_circle : Icons.error_outline,
                  color: errorCount == 0 ? green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorCount == 0
                        ? '모든 상품의 검증이 완료되었습니다. 상품을 등록할 수 있습니다.'
                        : '오류를 수정한 후 엑셀 파일을 다시 선택해 주세요.',
                    style: TextStyle(
                      color: errorCount == 0 ? green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // 153-9-5-7-2단계: 상품별 미리보기 목록 표시
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            const Text(
              '상품별 검증 결과',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...products.map((product) => _buildPreviewProductItem(product)),
            // 153-9-5-8-5단계: 검증 완료 상품 최종 등록 버튼
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed:
                    (errorCount != 0 ||
                        totalCount == 0 ||
                        _previewedExcelBytes == null ||
                        _isUploading ||
                        _isPreviewing)
                    ? null
                    : _confirmExcelRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _isUploading ? '상품 등록 중...' : '상품 $totalCount개 최종 등록하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 153-9-5-7-1단계: 상품별 미리보기 및 검증 오류 표시
  Widget _buildPreviewProductItem(Map<String, dynamic> product) {
    final rowNumber = product['rowNumber'] ?? '-';

    final name = product['name']?.toString() ?? '';
    final priceText = product['priceText']?.toString() ?? '';
    final category = product['category']?.toString() ?? '';
    final folderName = product['imageFolderName']?.toString() ?? '';

    final errors = (product['errors'] as List? ?? [])
        .map((error) => error.toString())
        .toList();

    final hasError = errors.isNotEmpty;

    const green = Color(0xFF214D36);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasError ? const Color(0xFFFFF5F5) : const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError ? Colors.red.shade200 : Colors.green.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '엑셀 $rowNumber행',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const Spacer(),
              Icon(
                hasError ? Icons.error_outline : Icons.check_circle,
                color: hasError ? Colors.red : green,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                hasError ? '오류 ${errors.length}건' : '정상',
                style: TextStyle(
                  color: hasError ? Colors.red : green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            name.isEmpty ? '(상품명 미입력)' : name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Text('판매가격 : ${priceText.isEmpty ? "미입력" : priceText}'),
          Text('카테고리 : ${category.isEmpty ? "미입력" : category}'),
          Text('사진폴더명 : ${folderName.isEmpty ? "미입력" : folderName}'),

          if (hasError) ...[
            const Divider(height: 20),

            ...errors.map(
              (error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $error',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _uploadCard({
    required String title,
    required String description,
    required IconData icon,
    required String? fileName,
    required VoidCallback onSelect,
    required VoidCallback onUpload,

    // 153-9-5-8-1단계: 카드별 버튼 문구 설정
    String buttonText = '서버에 등록하기',
  }) {
    return Card(
      color: Colors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF214D36)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(description),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              // 153-9-5-8-3단계: 작업 중 파일 선택 차단
              onPressed: (_isUploading || _isPreviewing) ? null : onSelect,
              icon: const Icon(Icons.attach_file),
              label: Text(fileName ?? '파일 선택'),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // 153-9-5-8-3단계: 작업 중 중복 실행 차단
                onPressed: (fileName == null || _isUploading || _isPreviewing)
                    ? null
                    : onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF214D36),
                  foregroundColor: Colors.white,
                ),
                child: (_isUploading || _isPreviewing)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(_isPreviewing ? '엑셀 검증 중...' : '업로드 중...'),
                        ],
                      )
                    : Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
