class AIProvider {
  final String id;
  final String name;
  final String logo;
  final String description;

  AIProvider({
    required this.id,
    required this.name,
    required this.logo,
    required this.description,
  });

  static List<AIProvider> getProviders() {
    return [
      AIProvider(
        id: 'chatgpt',
        name: 'ChatGPT 4',
        logo: '🤖',
        description: 'OpenAI\'s ChatGPT for accent analysis and feedback',
      ),
      AIProvider(
        id: 'google',
        name: 'Gemini 2.0 Stream Live',
        logo: '🔍',
        description: 'Google\'s Gemini 2.0 Stream Live API for real-time accent analysis and feedback',
      ),
    ];
  }
} 