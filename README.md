<div align="center">

# 💬 ChatConnect

### Real-time messaging app with voice & video calling for Flutter & Node.js

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev) [![Node.js](https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js)](https://nodejs.org) [![MongoDB](https://img.shields.io/badge/MongoDB-7.x-47A248?logo=mongodb)](https://mongodb.com) [![Socket.IO](https://img.shields.io/badge/Socket.IO-4.x-010101?logo=socket.io)](https://socket.io) [![WebRTC](https://img.shields.io/badge/WebRTC-Enabled-333333?logo=webrtc)](https://webrtc.org)

</div>

---

## 📸 App Screenshots

<div align="center">
  <img src="https://github.com/user-attachments/assets/c9a2e4b3-7996-4fa2-92aa-8bd148c321a0" width="100%"/>
</div>

---

## 📖 Overview

ChatConnect is a full-stack real-time messaging application built with **Flutter** on the frontend and **Node.js + Socket.IO** on the backend. Every feature is designed around three goals: messages that feel instant, calls that just work, and a UI that gets out of the way.

### 💬 Core Messaging

Real-time message delivery is powered by **Socket.IO**, with a three-stage status pipeline — **Sent → Delivered → Read** — so you always know where your message stands. As you type, a smart-debounced **typing indicator** appears on the other end. Once sent, messages can be **edited** (with a visual "edited" label) or **deleted for everyone**. Double-tapping a message triggers a **reaction**, and any message can be **replied to** with a quoted preview. URLs in messages are automatically parsed and expanded into rich **link preview cards** showing title, description, and thumbnail via Open Graph metadata. Media support covers **image messages** with full-screen preview, **audio messages** with real-time waveform visualization and playback controls, and **file uploads** with a progress indicator.

### 📞 Voice & Video Calling

Calls run on a direct **WebRTC peer-to-peer** connection, keeping latency low and keeping your media off the server. Both audio-only and video calls are supported, with mid-call controls for **mute/unmute**, **camera on/off**, and **front/back camera flip**. A live **call duration timer** runs throughout. The full call lifecycle is handled: incoming call screen, missed call logging, rejection with notification, and busy-line detection. Every call is saved to a **paginated, filterable call history**, and a call-summary message is automatically posted to the chat thread.

### 👤 User Management

Users register and log in with **JWT-based authentication**, with tokens stored securely via `flutter_secure_storage`. Each profile supports a **custom profile picture** (stored on Cloudinary), full name, and username — all editable at any time. Real-time **online/offline presence** is broadcast via Socket.IO, with a **last seen** timestamp shown when a user goes offline. A **user search** lets you find and start conversations with anyone. Users can also **block and unblock** other users directly from their profile dialog; blocked users are silently prevented from sending messages.

### 💾 Smart Caching

A **cache-first strategy** ensures the app feels responsive even on slow networks: cached data is shown immediately while fresh data is fetched in the background. Chat rooms, user profiles, and the full user list are all cached. **Media files** (images, audio) are downloaded on first tap and stored locally via `path_provider`, so subsequent opens are instant with zero re-download. All caches are invalidated cleanly on logout.

### 🎨 UI / UX

The app ships with a **dark/light theme toggle** in the chat list header, with the preference persisted across sessions via `SharedPreferences`. The design follows **Material 3** with a custom color scheme, smooth page transitions, **pull-to-refresh**, **infinite scroll with pagination** (20 messages per page), and **unread message counters** on every chat room tile. A **floating date chip** appears while scrolling through chat history. Long-pressing a message opens a **context menu** with edit, delete, react, and reply actions. Empty states and loading indicators are designed for every screen.

### 🔔 Notifications

**FCM push notifications** fire for new messages when the app is backgrounded. Inside the app, an **in-app notification banner** appears when a message arrives from a room the user isn't currently viewing — but is suppressed when they're already in that chat. Messages that arrive while a recipient is offline are queued and **auto-delivered the moment they reconnect**.

---

## 🗂️ Project Structure

```
chat-app/
├── app/src/lib/
│   ├── controllers/           # GetX Controllers
│   │   ├── auth_controller.dart
│   │   ├── call_controller.dart
│   │   ├── chat_controller.dart
│   │   ├── home_controller.dart
│   │   ├── stats_controller.dart
│   │   ├── theme_controller.dart
│   │   └── user_controller.dart
│   ├── models/                # Data models
│   │   ├── call_model.dart
│   │   ├── chat_room_model.dart
│   │   ├── message_model.dart
│   │   └── user_model.dart
│   ├── services/              # API & Socket services
│   │   ├── api_service.dart
│   │   ├── cache_services.dart
│   │   ├── link_preview_service.dart
│   │   ├── media_download_service.dart
│   │   ├── socket_service.dart
│   │   └── webrtc_service.dart
│   ├── views/                 # UI Screens
│   │   ├── auth/
│   │   ├── call/
│   │   ├── chat/
│   │   │   └── link_preview_card.dart
│   │   ├── home/
│   │   ├── landing/
│   │   └── profile/
│   └── constants/             # App constants
│
└── server/
    ├── controllers/
    │   └── linkPreviewController.js
    ├── models/                # MongoDB schemas
    ├── routes/
    │   └── linkPreviewRoutes.js
    ├── services/
    │   └── linkPreviewService.js
    ├── middleware/            # Auth & upload middleware
    ├── config/
    └── server.js
```

---

## 🛠️ Tech Stack

### Mobile (Flutter)

| Layer | Technology |
|---|---|
| Framework | Flutter 3 / Dart |
| State Management | GetX |
| Real-time | Socket.IO Client |
| Video Calling | flutter_webrtc |
| Audio Recording | record v4 |
| Audio Playback | audioplayers |
| Image Caching | cached_network_image |
| Secure Storage | flutter_secure_storage |
| HTTP | dio |
| Local Storage | path_provider |

### Backend (Node.js)

| Layer | Technology |
|---|---|
| Runtime | Node.js 20 |
| Framework | Express 4 |
| Database | MongoDB with Mongoose |
| Real-time | Socket.IO |
| Auth | JWT (jsonwebtoken) |
| Password Hashing | bcrypt |
| File Upload | Multer + Cloudinary |
| Rate Limiting | express-rate-limit |
| Logging | morgan |

---

## 🏗️ Architecture

**Message status flow:** `Sent` → `Delivered` (recipient online) → `Read` (recipient opens chat).

**Link preview flow:** URL detected in message via regex → `LinkPreviewService` checks session cache → calls `GET /api/link-preview?url=` → server fetches Open Graph tags (`og:title`, `og:description`, `og:image`) with a 5 s timeout → result cached server-side (1 hr TTL) and client-side (session) → card renders below message text; tap opens URL in browser.

**Call flow:** Caller initiates → call record created in DB → receiver notified → on accept, WebRTC peer connection established → media toggles (mute, camera flip) supported mid-call → on end, duration saved to call history.

**Caching strategy:** Cache-first on first load, background refresh to update stale data, force-refresh skips cache, media files stored locally via `path_provider` with tap-to-download progress, all caches cleared on logout.

**Smart notifications:** No notification when user is already in the active chat room; notification shown for messages from other rooms; undelivered messages auto-delivered on socket reconnection.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Node.js `>=18.x`
- MongoDB instance
- Cloudinary account

### Backend Setup

```bash
cd server
npm install
```

Edit `.env`:

```env
PORT=3000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

```bash
npm start
```

The server starts at **`http://localhost:3000`**.

### Frontend Setup

```bash
cd app/src
flutter pub get
```

Update the base URL in `lib/utils/api_constants.dart`:

```dart
static const String baseUrl = 'http://your-server-ip:3000/api';
```

```bash
flutter run
```

---

## 📡 REST API Reference

### Auth

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/auth/register` | Register a new user |
| `POST` | `/api/auth/login` | Login, receive JWT |

### Users

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/users` | List all users |
| `GET` | `/api/users/:id` | Get user profile |
| `PUT` | `/api/users/:id` | Update profile |
| `POST` | `/api/users/block/:id` | Block a user |
| `POST` | `/api/users/unblock/:id` | Unblock a user |

### Messages & Rooms

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/rooms` | Get all chat rooms for current user |
| `GET` | `/api/rooms/:id/messages` | Paginated message history |
| `POST` | `/api/rooms/:id/messages` | Send a message |
| `PUT` | `/api/messages/:id` | Edit a message |
| `DELETE` | `/api/messages/:id` | Delete a message |

### Calls

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/calls` | Paginated call history |
| `GET` | `/api/calls/:id` | Get call details |

### Utilities

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/link-preview?url=` | Fetch Open Graph metadata (rate-limited: 30 req/min per IP) |

---

## ⚡ Real-time Socket Events

### Client → Server

| Event | Description |
|---|---|
| `register_user` | Register socket on connect |
| `join_room` | Join a chat room |
| `leave_room` | Leave a chat room |
| `send_message` | Send a message |
| `typing_start` | Notify typing started |
| `typing_end` | Notify typing stopped |
| `mark_messages_read` | Mark messages as read |
| `edit_message` | Edit a sent message |
| `delete_message` | Delete a message for everyone |
| `like_message` | React to a message |
| `call_initiate` | Start a call |
| `call_accept` | Accept incoming call |
| `call_reject` | Reject incoming call |
| `call_end` | End active call |
| `call_missed` | Report missed call |
| `webrtc_offer` | Send WebRTC offer |
| `webrtc_answer` | Send WebRTC answer |
| `webrtc_ice_candidate` | Exchange ICE candidates |
| `call_toggle_media` | Toggle audio/video |

### Server → Client

| Event | Description |
|---|---|
| `new_message` | Receive a new message |
| `new_message_notification` | Notification for message in another room |
| `message_status` | Sent / delivered / read status update |
| `typing_indicator` | Typing status from other user |
| `user_status` | Online / offline status change |
| `messages_all_read` | All messages marked read |
| `message_edited` | Message edited confirmation |
| `message_deleted` | Message deleted confirmation |
| `message_liked` | Message reaction update |
| `incoming_call` | Incoming call notification |
| `call_accepted` | Receiver accepted call |
| `call_rejected` | Receiver rejected call |
| `call_ended` | Call ended by other party |
| `call_failed` | Call failed (busy / error) |
| `webrtc_offer` | Receive WebRTC offer |
| `webrtc_answer` | Receive WebRTC answer |
| `webrtc_ice_candidate` | Receive ICE candidate |
| `call_media_toggled` | Media toggle update from peer |

---

## 🗄️ Database Schema

```
User ──< ChatRoom >── User
ChatRoom ──< Message
Message ──< Reaction
User ──< Call ──> User
```

| Model | Key Fields |
|---|---|
| `User` | `_id`, `username`, `email`, `passwordHash`, `profilePicture`, `isOnline`, `lastSeen`, `blockedUsers[]` |
| `ChatRoom` | `_id`, `participants[]`, `lastMessage`, `unreadCount` |
| `Message` | `_id`, `roomId`, `senderId`, `content`, `type`, `status`, `replyTo`, `reactions[]`, `editedAt` |
| `Call` | `_id`, `callerId`, `receiverId`, `type`, `status`, `startedAt`, `duration` |

---

## 📱 App Screens

| Screen | Description |
|---|---|
| **Landing** | Onboarding / welcome screen |
| **Auth** | Register and login with JWT |
| **Home** | Chat list with unread counters and online indicators |
| **Chat** | Full message thread with reply, edit, reactions, media, link previews |
| **Call** | Active voice/video call with mute, camera flip, duration |
| **Call History** | Paginated log of past calls with filter |
| **Profile** | View and edit name, username, profile picture |
| **User Profile Dialog** | View another user's info; block/unblock action |

---

## 🔒 Security

**JWT authentication** with secure token storage via `flutter_secure_storage`. Passwords hashed with **bcrypt** before storage. All API routes protected by authentication middleware. File uploads validated and stored on **Cloudinary** rather than the server filesystem. Link preview endpoint **rate-limited** to 30 requests per minute per IP to prevent abuse.

---

## 🧪 Testing

```bash
# Backend — run from server/
npm test

# Flutter — run from app/src/
flutter test
```

---

## 📄 License

ISC © 2024 — feel free to fork and build on top of this.

---

<div align="center">
Made with ❤️ by <a href="https://github.com/NikhilYadav04">Nikhil Yadav</a>
</div>
