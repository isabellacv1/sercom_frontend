import 'package:flutter/material.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF5F6FA);
    const primaryColor = Color(0xFF3366E8);
    const textDark = Color(0xFF101828);
    const textSoft = Color(0xFF6B7A99);
    const borderColor = Color(0xFFD9DEE8);
    const orangeColor = Color(0xFFFF8A00);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: textDark,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: const [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryColor,
                        child: Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'TaskRank',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 34),
              const Text(
                '¿Quién eres?',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 18),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: textSoft,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(text: 'Elige cómo quieres usar '),
                    TextSpan(
                      text: 'TaskRank',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    TextSpan(text: ' hoy.'),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              _RoleCard(
                title: 'Busco un servicio',
                description: 'Necesito ayuda con una tarea o misión urgente.',
                buttonColor: primaryColor,
                emoji: '🧑‍💼',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/register',
                    arguments: 'client',
                  );
                },
              ),
              const SizedBox(height: 26),
              _RoleCard(
                title: 'Soy trabajador',
                description: 'Quiero realizar misiones y ganar dinero.',
                buttonColor: orangeColor,
                emoji: '👨‍🔧',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/register',
                    arguments: 'worker',
                  );
                },
              ),
              const Spacer(),
              const Center(
                child: Text(
                  'Selecciona tu tipo de cuenta para continuar con el registro.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSoft,
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final Color buttonColor;
  final String emoji;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.buttonColor,
    required this.emoji,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFD9DEE8);
    const textDark = Color(0xFF101828);
    const textSoft = Color(0xFF6B7A99);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 150,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.4,
                      color: textSoft,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(40),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: buttonColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: buttonColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            emoji,
            style: const TextStyle(fontSize: 82),
          ),
        ],
      ),
    );
  }
}