import 'package:flutter/material.dart';

class NoticeListScreen extends StatelessWidget {
  final List<dynamic> notices;

  const NoticeListScreen({super.key, required this.notices});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF244C3A),
        foregroundColor: Colors.white,
        title: const Text(
          '공지사항',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: notices.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final notice = notices[index];

          final title = notice['title']?.toString() ?? '공지사항';

          final rawDate = notice['createdAt']?.toString() ?? '';

          final date = DateTime.tryParse(rawDate);

          final formattedDate = date == null
              ? ''
              : '${date.year}.'
                    '${date.month.toString().padLeft(2, '0')}.'
                    '${date.day.toString().padLeft(2, '0')}';

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
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              },

              leading: const Icon(
                Icons.campaign_outlined,
                color: Color(0xFFF47B08),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF244C3A),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                formattedDate,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF244C3A),
              ),
            ),
          );
        },
      ),
    );
  }
}
