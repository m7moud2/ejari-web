import 'package:flutter/material.dart';
import 'ai_chat_screen.dart';

/// Wrapper screen for the AI Concierge feature.
/// It displays the [AiChatScreen] under the correct name.
class AiConciergeScreen extends StatelessWidget {
  const AiConciergeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AiChatScreen();
  }
}
