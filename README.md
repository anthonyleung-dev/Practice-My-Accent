# Practice My Accent

A Flutter application designed to help users practice and improve their English pronunciation with AI-powered feedback through conversations with Gemini AI.

*README in other languages:  [繁體中文](README_zh_HK.md) | [简体中文](README_zh.md)*

## Features

- **AI-Powered Accent Analysis**: Get real-time feedback on your pronunciation using Google's Gemini AI.
- **Voice Activity Detection (VAD)**: Automatically detects when you start and stop speaking for a natural conversation experience.
- **Continuous Conversation Mode**: Have natural conversations with automatic speech segmentation - the app detects pauses in your speech and creates new segments accordingly.
- **Multiple Accent Options**: Practice various English accents including American, British, Australian, Canadian, Irish, and New Zealand.
<!-- - **Multilingual Interface**: Available in English, Simplified Chinese, Traditional Chinese (Taiwan), and Traditional Chinese (Hong Kong). -->
- **Voice Messaging**: Record, playback, and analyze voice messages with AI feedback.

## Getting Started

### Prerequisites

- Flutter SDK (^3.7.0)
- Google Gemini API key (obtain from [Google AI Studio](https://aistudio.google.com/apikey))
- Microphone access permission

### Installation

1. Clone the repository:

   ```
   git clone https://github.com/yourusername/practice_my_accent.git
   ```

2. Navigate to the project directory:

   ```
   cd practice_my_accent
   ```

3. Install dependencies:

   ```
   flutter pub get
   ```

4. Run the app:
   ```
   flutter run
   ```

## Usage

1. **First Launch**: Select your target accent and enter your Google API key.
2. **Practice Mode**: Tap "Start Practicing" on the home screen to begin.
3. **Recording**: Press the "Start talking to your teacher" button to begin a conversation.
4. **Conversation Mode**: The app automatically segments your speech when you pause, allowing for natural conversation flow. Each segment appears as a separate message in the chat.
5. **AI Feedback**: Receive AI-powered feedback on your pronunciation from Gemini.
6. **Stop Recording**: Press "Stop talking to your teacher" to end the conversation.

## Technologies Used

- Flutter for cross-platform mobile development
- Google Gemini AI for speech analysis and conversation
- WebSockets for real-time communication
- Flutter Sound for audio recording and playback
- Shared Preferences for local storage

## Languages Supported

- English (en)
- Simplified Chinese (zh)
- Traditional Chinese (Taiwan) (zh_TW)
- Traditional Chinese (Hong Kong) (zh_HK)

## Credits

This application was developed collaboratively by Cursor agent mode + Claude 3.7 + MCP and a small potato developer.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Google Gemini for providing the AI capabilities
- Flutter team for the excellent framework
- All contributors who have helped improve this application
