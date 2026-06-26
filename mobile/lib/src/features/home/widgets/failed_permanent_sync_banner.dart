import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/repositories/sync_repository.dart';
import '../home_providers.dart';

class FailedPermanentSyncBanner extends ConsumerWidget {
  final int count;
  const FailedPermanentSyncBanner({super.key, required this.count});

  void _showDiscardConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận hủy bỏ'),
        content: const Text(
          'Các bài làm này sẽ bị xóa khỏi thiết bị và không được đồng bộ lên hệ thống. Hành động này không thể hoàn tác. Bạn có chắc chắn muốn hủy?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Quay lại'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Đóng confirm dialog
              await ref.read(syncRepositoryProvider).discardFailedPermanentAttempts();
              ref.invalidate(courseHomeProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Đồng ý hủy'),
          ),
        ],
      ),
    );
  }

  void _showErrorActionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lỗi đồng bộ dữ liệu'),
        content: Text(
          'Hệ thống không thể tự động đồng bộ $count bài làm vì dữ liệu không còn hợp lệ hoặc máy chủ từ chối xử lý.\n\n'
          'Bạn có thể thử đồng bộ lại sau khi dữ liệu/ứng dụng đã được cập nhật, hoặc hủy bỏ các bài làm lỗi này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showDiscardConfirmDialog(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hủy bỏ bài làm lỗi'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang thử đồng bộ lại...')),
              );
              try {
                await ref.read(syncRepositoryProvider).resetFailedPermanentAttempts();
                await ref.read(syncRepositoryProvider).syncPendingAttempts();
                ref.invalidate(courseHomeProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đồng bộ thất bại: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Thử đồng bộ lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showErrorActionDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red.shade900),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Có $count bài làm bị lỗi đồng bộ vĩnh viễn. Nhấp để xử lý.',
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.red.shade900),
          ],
        ),
      ),
    );
  }
}
