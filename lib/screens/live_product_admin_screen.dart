import 'package:flutter/material.dart';

import '../models/banchan_model.dart';
import '../services/banchan_service.dart';

class LiveProductAdminScreen extends StatefulWidget {
  const LiveProductAdminScreen({super.key});

  @override
  State<LiveProductAdminScreen> createState() => _LiveProductAdminScreenState();
}

class _LiveProductAdminScreenState extends State<LiveProductAdminScreen> {
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
        _selectedIds = products
            .where((product) => product.isLiveProduct)
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

    final success = await _service.saveLiveProducts(_selectedIds.toList());

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '오늘의 라이브 상품이 저장되었습니다!' : '저장에 실패했습니다. 다시 확인해주세요.',
        ),
      ),
    );

    if (success) {
      await _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 라이브 상품 관리'),
        backgroundColor: Colors.orangeAccent,
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
                  color: Colors.orange.shade50,
                  child: Text(
                    '오늘의 라이브 상품 ${_selectedIds.length}개 선택',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
                        activeColor: Colors.orange,
                        onChanged: _isSaving
                            ? null
                            : (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedIds.add(product.id);
                                  } else {
                                    _selectedIds.remove(product.id);
                                  }
                                });
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
            ),
            child: Text(_isSaving ? '저장 중...' : '선택한 라이브 상품 저장'),
          ),
        ),
      ),
    );
  }
}
