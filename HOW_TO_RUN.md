# تشغيل المشروع من التيرمينال

مشروع **Graduation Project** — تطبيق Flutter + Backend (Node.js) + AI (صوت + OCR).

---

## المتطلبات

| الأداة | الإصدار | للتحقق |
|--------|---------|--------|
| **Flutter** | 3.x+ | `flutter --version` |
| **Node.js** | 18+ | `node --version` |
| **npm** | 9+ | `npm --version` |
| **Python 3** | 3.10+ | `python3 --version` |
| **curl** | أي | `curl --version` |

**للـ iOS (Mac فقط):** Xcode + CocoaPods → `sudo gem install cocoapods`

**للـ Android:** Android Studio + Emulator أو جهاز حقيقي

---

## 1) فك الضغط وادخل المجلد

```bash
unzip graduation_project.zip
cd graduation_prooject
```

---

## 2) إعداد ملفات البيئة (.env)

### Backend — `backend_temp/.env`

```bash
cp backend_temp/.env.example backend_temp/.env
```

عدّل القيم المهمة:
- `MONGO_URI` — رابط MongoDB Atlas (قاعدة البيانات الوحيدة — Mongoose ORM)
- `MONGO_DB_NAME` — اسم قاعدة البيانات (افتراضي: `test`)
- `JWT_KEY` — مفتاح سري للـ JWT

> **Offers:** Amazon + Noon + Jumia — direct fetch (no API key).

> **ملاحظة:** لا يوجد Postgres أو SQLite في المشروع. كل البيانات في MongoDB عبر الـ Backend.

### Voice AI — `voice_server/.env`

```bash
cp voice_server/.env.example voice_server/.env
```

عدّل:
- `ASSEMBLYAI_API_KEY` — من [assemblyai.com](https://www.assemblyai.com/)

### OCR — `ocr_service/.env`

```bash
echo 'OPENAI_API_KEY=your_openai_key_here' > ocr_service/.env
```

---

## 3) تثبيت الاعتماديات (أول مرة فقط)

```bash
# Flutter
flutter pub get

# Backend Node
cd backend_temp && npm install && cd ..

# iOS (Mac فقط)
cd ios && pod install && cd ..
```

> Python venv للـ AI يُنشأ **تلقائياً** عند أول تشغيل عبر `start.sh`.

---

## 4) التشغيل — أمر واحد (موصى به)

```bash
chmod +x start.sh    # أول مرة فقط
./start.sh
```

يشغّل **بالتوازي** (Backend + AI + Flutter):
| الخدمة | المنفذ | الرابط |
|--------|--------|--------|
| Backend API | 3001 | http://localhost:3001/api |
| Voice + OCR AI | 8000 | http://localhost:8000/health |
| WebSocket | 3002 | ws://localhost:3002 |
| Flutter App | — | يفتح على المحاكي/الجهاز |

### خيارات إضافية

```bash
./start.sh --no-app              # السيرفرات فقط بدون Flutter
./start.sh --device <device-id>    # جهاز Flutter محدد
flutter devices                  # عرض الأجهزة المتاحة
```

**إيقاف:** اضغط `Ctrl+C` في نفس التيرمينال.

**اللوج:** `logs/server.log`

---

## 5) تشغيل يدوي (3 تيرمينالات)

```bash
# Terminal 1 — Backend + AI
cd backend_temp && node src/server.js

# Terminal 2 — Flutter
flutter run lib/main.dart

# Terminal 3 (اختياري) — AI منفصل إذا Backend لا يشغّله
cd voice_server && python3 main.py
```

---

## 6) جهاز حقيقي (موبايل على نفس الـ WiFi)

1. افتح `lib/core/config/api_config.dart`
2. غيّر `_useRealDevice` إلى `true`
3. حدّث `_pcLanIp` بـ IP جهاز الماك على الشبكة:

```bash
ipconfig getifaddr en0
```

4. شغّل `./start.sh` والموبايل على نفس الـ WiFi

---

## 7) حل المشاكل الشائعة

| المشكلة | الحل |
|---------|------|
| `Port 3001 already in use` | `./start.sh` يحرّر المنفذ تلقائياً، أو `lsof -ti tcp:3001 \| xargs kill` |
| Flutter لا يجد packages | `flutter clean && flutter pub get` |
| OCR 503 / Voice لا يعمل | تأكد من `.env` و `OPENAI_API_KEY` + `ASSEMBLYAI_API_KEY` |
| iOS build fail | `cd ios && pod install && cd ..` |
| Backend لا يتصل بـ DB | راجع `MONGO_URI` في `backend_temp/.env` |

---

## هيكل المشروع

```
graduation_prooject/
├── lib/              # كود Flutter
├── backend_temp/     # API (Node.js) — المنفذ 3001
├── voice_server/     # AI صوت + OCR — المنفذ 8000
├── ocr_service/      # محرك OCR (oocr/)
├── assets/           # صور وأصول التطبيق
├── start.sh          # سكربت التشغيل الموحّد
└── HOW_TO_RUN.md     # هذا الملف
```

---

## أوامر مفيدة

```bash
flutter clean
flutter pub get
flutter run lib/main.dart
flutter build apk          # Android APK
flutter build ios          # iOS (Mac)
cd backend_temp && npm start
```
