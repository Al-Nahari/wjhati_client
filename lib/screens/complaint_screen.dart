import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';


/// شاشة قائمة الدردشات
class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String chatsApiUrl = 'http://192.168.1.2:8000/chats';
  List<dynamic> chats = [];
  final int currentUserId = 1;
  Map<int, int> unreadCounts = {};

  @override
  void initState() {
    super.initState();
    fetchChats();
  }

  // دالة لجلب عدد الرسائل غير المقروءة لكل دردشة
  Future<int> getUnreadCountForChat(int chatId) async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.2:8000/messages/'));
      if (response.statusCode == 200) {
        List<dynamic> allMessages = json.decode(utf8.decode(response.bodyBytes));
        int count = allMessages.where((m) =>
        m['chat'] == chatId &&
            m['is_read'] == false &&
            m['sender'] != currentUserId).length;
        return count;
      }
      return 0;
    } catch (e) {
      print(e);
      return 0;
    }
  }

  // جلب الدردشات وتحديث عداد الرسائل غير المقروءة
  Future<void> fetchChats() async {
    try {
      final response = await http.get(Uri.parse(chatsApiUrl));
      if (response.statusCode == 200) {
        setState(() {
          chats = json.decode(utf8.decode(response.bodyBytes));
        });
        for (var chat in chats) {
          int chatId = chat['id'];
          getUnreadCountForChat(chatId).then((count) {
            setState(() {
              unreadCounts[chatId] = count;
            });
          });
        }
      } else {
        throw Exception('فشل في تحميل بيانات الدردشات');
      }
    } catch (e) {
      print(e);
    }
  }

  // تحويل قائمة المشاركين إلى نص مفصول بفواصل
  String formatParticipants(List<dynamic> participants) {
    return participants.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('قائمة الدردشات'),
      ),
      body: chats.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];
          final chatTitle = (chat['title'] != null &&
              chat['title'].toString().trim().isNotEmpty)
              ? chat['title']
              : 'دردشة رقم ${chat['id']}';
          int unreadCount = unreadCounts[chat['id']] ?? 0;
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListTile(
              contentPadding:
              EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              leading: CircleAvatar(
                backgroundColor: Colors.deepPurple,
                child: Icon(
                  chat['is_group'] ? Icons.group : Icons.person,
                  color: Colors.white,
                ),
              ),
              title: Text(
                chatTitle,
                style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  'المشاركون: ${formatParticipants(chat['participants'])}'),
              trailing: unreadCount > 0
                  ? Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              )
                  : Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () async {
                // عند فتح الدردشة، يتم تمرير البيانات والتحديث بعد العودة
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailScreen(
                      chatId: chat['id'],
                      chatTitle: chatTitle,
                    ),
                  ),
                );
                fetchChats();
              },
            ),
          );
        },
      ),
    );
  }
}

/// شاشة تفاصيل الدردشة
class ChatDetailScreen extends StatefulWidget {
  final int chatId;
  final String chatTitle;
  ChatDetailScreen({required this.chatId, required this.chatTitle});

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  late String messagesApiUrl;
  List<dynamic> messages = [];
  TextEditingController messageController = TextEditingController();
  final int currentUserId = 1;
  final ScrollController _scrollController = ScrollController();
  File? _selectedAttachment;

  @override
  void initState() {
    super.initState();
    messagesApiUrl = 'http://192.168.1.2:8000/messages/';
    fetchMessages();
  }

