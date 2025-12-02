## 📱 App Screenshots

<img width="1239" height="615" alt="1" src="https://github.com/user-attachments/assets/851ed9a5-6c53-4b37-8362-be0fb232d3e9" />

<img width="1902" height="784" alt="4" src="https://github.com/user-attachments/assets/fb34d853-724d-4f07-ba55-4c2c10361948" />

# 💬 ChatConnect - Real-time Chat Application

A modern, feature-rich real-time chat application built with Flutter and Node.js, offering seamless communication with support for text, images, and audio messages.

## ✨ Features

- **Real-time Messaging** - Instant message delivery using Socket.IO
- **Message Status** - Track message status (sent, delivered, read)
- **Message Timeline** - Messages organized by time (Today, Yesterday, specific dates)
- **Media Support** - Send images and audio messages
- **Message Actions**
  - Edit sent messages
  - Delete messages for everyone
  - Reply to messages
  - Like/react to messages
- **Typing Indicators** - See when someone is typing
- **Online Status** - Real-time user presence and last seen
- **Profile Management** - Upload and manage profile pictures
- **Push Notifications** - Get notified of new messages
- **Secure Authentication** - JWT-based authentication with encrypted storage
- **Message Pagination** - Efficient loading of chat history
- **Audio Recording** - Record and send voice messages with waveform visualization

## 🛠️ Tech Stack

### Frontend (Mobile)

- **Flutter** - Cross-platform mobile framework
- **GetX** - State management and navigation
- **Socket.IO Client** - Real-time communication
- **Dio** - HTTP client for API calls
- **Cached Network Image** - Efficient image loading
- **Flutter Secure Storage** - Secure token storage
- **Image Picker** - Gallery and camera access
- **Record** - Audio recording
- **Audioplayers** - Audio playback
- **Flutter Local Notifications** - Push notifications
- **Intl** - Date formatting and internationalization
- **UUID** - Unique ID generation
- **Logger** - Debug logging

### Backend

- **Node.js & Express** - Server framework
- **Socket.IO** - WebSocket communication
- **MongoDB & Mongoose** - Database and ODM
- **Cloudinary** - Media storage and CDN
- **JWT** - Authentication tokens
- **Bcrypt** - Password hashing
- **Multer** - File upload handling
- **Morgan** - HTTP request logging
- **CORS** - Cross-origin resource sharing
- **Dotenv** - Environment configuration
- **Streamifier** - Stream conversion utility

## 📁 Project Structure

```
├── app/src/              # Flutter mobile application
│   ├── lib/
│   │   ├── controllers/  # GetX controllers
│   │   ├── models/       # Data models
│   │   ├── services/     # API and Socket services
│   │   ├── views/        # UI screens
│   │   ├── constants/    # App constants and colors
│   │   └── bindings/     # Dependency injection
│   └── android/          # Android specific files
│
└── server/               # Node.js backend
    ├── controllers/      # Request handlers
    ├── models/          # MongoDB schemas
    ├── routes/          # API routes
    ├── services/        # Business logic
    ├── middleware/      # Authentication & file upload
    ├── config/          # Database & Cloudinary config
    ├── utils/           # Helper functions
    └── server.js        # Main server file with Socket.IO setup
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK
- Node.js
- MongoDB (local or Atlas)
- Cloudinary account (for media storage)
- Android Studio / Xcode (for mobile development)

### Backend Setup

1. Navigate to server directory:
```bash
cd server
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file in the server root:
```env
PORT=3000
MONGODB_URI=your_mongodb_uri
JWT_SECRET=your_jwt_secret
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

4. Start the server:
```bash
npm start
```

The server will run on `http://localhost:3000`

### Mobile App Setup

1. Navigate to app directory:
```bash
cd app/src
```

2. Install Flutter dependencies:
```bash
flutter pub get
```

3. Update API endpoints:
   - For Android Emulator: Use `10.0.2.2` instead of `localhost`
   - For Physical Device: Use your computer's IP address

   Update these files:
   - `lib/services/api_service.dart` - Line: `static const String baseUrl`
   - `lib/services/socket_service.dart` - Line: `static const String _socketUrl`
   - `lib/utils/api_constants.dart` - Line: `static const String baseUrl`

4. Run the app:
```bash
# For Android
flutter run

# For iOS
flutter run -d ios
```

### Configuration Notes

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
static const String _socketUrl = 'http://10.0.2.2:3000';
```

**For Physical Device:**
```dart
static const String baseUrl = 'http://YOUR_IP:3000/api';
static const String _socketUrl = 'http://YOUR_IP:3000';
```

Find your IP:
- Windows: `ipconfig`
- Mac/Linux: `ifconfig` or `ip addr show`


## 🔑 Key Features Explained

### Real-time Communication

- Socket.IO handles bidirectional communication
- Automatic reconnection on network changes
- Background/foreground state management
- Optimistic UI updates for instant feedback

### Message Timeline

- Smart date grouping (Today, Yesterday, Day name, Full date)
- Floating date indicator while scrolling
- Automatic date headers in chat view
- Timezone-aware timestamps

### Message Management

- Messages stored in MongoDB with status tracking
- Message status: sent → delivered → read
- Efficient pagination with 20 messages per page
- Message editing with "Edited" indicator
- Message deletion for everyone
- Reply to messages with context preview

### Media Handling

- Images compressed before upload (max 1024x1024, 85% quality)
- Audio recording with real-time waveform visualization
- 20-second audio message limit
- Cloudinary CDN for fast media delivery
- Automatic cleanup of temporary files

### Security

- JWT tokens with 10-day expiration
- Secure token storage using flutter_secure_storage
- Password hashing with bcrypt (12 rounds)
- Protected API endpoints with auth middleware
- CORS configuration for API security

### Notifications

- Local push notifications for new messages
- Notification badges for unread messages
- Timezone support for notification scheduling
- Custom notification icons and sounds

## 🔌 Socket.IO Events

The `server.js` file implements the following real-time events:

**Connection Events:**
- `register_user` - Register user connection with online status
- `join_room` - Join a specific chat room
- `leave_room` - Leave a chat room
- `manual_disconnect` - Handle user logout/disconnect

**Messaging Events:**
- `send_message` - Send text/image/audio messages
- `new_message` - Receive new message in room
- `new_message_notification` - Notify user of new messages when not in room

**Status Events:**
- `typing_start` / `typing_end` - Real-time typing indicators
- `message_delivered` - Update message to delivered status
- `messages_read` - Mark multiple messages as read
- `mark_messages_read` - Bulk read status update
- `user_status_change` - Online/offline status updates

**Message Actions:**
- `edit_message` - Edit existing message
- `message_edited` - Broadcast edited message
- `delete_message` - Delete message for everyone
- `message_deleted` - Broadcast deletion
- `like_message` - React to message with like
- `message_liked` - Broadcast like reaction


## Thanks 💖
