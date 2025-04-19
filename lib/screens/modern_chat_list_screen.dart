import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shimmer/shimmer.dart';
import '../services/AuthService.dart';
import '../services/ip.dart';

// 1. تعريف ثيم التطبيق خارج أي كلاس
const ColorScheme _appColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xff2d4960),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFEADDFF),
  onPrimaryContainer: Color(0xFF005C88),
  secondary: Color(0xB8406887),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFE8DEF8),
  onSecondaryContainer: Color(0xFF1D192B),
  tertiary: Color(0xff2d4960),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFFFFD8E4),
  onTertiaryContainer: Color(0xFF31111D),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  background: Color(0xFFFFFBFE),
  onBackground: Color(0xFF1C1B1F),
  surface: Color(0xFFFFFBFE),
  onSurface: Color(0xFF1C1B1F),
  surfaceVariant: Color(0xFFE7E0EC),
  onSurfaceVariant: Color(0xFF49454E),
  outline: Color(0xFF79747E),
  outlineVariant: Color(0xFFCAC4D0),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  inverseSurface: Color(0xFF313033),
  onInverseSurface: Color(0xFFF4EFF4),
  inversePrimary: Color(0xFFD0BCFF),
  surfaceTint: Color(0xFF6750A4),
);

/// 2. شاشة قائمة الدردشات المطورة
class ModernChatListScreen extends StatelessWidget {
  const ModernChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحادثات'),
        centerTitle: true,
      ),
      body: _ChatListBody(),
    );
  }
}

class _ChatListBody extends StatefulWidget {
  @override
  State<_ChatListBody> createState() => _ChatListBodyState();
}

