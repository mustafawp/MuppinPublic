/*import 'package:flutter/material.dart';

class DenemeBosSinif extends StatelessWidget {
  const DenemeBosSinif({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          const BubbleNormalImage(
            id: 'id001',
            image: Image(image: AssetImage("assets/images/default.png")),
            color: Colors.transparent,
            tail: true,
            delivered: true,
          ),
          const SizedBox(
            height: 25,
          ),
          BubbleNormalAudio(
            color: const Color.fromARGB(255, 112, 35, 112),
            textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            duration: duration.inSeconds.toDouble(),
            position: position.inSeconds.toDouble(),
            isPlaying: isPlaying,
            isLoading: isLoading,
            isPause: isPause,
            onSeekChanged: (value) {},
            onPlayPauseButtonClick: () {},
            seen: false,
            sent: true,
          ),
          const SizedBox(
            height: 25,
          ),
          BubbleNormal(
            text: 'merhaba nasılsın napıon',
            isSender: true,
            color: const Color.fromARGB(255, 112, 35, 112),
            textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            tail: true,
            sent: true,
            seen: false,
          ),
          const SizedBox(
            height: 10,
          ),
          DateChip(
            color: Colors.grey,
            date: DateTime(now.year, now.month, now.day - 2),
          ),
          const SizedBox(
            height: 10,
          ),
          BubbleNormal(
            text: 'merhaba nasılsın napıon',
            isSender: true,
            color: const Color.fromARGB(255, 112, 35, 112),
            textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            tail: true,
            seen: true,
          ),
          const BubbleSpecialOne(
            text: 'selammmmmmm',
            tail: false,
            color: Color.fromARGB(255, 112, 35, 112),
            textStyle: TextStyle(color: Colors.white, fontSize: 16),
            seen: true,
          ),
          const BubbleSpecialOne(
            text: 'nasılsın napıyorsun?',
            tail: false,
            color: Color.fromARGB(255, 112, 35, 112),
            textStyle: TextStyle(color: Colors.white, fontSize: 16),
            seen: true,
          ),
          const SizedBox(
            height: 5,
          ),
          BubbleNormal(
            text: 'merhaba iyiyimm',
            isSender: false,
            textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            color: const Color.fromARGB(255, 67, 67, 67),
            tail: true,
          ),
          const BubbleSpecialOne(
            text: 'hiç öylesine takılıyordumm',
            tail: false,
            isSender: false,
            textStyle: TextStyle(color: Colors.white, fontSize: 16),
            color: Color.fromARGB(255, 67, 67, 67),
          ),
          const BubbleSpecialOne(
            text: 'sen nasılsın napıyorsun?',
            tail: false,
            isSender: false,
            textStyle: TextStyle(color: Colors.white, fontSize: 16),
            color: Color.fromARGB(255, 67, 67, 67),
          ),
          const BubbleSpecialOne(
            text: 'sen nasılsın napıyorsun?',
            tail: false,
            isSender: false,
            textStyle: TextStyle(color: Colors.white, fontSize: 16),
            color: Color.fromARGB(255, 67, 67, 67),
          ),
          const BubbleSpecialOne(
            text: 'sen nasılsın napıyorsun?',
            tail: false,
            isSender: false,
            textStyle: TextStyle(color: Colors.white, fontSize: 16),
            color: Color.fromARGB(255, 67, 67, 67),
          ),
          const BubbleSpecialOne(
            text: 'sen nasılsın napıyorsun?',
            tail: false,
            isSender: false,
            textStyle: TextStyle(color: Colors.white, fontSize: 16),
            color: Color.fromARGB(255, 67, 67, 67),
          ),
          SizedBox(
            height: 10,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin:
                      const EdgeInsets.only(bottom: 8.0, left: 10.0, right: 10),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 73, 47, 85),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(Icons.emoji_emotions,
                            color: Colors.white),
                        onPressed: () {
                          //_toggleEmojiPicker();
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _textEditingController,
                          maxLines:
                              null, // Birden fazla satır kullanmak için null olarak ayarlandı
                          keyboardType: TextInputType
                              .multiline, // Birden fazla satır kullanmak için gerekli
                          decoration: InputDecoration(
                            hintText: isSendButtonVisible ? '' : 'Mesaj',
                            hintStyle: const TextStyle(color: Colors.grey),
                            contentPadding:
                                const EdgeInsets.all(8), // İçerik içi boşluğu
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (text) {
                            setState(() {
                              isSendButtonVisible = text.isNotEmpty;
                            });
                          },
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.attach_file, color: Colors.white),
                        onPressed: () {
                          //_toggleFilePicker();
                        },
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.photo_camera, color: Colors.white),
                        onPressed: () {
                          // Handle camera button press
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/
