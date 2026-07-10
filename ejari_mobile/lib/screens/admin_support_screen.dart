import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/support_service.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  List<Map<String, dynamic>> _tickets = [];
  bool _isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tickets = await SupportService.getAllTickets();
    if (!mounted) return;
    setState(() {
      _tickets = tickets;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'all') return _tickets;
    return _tickets.where((t) => t['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('صندوق الدعم (${_tickets.length})'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      _chip('الكل', 'all'),
                      _chip('مفتوحة', 'open'),
                      _chip('قيد المعالجة', 'in_progress'),
                      _chip('تم الحل', 'resolved'),
                    ],
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(
                          child: Text('لا توجد تذاكر دعم',
                              style: TextStyle(color: AppTheme.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _buildTicketCard(_filtered[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status']?.toString() ?? 'open';
    final color = status == 'resolved'
        ? AppTheme.successColor
        : status == 'in_progress'
            ? AppTheme.primaryColor
            : AppTheme.accentColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openTicket(ticket),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket['subject']?.toString() ?? 'بدون عنوان',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      SupportService.statusLabelAr(status),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                ticket['userName']?.toString() ?? ticket['userEmail']?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticket['message']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 8),
              Text(
                ticket['id']?.toString() ?? '',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTicket(Map<String, dynamic> ticket) async {
    final fresh =
        await SupportService.getTicketById(ticket['id']?.toString() ?? '');
    if (fresh == null) return;
    ticket = fresh;

    final replyController = TextEditingController();
    final admin = await AuthService.getCurrentUser();
    final adminEmail = admin?['email']?.toString() ?? SupportService.adminEmail;

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ticket['subject']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ticket['userName']} — ${ticket['userEmail']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(ticket['message']?.toString() ?? ''),
                const SizedBox(height: 12),
                if ((ticket['replies'] as List?)?.isNotEmpty == true) ...[
                  const Divider(),
                  const Text('الردود',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...(ticket['replies'] as List).map((r) {
                    final reply = r as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${reply['senderName']}: ${reply['text']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: reply['isAdmin'] == true
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: replyController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'رد الإدارة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final text = replyController.text.trim();
                        if (text.isEmpty) return;
                        await SupportService.addReply(
                          ticketId: ticket['id'].toString(),
                          senderEmail: adminEmail,
                          senderName: 'دعم إيجاري',
                          text: text,
                          isAdmin: true,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      },
                      icon: const Icon(Icons.reply_rounded),
                      label: const Text('إرسال رد'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await SupportService.updateStatus(
                            ticket['id'].toString(), 'in_progress');
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      },
                      child: const Text('قيد المعالجة'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await SupportService.updateStatus(
                            ticket['id'].toString(), 'resolved');
                        if (ctx.mounted) Navigator.pop(ctx);
                        _load();
                      },
                      child: const Text('تم الحل'),
                    ),
                    if (ticket['chatId'] != null)
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                chatId: ticket['chatId'].toString(),
                                otherUserName:
                                    ticket['userName']?.toString() ??
                                        ticket['userEmail']?.toString() ??
                                        'مستخدم',
                                currentUserId: adminEmail,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_rounded),
                        label: const Text('فتح الشات'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    replyController.dispose();
  }
}