  // جلب الرسائل الخاصة بالدردشة وترتيبها تصاعدياً (الأقدم أولاً)
  Future<void> fetchMessages() async {
    try {
      final response = await http.get(Uri.parse(messagesApiUrl));
      if (response.statusCode == 200) {
        var allMessages =
        json.decode(utf8.decode(response.bodyBytes)) as List<dynamic>;
        setState(() {
          messages = allMessages
              .where((m) => m['chat'] == widget.chatId)
              .toList();
          messages.sort((a, b) => DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at'])));
        });
        // التمرير تلقائيًا إلى أحدث رسالة
        Future.delayed(Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
        markMessagesAsRead();
      } else {
        throw Exception('فشل في تحميل الرسائل');
      }
    } catch (e) {
      print(e);
    }
  }

  // تحديث حالة الرسائل غير المقروءة لتصبح مقروءة
  Future<void> markMessagesAsRead() async {
    for (var message in messages) {
      if (message['is_read'] == false && message['sender'] != currentUserId) {
        try {
          final response = await http.patch(
            Uri.parse(
                'http://192.168.1.2:8000/messages/${message['id']}/'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8'
            },
            body: json.encode({'is_read': true}),
          );
          if (response.statusCode == 200) {
            message['is_read'] = true;
          }
        } catch (e) {
          print(e);
        }
      }
    }
  }

  // دالة إرسال الرسالة (نصية أو مع مرفق)
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty && _selectedAttachment == null) return;
    try {
      if (_selectedAttachment != null) {
        var uri = Uri.parse(messagesApiUrl);
        var request = http.MultipartRequest("POST", uri);
        request.fields["content"] = content;
        request.fields["is_read"] = "false";
        request.fields["chat"] = widget.chatId.toString();
        request.fields["sender"] = currentUserId.toString();

        var stream = http.ByteStream(_selectedAttachment!.openRead());
        var length = await _selectedAttachment!.length();
        var multipartFile = http.MultipartFile(
          "attachment",
          stream,
          length,
          filename: p.basename(_selectedAttachment!.path),
        );
        request.files.add(multipartFile);

        var response = await request.send();
        if (response.statusCode == 201 || response.statusCode == 200) {
          fetchMessages();
          messageController.clear();
          setState(() {
            _selectedAttachment = null;
          });
        } else {
          throw Exception('فشل في إرسال الرسالة مع المرفق');
        }
      } else {
        final response = await http.post(
          Uri.parse(messagesApiUrl),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
          body: json.encode({
            "content": content,
            "attachment": null,
            "is_read": false,
            "chat": widget.chatId,
            "sender": currentUserId,
          }),
        );
        if (response.statusCode == 201 || response.statusCode == 200) {
          fetchMessages();
          messageController.clear();
        } else {
          throw Exception('فشل في إرسال الرسالة');
        }
      }
    } catch (e) {
      print(e);
    }
  }

  // اختيار صورة مع طلب صلاحيات الوصول
  Future<void> _pickImage() async {
    var status = await Permission.photos.request();
    if (status.isGranted) {
      final pickedFile =
      await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedAttachment = File(pickedFile.path);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لم يتم منح صلاحيات الوصول للصور')),
      );
    }
  }

  // اختيار ملف مع طلب صلاحيات الوصول
  Future<void> _pickFile() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAttachment = File(result.files.single.path!);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لم يتم منح صلاحيات الوصول للملفات')),
      );
    }
  }

  // عرض خيارات رفع المرفقات في BottomSheet
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.image,
                    color: Colors.deepPurple, size: 28),
                title: Text('اختيار صورة',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: Icon(Icons.insert_drive_file,
                    color: Colors.deepPurple, size: 28),
                title: Text('اختيار ملف',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16)),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // عرض معاينة للمرفق المُختار (صورة أو ملف)
  Widget _buildAttachmentPreview() {
    if (_selectedAttachment == null) return SizedBox.shrink();
    bool isImage = _selectedAttachment!.path.toLowerCase().endsWith(".png") ||
        _selectedAttachment!.path.toLowerCase().endsWith(".jpg") ||
        _selectedAttachment!.path.toLowerCase().endsWith(".jpeg") ||
        _selectedAttachment!.path.toLowerCase().endsWith(".gif");
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          isImage
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedAttachment!,
              height: 120,
              width: 120,
              fit: BoxFit.cover,
            ),
          )
              : Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.insert_drive_file,
                size: 50, color: Colors.grey[700]),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAttachment = null;
                });
              },
              child: CircleAvatar(
                radius: 12,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تصميم فقاعات الرسائل بنمط عصري
  Widget buildMessageItem(dynamic message) {
    bool isCurrentUser = message['sender'] == currentUserId;
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isCurrentUser
              ? LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : LinearGradient(
            colors: [Colors.grey.shade300, Colors.grey.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft:
            isCurrentUser ? Radius.circular(20) : Radius.circular(0),
            bottomRight:
            isCurrentUser ? Radius.circular(0) : Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isCurrentUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message['content'],
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
              textAlign: isCurrentUser ? TextAlign.right : TextAlign.left,
            ),
            SizedBox(height: 6),
            Text(
              message['created_at'],
              style: TextStyle(fontSize: 10, color: Colors.black54),
            ),
            if (message['attachment'] != null) ...[
              SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message['attachment'],
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      'خطأ في تحميل الملف',
                      style: TextStyle(
                        color: isCurrentUser
                            ? Colors.white
                            : Colors.black,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(vertical: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return buildMessageItem(message);
              },
            ),
          ),
          _buildAttachmentPreview(),
          Divider(height: 1),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.attach_file,
                      color: Colors.deepPurple, size: 28),
                  onPressed: _showAttachmentOptions,
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    style: TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple, Colors.deepPurpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () => sendMessage(messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
