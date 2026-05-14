import 'package:flutter/material.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() =>
      _ChatbotPageState();
}

class _ChatbotPageState
    extends State<ChatbotPage> {

  final TextEditingController controller =
      TextEditingController();

  final List<Map<String, dynamic>> messages = [];

  bool loading = false;

  Future<void> sendMessage() async {

    if (controller.text.trim().isEmpty) {
      return;
    }

    final message = controller.text.trim();

    setState(() {
      messages.add({
        'text': message,
        'isUser': true,
      });

      loading = true;
    });

    controller.clear();

    // TEMPORAL MOCK
    await Future.delayed(
      const Duration(seconds: 1),
    );

    setState(() {
      messages.add({
        'text':
            'Describe más detalles sobre el problema.',
        'isUser': false,
      });

      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      height:
          MediaQuery.of(context).size.height * .82,

      padding: const EdgeInsets.only(top: 12),

      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),

        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),

      child: Column(
        children: [

          Container(
            width: 50,
            height: 5,

            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),

          const SizedBox(height: 18),

          const Row(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [

              CircleAvatar(
                backgroundColor:
                    Color(0xFF2563EB),

                child: Icon(
                  Icons.support_agent,
                  color: Colors.white,
                ),
              ),

              SizedBox(width: 12),

              Text(
                'Asistente Virtual',

                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),

              itemCount: messages.length,

              itemBuilder: (_, index) {

                final message =
                    messages[index];

                final isUser =
                    message['isUser'];

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 280,
                    ),

                    margin:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),

                    padding:
                        const EdgeInsets.all(14),

                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(
                              0xFF2563EB,
                            )
                          : Colors.white,

                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      boxShadow: const [
                        BoxShadow(
                          color:
                              Color(0x12000000),

                          blurRadius: 8,

                          offset: Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Text(
                      message['text'],

                      style: TextStyle(
                        color: isUser
                            ? Colors.white
                            : const Color(
                                0xFF0F172A,
                              ),

                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (loading)
            const Padding(
              padding: EdgeInsets.only(
                bottom: 10,
              ),

              child:
                  CircularProgressIndicator(),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              20,
            ),

            decoration: const BoxDecoration(
              color: Colors.white,

              border: Border(
                top: BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),

            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: controller,

                    decoration:
                        InputDecoration(
                      hintText:
                          'Describe tu problema...',

                      filled: true,

                      fillColor:
                          const Color(
                        0xFFF1F5F9,
                      ),

                      border:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),

                        borderSide:
                            BorderSide.none,
                      ),

                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                InkWell(
                  onTap: sendMessage,

                  borderRadius:
                      BorderRadius.circular(30),

                  child: Container(
                    width: 54,
                    height: 54,

                    decoration:
                        const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),

                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
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