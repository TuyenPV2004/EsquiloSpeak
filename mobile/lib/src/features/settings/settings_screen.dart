import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Nhóm tài khoản
          _buildSectionHeader('Tài khoản'),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text('Tài khoản Khách (Guest)'),
            subtitle: const Text('ID: guest_user_001'),
            trailing: TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng đăng ký đang phát triển.'),
                  ),
                );
              },
              child: const Text('Liên kết'),
            ),
          ),
          const Divider(),
          
          // Cài đặt chung
          _buildSectionHeader('Cài đặt học tập'),
          const ListTile(
            leading: Icon(Icons.language_rounded),
            title: Text('Ngôn ngữ nguồn'),
            subtitle: Text('Tiếng Việt (vi)'),
          ),
          const ListTile(
            leading: Icon(Icons.flag_rounded),
            title: Text('Ngôn ngữ đích'),
            subtitle: Text('Tiếng Anh (en)'),
          ),
          const Divider(),
          
          // Tùy chọn hệ thống
          _buildSectionHeader('Hệ thống'),
          ListTile(
            leading: const Icon(Icons.restart_alt_rounded),
            title: const Text('Đặt lại hướng dẫn (Reset Onboarding)'),
            subtitle: const Text('Quay lại màn khảo sát lúc đầu.'),
            onTap: () {
              // Quay lại Onboarding
              context.go('/');
            },
          ),
          const ListTile(
            leading: Icon(Icons.info_outline_rounded),
            title: Text('Phiên bản ứng dụng'),
            subtitle: Text('1.0.0 (MVP)'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
    );
  }
}
