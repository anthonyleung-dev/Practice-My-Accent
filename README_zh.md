# 练习我的口音

这是一款 Flutter 应用程序，旨在通过与 Gemini AI 的对话，帮助用户练习并提高英语发音。

## 功能特点

- **AI 驱动的口音分析**：使用 Google 的 Gemini AI 获得实时发音反馈。
- **语音活动检测 (VAD)**：自动检测您何时开始和停止说话，提供自然的对话体验。
- **连续对话模式**：通过自动语音分段实现自然对话 - 应用程序会检测您说话中的停顿并相应地创建新的语音段落。
- **多种口音选择**：练习各种英语口音，包括美式、英式、澳式、加拿大式、爱尔兰式和新西兰式。
- **多语言界面**：支持英语、简体中文、繁体中文（台湾）和繁体中文（香港）。
- **语音消息**：录制、播放和分析带有 AI 反馈的语音消息。

## 开始使用

### 前提条件

- Flutter SDK (^3.7.0)
- Google Gemini API 密钥（从 [Google AI Studio](https://aistudio.google.com/apikey) 获取）
- 麦克风访问权限

### 安装

1. 克隆存储库：
   ```
   git clone https://github.com/yourusername/practice_my_accent.git
   ```

2. 进入项目目录：
   ```
   cd practice_my_accent
   ```

3. 安装依赖：
   ```
   flutter pub get
   ```

4. 运行应用：
   ```
   flutter run
   ```

## 使用方法

1. **首次启动**：选择您的目标口音并输入您的 Google API 密钥。
2. **练习模式**：在主屏幕上点击「开始练习」开始。
3. **录音**：按下「开始与您的老师对话」按钮开始对话。
4. **对话模式**：应用程序会在您停顿时自动分段您的语音，实现自然的对话流程。每个段落都会作为单独的消息显示在聊天中。
5. **AI 反馈**：从 Gemini 获得关于您发音的 AI 反馈。
6. **停止录音**：按下「停止与老师对话」结束对话。

## 使用的技术

- Flutter 用于跨平台移动开发
- Google Gemini AI 用于语音分析和对话
- WebSockets 用于实时通信
- Flutter Sound 用于音频录制和播放
- Shared Preferences 用于本地存储

## 支持的语言

- 英语 (en)
- 简体中文 (zh)
- 繁体中文（台湾）(zh_TW)
- 繁体中文（香港）(zh_HK)

## 开发团队

此应用程序由 Cursor agent mode + Claude 3.7 + MCP 和开发者共同协作开发。

## 许可证

本项目采用 MIT 许可证 - 详情请参阅 LICENSE 文件。

## 致谢

- 感谢 Google Gemini 提供 AI 功能
- 感谢 Flutter 团队提供优秀的框架
- 感谢所有帮助改进此应用程序的贡献者 