class _ChatListBodyState extends State<_ChatListBody> {
  final String _chatsApiUrl = '${ips.apiUrl}chats';
  List<dynamic> _chats = [];
  bool _isLoading = true;
  bool _hasError = false;
  final int _currentUserId = 1;
  final Map<int, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      await AuthService.refreshToken();
      final headers = await AuthService.getAuthHeader();
      final response = await http.get(Uri.parse('${ips.apiUrl}chats/'), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        _updateUnreadCounts(data);
        setState(() {
          _chats = data;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        _handleError('فشل في تحميل البيانات: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Future<void> _updateUnreadCounts(List<dynamic> chats) async {
    for (final chat in chats) {
      final count = await _getUnreadCount(chat['id']);
      _unreadCounts[chat['id']] = count;
    }
  }

  Future<int> _getUnreadCount(int chatId) async {
    try {
      await AuthService.refreshToken();
      final headers = await AuthService.getAuthHeader();
      final response = await http.get(Uri.parse('${ips.apiUrl}messages/'), headers: headers);
      if (response.statusCode == 200) {
        final messages = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        return messages.where((m) =>
        m['chat'] == chatId &&
            !m['is_read'] &&
            m['sender'] != _currentUserId
        ).length;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  void _handleError(String message) {
    debugPrint(message);
    setState(() {
      _isLoading = false;
      _hasError = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) return _ErrorView(onRetry: _loadChats);
    if (_isLoading) return _LoadingShimmer();
    return _ChatListView(chats: _chats, unreadCounts: _unreadCounts);
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 20),
          const Text('حدث خطأ في تحميل البيانات'),
          TextButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, index) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _ChatListView extends StatelessWidget {
  final List<dynamic> chats;
  final Map<int, int> unreadCounts;

  const _ChatListView({
    required this.chats,
    required this.unreadCounts,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => context.findAncestorStateOfType<_ChatListBodyState>()?._loadChats(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: chats.length,
        itemBuilder: (_, index) => _ChatListItem(
          chat: chats[index],
          unreadCount: unreadCounts[chats[index]['id']] ?? 0,
        ),
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final dynamic chat;
  final int unreadCount;

  const _ChatListItem({
    required this.chat,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _ChatAvatar(isGroup: chat['is_group'], unreadCount: unreadCount),
      title: Text(
        chat['title'] ?? 'الدردشة ${chat['id']}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: unreadCount > 0
          ? _UnreadBadge(count: unreadCount)
          : const Icon(Icons.chevron_right),
      onTap: () => _openChat(context),
    );
  }

  String _formatParticipants(List<dynamic> participants) {
    if (participants.length > 3) {
      return '${participants.take(3).join(', ')} +${participants.length - 3}';
    }
    return participants.join(', ');
  }

  void _openChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModernChatScreen(
          chatId: chat['id'],
          title: chat['title'] ?? 'الدردشة ${chat['id']}',
        ),
      ),
    );
  }
}

class _ChatAvatar extends StatelessWidget {
  final bool isGroup;
  final int unreadCount;

  const _ChatAvatar({
    required this.isGroup,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _appColorScheme.secondary,
          child: Icon(
            isGroup ? Icons.group : Icons.person,
            color: _appColorScheme.onSecondary,
            size: 28,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _appColorScheme.error,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _appColorScheme.surface,
                  width: 2,
                ),
              ),
              child: Text(
                unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _appColorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 3. شاشة الدردشة المطورة
class ModernChatScreen extends StatefulWidget {
  final int chatId;
  final String title;

  const ModernChatScreen({
    super.key,
    required this.chatId,
    required this.title,
  });

  @override
  State<ModernChatScreen> createState() => _ModernChatScreenState();
}

class _ModernChatScreenState extends State<ModernChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final int _currentUserId = 1;
  File? _selectedAttachment;
  List<dynamic> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      await AuthService.refreshToken();
      final headers = await AuthService.getAuthHeader();
      final response = await http.get(Uri.parse('${ips.apiUrl}messages/'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;
        setState(() {
          _messages = data
              .where((m) => m['chat'] == widget.chatId)
              .toList()
            ..sort((a, b) =>
                DateTime.parse(a['created_at']).compareTo(
                  DateTime.parse(b['created_at']),
                ),
            );
        });
        _scrollToBottom();
        _markMessagesAsRead();
      }
    } catch (e) {
      _showError('فشل في تحميل الرسائل');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markMessagesAsRead() async {
    try {
      for (final message in _messages) {
        if (!message['is_read'] && message['sender'] != _currentUserId) {
          final response = await http.patch(
            Uri.parse('${ips.apiUrl}messages/${message['id']}/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'is_read': true}),
          );

          if (response.statusCode == 200) {
            setState(() => message['is_read'] = true);
          }
        }
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty && _selectedAttachment == null) return;

    setState(() => _isSending = true);

    try {
      if (_selectedAttachment != null) {
        await _sendFileMessage();
      } else {
        await _sendTextMessage();
      }
    } catch (e) {
      _showError('فشل في إرسال الرسالة');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendTextMessage() async {
    final response = await http.post(
      Uri.parse('${ips.apiUrl}messages/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'content': _messageController.text,
        'chat': widget.chatId,
        'sender': _currentUserId,
        'is_read': false,
      }),
    );

    if (response.statusCode == 201) {
      _messageController.clear();
      await _loadMessages();
    } else {
      throw Exception('Failed to send text message');
    }
  }

  Future<void> _sendFileMessage() async {
    await AuthService.refreshToken();
    final headers = await AuthService.getAuthHeader();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ips.apiUrl}messages/'),
    );

    request.fields.addAll({
      'chat': widget.chatId.toString(),
      'sender': _currentUserId.toString(),
      'is_read': 'false',
      'content': _messageController.text,
    });

    final file = await http.MultipartFile.fromPath(
      'attachment',
      _selectedAttachment!.path,
      filename: p.basename(_selectedAttachment!.path),
    );

    request.files.add(file);

    final response = await request.send();
    if (response.statusCode == 201) {
      _messageController.clear();
      setState(() => _selectedAttachment = null);
      await _loadMessages();
    } else {
      throw Exception('Failed to send file message');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() => _selectedAttachment = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackbar('تعذر اختيار الصورة');
      if (e is PlatformException && e.code == 'photo_access_denied') {
        await _handleImagePermissionDenied();
      }
    }
  }
  Future<void> _handleImagePermissionDenied() async {
    final status = await Permission.photos.status;
    if (status.isPermanentlyDenied) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('صلاحية مطلوبة'),
          content: const Text('الرجاء منح صلاحية الوصول إلى الصور من الإعدادات'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                await openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('فتح الإعدادات'),
            ),
          ],
        ),
      );
    }
  }
  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedAttachment = File(result.files.single.path!));
      }
    } catch (e) {
      debugPrint('Error picking file: $e');
      _showError('تعذر اختيار الملف');
    }
  }
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _appColorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, index) => _MessageBubble(
                message: _messages[index],
                isMe: _messages[index]['sender'] == _currentUserId,
              ),
            ),
          ),
          if (_selectedAttachment != null) _SelectedAttachmentPreview(
            file: _selectedAttachment!,
            onRemove: () => setState(() => _selectedAttachment = null),
          ),
          _MessageInput(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
            onAttach: _showAttachmentOptions,
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('صورة من المعرض'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final dynamic message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? _appColorScheme.primary : _appColorScheme.secondary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message['attachment'] != null)
              _AttachmentPreview(url: message['attachment']),
            Text(
              message['content'] ?? '',
              style: TextStyle(
                color: isMe ? _appColorScheme.onPrimary : _appColorScheme.onSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(message['created_at']),
              style: TextStyle(
                color: isMe
                    ? _appColorScheme.onPrimary.withOpacity(0.8)
                    : _appColorScheme.onSecondary.withOpacity(0.8),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _AttachmentPreview extends StatelessWidget {
  final String url;

  const _AttachmentPreview({required this.url});

  @override
  Widget build(BuildContext context) {
    final isImage = url.endsWith('.jpg') || url.endsWith('.png') || url.endsWith('.jpeg');

    return GestureDetector(
      onTap: () => _showFullScreen(context, url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white30),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isImage
              ? Image.network(
            url,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Container(
                height: 150,
                color: Colors.grey[200],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
          )
              : const SizedBox(
            height: 80,
            child: Center(
              child: Icon(Icons.insert_drive_file, size: 40),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(url),
        ),
      ),
    );
  }
}

class _SelectedAttachmentPreview extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;

  const _SelectedAttachmentPreview({
    required this.file,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _appColorScheme.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.attach_file),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              p.basename(file.path),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  const _MessageInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onAttach,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _appColorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: onAttach,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                filled: true,
                fillColor: _appColorScheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSending
                  ? null
                  : LinearGradient(
                colors: [
                  _appColorScheme.primary,
                  _appColorScheme.primary.withOpacity(0.8),
                ],
              ),
            ),
            child: IconButton(
              icon: isSending
                  ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
                  : const Icon(Icons.send, color: Colors.white),
              onPressed: isSending ? null : onSend,
            ),
          ),
        ],
      ),
    );
  }
}
