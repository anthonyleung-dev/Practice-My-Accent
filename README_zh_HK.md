# 練習我的口音

這是一款 Flutter 應用程式，旨在通過與 Gemini AI 的對話，幫助用戶練習並提高英語發音。

## 功能特點

- **AI 驅動的口音分析**：使用 Google 的 Gemini AI 獲得即時發音反饋。
- **語音活動檢測 (VAD)**：自動檢測您何時開始和停止說話，提供自然的對話體驗。
- **連續對話模式**：通過自動語音分段實現自然對話 - 應用程式會檢測您說話中的停頓並相應地創建新的語音段落。
- **多種口音選擇**：練習各種英語口音，包括美式、英式、澳式、加拿大式、愛爾蘭式和紐西蘭式。
- **多語言界面**：支持英語、簡體中文、繁體中文（台灣）和繁體中文（香港）。
- **語音訊息**：錄製、播放和分析帶有 AI 反饋的語音訊息。

## 開始使用

### 前提條件

- Flutter SDK (^3.7.0)
- Google Gemini API 密鑰（從 [Google AI Studio](https://aistudio.google.com/apikey) 獲取）
- 麥克風訪問權限

### 安裝

1. 克隆存儲庫：
   ```
   git clone https://github.com/yourusername/practice_my_accent.git
   ```

2. 進入項目目錄：
   ```
   cd practice_my_accent
   ```

3. 安裝依賴：
   ```
   flutter pub get
   ```

4. 運行應用：
   ```
   flutter run
   ```

## 使用方法

1. **首次啟動**：選擇您的目標口音並輸入您的 Google API 密鑰。
2. **練習模式**：在主屏幕上點擊「開始練習」開始。
3. **錄音**：按下「開始與您的老師對話」按鈕開始對話。
4. **對話模式**：應用程式會在您停頓時自動分段您的語音，實現自然的對話流程。每個段落都會作為單獨的訊息顯示在聊天中。
5. **AI 反饋**：從 Gemini 獲得關於您發音的 AI 反饋。
6. **停止錄音**：按下「停止與老師對話」結束對話。

## 使用的技術

- Flutter 用於跨平台移動開發
- Google Gemini AI 用於語音分析和對話
- WebSockets 用於實時通信
- Flutter Sound 用於音頻錄製和播放
- Shared Preferences 用於本地存儲

## 支持的語言

- 英語 (en)
- 簡體中文 (zh)
- 繁體中文（台灣）(zh_TW)
- 繁體中文（香港）(zh_HK)

## 開發團隊

此應用程式由 Cursor agent mode + Claude 3.7 + MCP 和小薯程式員共同協作開發。

## 許可證

本項目採用 MIT 許可證 - 詳情請參閱 LICENSE 文件。

## 致謝

- 感謝 Google Gemini 提供 AI 功能
- 感謝 Flutter 團隊提供優秀的框架
- 感謝所有幫助改進此應用程式的貢獻者 