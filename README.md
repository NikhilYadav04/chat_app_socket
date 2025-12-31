# ChatConnect - Real-Time Chat Application

A feature-rich, real-time messaging application built with Flutter and Node.js, offering seamless communication with voice/video calling capabilities.

## 🚀 Features

### 💬 Core Messaging
- **Real-time messaging** with Socket.IO
- **Message status tracking** (Sent, Delivered, Read)
- **Typing indicators** with smart debouncing
- **Message editing** - Edit sent messages with visual indicators
- **Message deletion** - Remove messages for everyone
- **Message reactions** - Like/react to messages with double-tap
- **Reply to messages** - Context-aware message replies
- **Media sharing**:
  - Image messages with preview
  - Audio messages with waveform visualization and playback
  - File upload with progress indication

### 📞 Voice & Video Calling
- **WebRTC-based calling** with peer-to-peer connection
- **Audio and video calls** with seamless switching
- **Call features**:
  - Mute/unmute microphone
  - Enable/disable camera
  - Camera flip (front/back)
  - Call duration tracking
- **Call status handling**:
  - Incoming call notifications
  - Missed calls
  - Rejected calls
  - Busy line detection
  - Call history tracking
- **Call history** with pagination and filtering
- **Call-specific messages** automatically logged in chat

### 👤 User Management
- **User authentication** (Register/Login) with JWT
- **Profile management**:
  - Custom profile pictures with Cloudinary storage
  - Full name and username
  - Profile editing
- **Online/offline status** with real-time updates
- **Last seen** timestamp when offline
- **User search** and discovery

### 💾 Smart Caching System
- **Automatic caching** for faster load times:
  - Chat rooms
  - User profiles
  - All users list
- **Background sync** - Fetch fresh data while showing cached content
- **Cache invalidation** on logout
- **Optimized data fetching** with cache-first strategy

### 🎨 UI/UX Features
- **Modern Material Design** with custom color scheme
- **Smooth animations** and transitions
- **Pull-to-refresh** functionality
- **Infinite scroll** with pagination
- **Unread message counters**
- **Empty state designs**
- **Loading indicators**
- **Floating date indicator** while scrolling chat
- **Profile dialogs** with user information
- **Bottom sheets** for contextual actions

### 🔔 Notifications & Real-time Updates
- **Push notifications** for new messages
- **In-app notifications** when not in active chat
- **Undelivered message queue** with auto-delivery
- **Real-time user status** updates
- **Smart notification handling** based on user context

### 🔒 Security & Privacy
- **JWT authentication** with secure token storage
- **Password hashing** with bcrypt
- **Secure file uploads** to Cloudinary
- **Protected API routes** with authentication middleware

### 📱 Chat Features
- **Persistent chat history** with MongoDB
- **Message pagination** (20 messages per page)
- **Chat room management**
- **Unread message tracking**
- **Message search** in chat rooms
- **Edit mode** with visual indicators
- **Reply mode** with quoted messages
- **Long-press context menus** for message actions

## 🛠️ Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter with Dart
- **State Management**: GetX
- **Real-time Communication**: Socket.IO Client
- **Video Calling**: flutter_webrtc
- **Audio Recording**: record package v4
- **Audio Playback**: audioplayers
- **Image Caching**: cached_network_image
- **Secure Storage**: flutter_secure_storage
- **Date Formatting**: intl
- **Image Picker**: image_picker
- **HTTP Requests**: dio

### Backend (Node.js)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Real-time**: Socket.IO
- **Authentication**: JWT (jsonwebtoken)
- **Password Hashing**: bcrypt
- **File Upload**: Multer
- **Cloud Storage**: Cloudinary
- **Environment Variables**: dotenv
- **Logging**: morgan

## 📂 Project Structure

