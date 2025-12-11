Шаг 1: Содержимое для Plan.md (Вставь это в файл)
Markdown

# PLAN.MD — SCAS MVP (Final Demo Version)

## 🎯 GOAL
Create a bulletproof Flutter application for a Thesis Defense Demo.
The app must render UI dynamically based on a JSON config hosted on a local Python server.
**DEADLINE:** TOMORROW. No complex debugging allowed.

## 🛠 TECH STACK & REQUIREMENTS
* **Framework:** Flutter (Latest Stable).
* **Backend:** Python `http.server` (running on port 8000).
* **Networking:**
    * Must automatically detect platform:
    * **Android Emulator:** Use `10.0.2.2:8000` (Crucial fix for "Connection Refused").
    * **iOS/macOS:** Use `127.0.0.1:8000`.
* **macOS Security:** App Sandbox permissions MUST be fixed programmatically or explicitly instructed.

## 📜 JSON DATA (The Source of Truth)
We need 3 scenarios to switch between during the demo.

### Scenario A: Living Room (Default)
```json
{
  "page_title": "Гостиная",
  "widgets": [
    { "type": "header", "text": "Управление светом" },
    { "type": "card", "color": "green", "child": { "type": "text", "text": "Статус: Комфорт" } },
    { "type": "toggle", "label": "Люстра", "initial_value": true }
  ]
}
Scenario B: Kitchen (Complex)
JSON

{
  "page_title": "Умная Кухня",
  "widgets": [
    { "type": "header", "text": "Климат и Вентиляция" },
    { "type": "text", "text": "Температура: 24°C" },
    { "type": "slider", "label": "Мощность вытяжки", "min": 0, "max": 100 },
    { "type": "toggle", "label": "Подсветка зоны", "initial_value": false }
  ]
}
Scenario C: Garage (Alert)
JSON

{
  "page_title": "Гараж",
  "widgets": [
    { "type": "header", "text": "Система Охраны" },
    { "type": "card", "color": "red", "child": { "type": "text", "text": "ВНИМАНИЕ: ДВИЖЕНИЕ" } },
    { "type": "toggle", "label": "Сирена", "initial_value": true }
  ]
}
✅ AGENT EXECUTION TASKS
1. SERVER SETUP
Create directory demo_server.

Create config.json with Scenario A.

Provide the exact terminal command to run the server.

2. FLUTTER SETUP
Create Flutter project scas_app.

Add dependencies: http, google_fonts.

CRITICAL macOS FIX: Update macos/Runner/DebugProfile.entitlements to allow com.apple.security.network.client.

3. CODING (main.dart)
Write a robust main.dart that:

Uses dart:io to detect Platform.isAndroid.

Sets URL to http://10.0.2.2:8000/config.json for Android and http://127.0.0.1:8000/config.json for others.

Adds a "Timestamp" to the URL to prevent caching (?t=123).

Handles errors gracefully (Show red text if server is down).

Parses: header, text, card (with recursion), toggle, slider.


---

### Шаг 2: "Золотой Промпт" для Агента

Скопируй этот текст и отправь своему AI в чат (Windsurf/Cursor):

```text
@Plan.md
You are a Senior Flutter Architect. I need you to execute the attached Plan.md step-by-step to build a working demo for my thesis defense.

1.  **Server:** Create the `demo_server` folder and the `config.json` file with the "Living Room" JSON from the plan.
2.  **Flutter:** Initialize the project `scas_app` and add dependencies.
3.  **Permissions (Crucial):** rewrite `scas_app/macos/Runner/DebugProfile.entitlements` to include `<key>com.apple.security.network.client</key><true/>`. If you don't do this, the app will fail on macOS.
4.  **Code:** Write the complete `lib/main.dart` file. Ensure it has logic to swap the URL host between `10.0.2.2` (if Android) and `127.0.0.1` (if macOS/iOS) to fix the connection errors seen in previous attempts.
5.  **Final Instructions:** Tell me exactly which two commands to run in two separate terminals to start the demo.
Почему это сработает сейчас:
Исправление Android: На твоем скрине ошибка Connection refused ... 127.0.0.1. Это потому, что эмулятор Android считает 127.0.0.1 самим собой. Ему нужно стучаться на 10.0.2.2, чтобы попасть в твой комп. Новый код это учтёт.

Исправление macOS: На скрине ошибка пустая ($e не распарсился), но это 99% проблема прав доступа (Sandbox). Промпт заставляет агента прописать права на сеть.

Чистый лист: Мы убираем весь старый мусор и конфигурации.