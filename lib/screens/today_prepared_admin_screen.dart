import 'package:flutter/material.dart';

import '../models/banchan_model.dart';
import '../services/banchan_service.dart';

class TodayPreparedAdminScreen extends StatefulWidget {
  const TodayPreparedAdminScreen({super.key});

  @override
  State<TodayPreparedAdminScreen> createState() =>
      _TodayPreparedAdminScreenState();
}

class _TodayPreparedAdminScreenState extends State<TodayPreparedAdminScreen> {
  final BanchanService _service = BanchanService();

  List<Banchan> _products = [];
  Set<int> _selectedIds = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final products = await _service.fetchBanchanList();

      if (!mounted) return;

      setState(() {
        _products = products;

        // 기존에 선택한 오늘 준비한 반찬 자동 복원
        _selectedIds = products
            .where((product) => product.isTodayPrepared)
            .map((product) => product.id)
            .toSet();

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProducts() async {
    if (_isSaving || _isLoading || _products.isEmpty) return;

    setState(() => _isSaving = true);

    final success = await _service.saveTodayPreparedProducts(
      _selectedIds.toList(),
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '지금 준비된 반찬이 저장되었습니다!' : '저장에 실패했습니다. 다시 확인해주세요.',
        ),
      ),
    );

    if (success) {
      await _loadProducts();
    }
  }

  // 147-2-1단계: 지금 준비된 반찬 최대 20개 선택
  void _toggleProduct(int productId, bool checked) {
    if (checked &&
        !_selectedIds.contains(productId) &&
        _selectedIds.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지금 준비된 반찬은 최대 20개까지 선택할 수 있습니다.')),
      );
      return;
    }

    setState(() {
      if (checked) {
        _selectedIds.add(productId);
      } else {
        _selectedIds.remove(productId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('지금 준비된 반찬 관리'),
        backgroundColor: const Color(0xFF244C3A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? const Center(child: Text('상품을 불러오지 못했습니다.'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFF8F4E9),
                  child: Text(
                    '지금 준비된 반찬 ${_selectedIds.length}/20개 선택',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF244C3A),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];

                      return CheckboxListTile(
                        value: _selectedIds.contains(product.id),
                        title: Text(product.name),
                        subtitle: Text('${product.price}원'),
                        activeColor: const Color(0xFFF47B08),
                        onChanged: _isSaving
                            ? null
                            : (checked) {
                                _toggleProduct(product.id, checked ?? false);
                              },
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isLoading || _isSaving || _hasError || _products.isEmpty
                ? null
                : _saveProducts,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF244C3A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: Text(_isSaving ? '저장 중...' : '지금 준비된 반찬 저장'),
          ),
        ),
      ),
    );
  }
}