```
chat-app/
├── app/src/lib/
│   ├── controllers/           # GetX Controllers
│   │   ├── auth_controller.dart
│   │   ├── call_controller.dart
│   │   ├── chat_controller.dart
│   │   ├── home_controller.dart
│   │   ├── stats_controller.dart
│   │   └── user_controller.dart
│   ├── models/                # Data models
│   │   ├── call_model.dart
│   │   ├── chat_room_model.dart
│   │   ├── message_model.dart
│   │   └── user_model.dart
│   ├── services/              # API & Socket services
│   │   ├── api_service.dart
│   │   ├── cache_services.dart
│   │   ├── socket_service.dart
│   │   └── webrtc_service.dart
│   ├── views/                 # UI Screens
│   │   ├── auth/
│   │   ├── call/
│   │   ├── chat/
│   │   ├── home/
│   │   ├── landing/
│   │   └── profile/
│   └── constants/             # App constants
│
└── server/
    ├── controllers/           # Route controllers
    ├── models/               # MongoDB schemas
    ├── routes/               # API routes
    ├── services/             # Business logic
    ├── middleware/           # Auth & upload middleware
    ├── config/               # Configuration files
    └── server.js             # Main server file
```

## 🚦 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Node.js (>=16.x)
- MongoDB
- Cloudinary account

### Backend Setup

1. **Navigate to server directory**:
```bash
cd server
```

2. **Install dependencies**:
```bash
npm install
```

3. **Create `.env` file**:
```env
PORT=3000
MONGODB_URI=your_mongodb_connection_string
JWT_SECRET=your_jwt_secret_key
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

4. **Start the server**:
```bash
npm start
```

### Frontend Setup

1. **Navigate to app directory**:
```bash
cd app
```

2. **Install dependencies**:
```bash
flutter pub get
```

3. **Update API endpoint** in `lib/services/api_service.dart`:
```dart
final String baseUrl = 'http://your-server-ip:3000/api';
```

4. **Run the app**:
```bash
flutter run
```

## 📡 Socket Events

### Client → Server
- `register_user` - Register user socket connection
- `join_room` - Join a chat room
- `leave_room` - Leave a chat room
- `send_message` - Send a message
- `typing_start` - Notify typing started
- `typing_end` - Notify typing stopped
- `mark_messages_read` - Mark messages as read
- `edit_message` - Edit a message
- `delete_message` - Delete a message
- `like_message` - Like/react to a message
- `call_initiate` - Start a call
- `call_accept` - Accept incoming call
- `call_reject` - Reject incoming call
- `call_end` - End active call
- `call_missed` - Report missed call
- `webrtc_offer` - Send WebRTC offer
- `webrtc_answer` - Send WebRTC answer
- `webrtc_ice_candidate` - Exchange ICE candidates
- `call_toggle_media` - Toggle audio/video

### Server → Client
- `new_message` - Receive new message
- `new_message_notification` - Receive notification for new message
- `message_status` - Message status update
- `typing_indicator` - Typing status update
- `user_status` - User online/offline status
- `messages_all_read` - All messages marked as read
- `message_edited` - Message edited successfully
- `message_deleted` - Message deleted successfully
- `message_liked` - Message liked successfully
- `incoming_call` - Incoming call notification
- `call_accepted` - Call accepted by receiver
- `call_rejected` - Call rejected
- `call_ended` - Call ended
- `call_failed` - Call failed
- `webrtc_offer` - Receive WebRTC offer
- `webrtc_answer` - Receive WebRTC answer
- `webrtc_ice_candidate` - Receive ICE candidate
- `call_media_toggled` - Media toggle update

## 🎯 Key Features Implementation

### Message Status Flow
1. **Sent** - Message sent to server
2. **Delivered** - Message delivered to recipient (online)
3. **Read** - Recipient opened and viewed the message

### Call Flow
1. Caller initiates call → Creates call record in DB
2. Receiver gets notification → Can accept/reject
3. On accept → WebRTC connection established
4. During call → Media toggle, camera switch supported
5. On end → Call duration saved to history

### Caching Strategy
- **First load**: Check cache → Show cached data → Fetch fresh data in background
- **Force refresh**: Skip cache → Fetch fresh data → Update cache
- **On logout**: Clear all caches

### Smart Notifications
- No notification if user is in active chat
- Notification shown if message from different chat
- Undelivered messages auto-delivered on reconnection

## 🐳 Docker Deployment

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 5000
CMD ["node", "server.js"]
```


## 📄 License

This project is licensed under the ISC License.

## 👨‍💻 Author

**Your Name**
- GitHub: Nikhil Yadav

## 🙏 Acknowledgments

- Socket.IO for real-time communication
- Cloudinary for media storage
- GetX for state management
- flutter_webrtc for video calling capabilities

---
