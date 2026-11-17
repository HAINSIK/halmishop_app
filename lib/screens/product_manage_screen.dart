import 'package:flutter/material.dart';

import '../models/banchan_model.dart';
import '../services/banchan_service.dart';
import 'product_edit_screen.dart';

class ProductManageScreen extends StatefulWidget {
  const ProductManageScreen({super.key});

  @override
  State<ProductManageScreen> createState() => _ProductManageScreenState();
}

class _ProductManageScreenState extends State<ProductManageScreen> {
  final BanchanService _banchanService = BanchanService();

  List<Banchan> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    final products = await _banchanService.fetchBanchanList();

    if (!mounted) return;

    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF2),
      appBar: AppBar(
        title: const Text('상품 수정·관리'),
        backgroundColor: const Color(0xFF1F4D3A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProducts,

              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  24 + MediaQuery.of(context).viewPadding.bottom,
                ),
                children: [
                  const Text(
                    '등록된 상품 목록',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '총 ${_products.length}개 상품',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ..._products.map(
                    (product) => Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                          '${product.category} · ${product.price}원',
                        ),
                        trailing: const Icon(Icons.chevron_right),

                        onTap: () async {
                          // 149-3-29단계: 상품 수정 결과 확인
                          final updated = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductEditScreen(product: product),
                            ),
                          );

                          if (!mounted) return;

                          // 상품 수정에 성공한 경우 최신 목록 다시 조회
                          if (updated == true) {
                            await _loadProducts();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
