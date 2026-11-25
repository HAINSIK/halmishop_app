import 'package:flutter/material.dart';

// 149-2-2-1단계: 기존 관리자 화면 연결
import 'product_register_screen.dart';
import 'live_product_admin_screen.dart';
import 'recommended_product_admin_screen.dart';
import 'today_prepared_admin_screen.dart';
import 'admin_notice_screen.dart';
import 'admin_banner_screen.dart';
import 'product_manage_screen.dart';
import 'admin_product_bulk_upload_screen.dart';

// 149-2-1단계: 젊은할미 관리자센터 메인 화면
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('젊은할미 관리자센터'),
        backgroundColor: const Color(0xFF1F4D3A),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF8F7F2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE7EFE9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '젊은할미 쇼핑몰 운영',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F4D3A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '상품과 쇼핑몰 운영 기능을 관리합니다.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildSectionTitle('상품 관리'),
            const SizedBox(height: 12),

            _buildMenuTile(
              context: context,
              icon: Icons.add_box_outlined,
              title: '상품 등록',
              subtitle: '새로운 반찬 상품 등록',
            ),

            _buildMenuTile(
              context: context,
              icon: Icons.upload_file_outlined,
              title: '상품 일괄등록',
              subtitle: '엑셀 상품정보 및 ZIP 상품사진 일괄등록',
            ),

            _buildMenuTile(
              context: context,
              icon: Icons.inventory_2_outlined,
              title: '상품 수정·관리',
              subtitle: '등록된 상품 정보 및 이미지 관리',
            ),

            _buildMenuTile(
              context: context,
              icon: Icons.live_tv_outlined,
              title: '라이브 상품 관리',
              subtitle: '라이브 방송 상품 선택',
            ),

            _buildMenuTile(
              context: context,
              icon: Icons.star_outline,
              title: '추천 반찬 관리',
              subtitle: '홈 화면 추천 상품 설정',
            ),

            _buildMenuTile(
              context: context,
              icon: Icons.restaurant_menu_outlined,
              title: '지금 준비된 반찬 관리',
              subtitle: '준비된 반찬 목록 설정',
            ),

            const SizedBox(height: 24),
            _buildSectionTitle('쇼핑몰 운영'),
            const SizedBox(height: 12),

            _buildMenuTile(
              context: context,
              icon: Icons.campaign_outlined,
              title: '공지사항 관리',
              subtitle: '공지사항 등록 및 수정',
            ),
            _buildMenuTile(
              context: context,
              icon: Icons.view_carousel_outlined,
              title: '배너 관리',
              subtitle: '메인 배너 등록 및 관리',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F4D3A),
      ),
    );
  }

  // 149-2-2-2단계: 관리자 메뉴 화면 이동을 위한 context 전달
  Widget _buildMenuTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () async {
          if (title == '상품 등록') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductRegisterScreen(),
              ),
            );
          } else if (title == '상품 일괄등록') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminProductBulkUploadScreen(),
              ),
            );
          } else if (title == '상품 수정·관리') {
            // 149-3-17단계: 상품 수정·관리 화면 연결
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductManageScreen(),
              ),
            );
          } else if (title == '라이브 상품 관리') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LiveProductAdminScreen(),
              ),
            );
          } else if (title == '추천 반찬 관리') {
            // 149-2-2-9단계: 추천 반찬 관리 화면 연결
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RecommendedProductAdminScreen(),
              ),
            );
          } else if (title == '지금 준비된 반찬 관리') {
            // 149-2-2-11단계: 지금 준비된 반찬 관리 연결
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const TodayPreparedAdminScreen(),
              ),
            );
          } else if (title == '공지사항 관리') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminNoticeScreen(),
              ),
            );
          } else if (title == '배너 관리') {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminBannerScreen(),
              ),
            );
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: const Color(0xFFF47B08), size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Colors.black38),
      ),
    );
  }
}
