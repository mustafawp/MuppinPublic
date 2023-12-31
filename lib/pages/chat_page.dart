import 'package:flutter/material.dart';
import 'package:muppin_app/services/chat/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverDocId;
  final dynamic receiverPp;
  final String receiverUsername;
  const ChatPage(
      {super.key,
      required this.receiverDocId,
      required this.receiverPp,
      required this.receiverUsername});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();

  final msgController = TextEditingController();
  bool isSendButtonVisible = false;

  void sendNewMsg() async {
    String message = msgController.text;
    if (message.isNotEmpty) {
      setState(() {
        msgController.clear();
        isSendButtonVisible = false;
      });
      await _chatService.sendMessage(widget.receiverDocId, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 32, 32, 32),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(154, 73, 47, 85),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
        ),
        title: const Align(
            alignment: Alignment.centerLeft, child: Text("mustafawiped")),
      ),
      body: Column(
        children: [
          // Mesajlar listesini oluştur
          const Expanded(
            child: Text("za"), //_buildMessageList(),
          ),

          // Mesaj gönderme butonu
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  margin:
                      const EdgeInsets.only(bottom: 8.0, left: 10.0, right: 3),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(154, 73, 47, 85),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions,
                            color: Colors.white),
                        onPressed: () {
                          //Emoji Butonu
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: msgController,
                          minLines: 1,
                          maxLines: 4,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            hintText: 'Mesajınızı buraya yazın...',
                            hintStyle: TextStyle(color: Colors.grey),
                            contentPadding: EdgeInsets.all(6),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                          onChanged: (text) {
                            setState(() {
                              isSendButtonVisible = text.isNotEmpty;
                            });
                          },
                        ),
                      ),
                      if (!isSendButtonVisible)
                        IconButton(
                          icon: const Icon(Icons.attach_file,
                              color: Colors.white),
                          onPressed: () {
                            //resim eklemece
                          },
                        ),
                      if (!isSendButtonVisible)
                        IconButton(
                          icon: const Icon(Icons.photo_camera,
                              color: Colors.white),
                          onPressed: () {
                            // kamera buton
                          },
                        ),
                    ],
                  ),
                ),
              ),
              isSendButtonVisible
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 8, right: 5),
                      child: GestureDetector(
                        onTap: () => sendNewMsg,
                        child: Container(
                          width: 50.0,
                          height: 45.0,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color.fromARGB(154, 73, 47, 85),
                          ),
                          padding: const EdgeInsets.all(5.0),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 24.0,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        ],
      ),
    );
  }
}
