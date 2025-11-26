const express = require("express");
const { createServer } = require("http");
const cors = require("cors");
const morgan = require("morgan");
const { Server } = require("socket.io");
const { join } = require("path");

const { connectDB } = require("./config/db.js");

const userRoutes = require("./routes/userRoutes.js");
const chatRoutes = require("./routes/chatRoutes.js");
const uploadRoutes = require("./routes/uploadRoutes.js");

const Message = require("./models/message.js");
const User = require("./models/user.js");

const {
  getRoomId
} = require("./utils/chatHelper.js");

const {
  createMessage,
  getUndeliveredMessages,
  getUserLastSeen,
  markMessageAsDelivered,
  markMessageAsRead,
  updateMessageStatus,
  updateUserLastSeen
} = require("./services/chatService.js");


connectDB();
const app = express();

app.get("/", (req, res) => {
  console.log("Server Running at PORT 3000");
  res.send("Server Running");
});

app.use(morgan("dev"));

app.use(express.json());

app.use("/api/users", userRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/upload", uploadRoutes);

//* <-------- CLOUDINARY ------------------->

require("./config/cloudinary");

//* <------------------------------------->

//* <------------------SOCKET ON----------------------------->

const httpServer = createServer(app);
const io = new Server(httpServer, { cors: { origin: "*" } });

const onlineUsers = new Map();

io.on("connection", (socket) => {
  console.log("New client connected", socket.id);
  let currentUserId = null;

  //* register user
  socket.on("register_user", ({ userId }) => {
    if (!userId) return;

    currentUserId = userId;
    onlineUsers.set(userId, socket.id);

    console.log(`User ${userId} registered with socket ${socket.id}`);

    checkPendingMessages(userId);
  });

  //* join room io
  socket.on("join_room", async ({ userId, partnerId }) => {
    if (!userId || !partnerId) {
      console.log("Invalid join_room request : missing userId or partnerId");
      return;
    }

    currentUserId = userId;
    onlineUsers.set(userId, socket.id);

    const roomId = getRoomId(userId, partnerId);
    socket.join(roomId);

    console.log(`User ${userId} joined room : ${roomId}`);

    try {
      const undeliveredMessages = await getUndeliveredMessages(
        userId,
        partnerId
      );
      const undeliveredCount = await markMessageAsDelivered(userId, partnerId);

      if (undeliveredCount > 0) {
        console.log(
          `Marked ${undeliveredCount} messages as delivered for ${userId}`
        );

        undeliveredMessages.forEach((message) => {
          io.to(roomId).emit("message_status", {
            messageId: message.messageId,
            status: "delivered",
            sender: message.sender,
            receiver: message.receiver,
          });
        });
      }

      // Logic moved outside the IF block so it runs every time
      io.to(roomId).emit("user_status", {
        userId: userId,
        status: "online",
      });

      if (onlineUsers.has(partnerId)) {
        socket.emit("user_status", {
          userId: partnerId,
          status: "online",
        });
      } else {
        const lastSeen = await getUserLastSeen(partnerId);
        socket.emit("user_status", {
          userId: partnerId,
          status: "offline",
          lastSeen: lastSeen || new Date().toISOString(),
        });
      }
    } catch (error) {
      console.log("Error handling room join : ", error);
    }
  });

  //* leave room
  socket.on("leave_room", ({ userId, partnerId }) => {
    const roomId = getRoomId(userId, partnerId);
    socket.leave(roomId);
    console.log(`User ${userId} left room : ${roomId}`);
  });

  //* send message
  socket.on("send_message", async (message) => {
    if (
      !message.sender ||
      !message.receiver ||
      !message.message ||
      !message.messageId
    ) {
      console.log("Invalid message format : ", message);
      return;
    }

    const roomId = getRoomId(message.sender, message.receiver);

    await createMessage({
      ...message,
      status: "sent",
      roomId: roomId,
    });

    console.log(
      `Message in room ${roomId} from ${message.sender} to ${message.receiver} : ${message.message}`
    );

    if (onlineUsers.has(message.receiver)) {
      message.status = "delivered";

      await updateMessageStatus(message.messageId, "delivered");
    } else {
      message.status = "sent";
    }

    io.to(roomId).emit("new_message", message);

    //* if user is online, but not joined in that particular room send him notification
    if (onlineUsers.has(message.receiver)) {
      const receiverSocketId = onlineUsers.get(message.receiver);
      const receiverSocket = io.sockets.sockets.get(receiverSocketId);

      if (receiverSocket && !receiverSocket.rooms.has(roomId)) {
        const sender = await User.findById(message.sender).select("username");

        const roomId = getRoomId(message.sender, message.receiver);

        console.log("Noticaion sent");

        receiverSocket.emit("new_message_notification", {
          roomId: roomId,
          senderId: message.sender,
          senderName: sender.username,
          messageId: message.messageId,
          message: message.message,
        });
      }
    }
  });

  //* typing status
  const typingTimeouts = new Map();

  // typing start
  socket.on("typing_start", ({ userId, receiverId }) => {
    if (!userId || !receiverId) {
      return;
    }

    const roomId = getRoomId(userId, receiverId);
    const key = `${userId}_${receiverId}`;

    if (typingTimeouts.has(key)) {
      clearTimeout(typingTimeouts.get(key));
    }

    socket.to(roomId).emit("typing_indicator", {
      userId,
      isTyping: true,
    });

    const timeout = setTimeout(() => {
      socket.to(roomId).emit("typing_indicator", {
        userId,
        isTyping: false,
      });
      typingTimeouts.delete(key);
    }, 5000);

    typingTimeouts.set(key, timeout);
  });

  // typing end
  socket.on("typing_end", ({ userId, receiverId }) => {
    if (!userId || !receiverId) {
      return;
    }

    const roomId = getRoomId(userId, receiverId);
    const key = `${userId}_${receiverId}`;

    if (typingTimeouts.has(key)) {
      clearTimeout(typingTimeouts.get(key));
      typingTimeouts.delete(key);
    }

    socket.to(roomId).emit("typing_indicator", {
      userId,
      isTyping: false,
    });
  });

  socket.on(
    "message_delivered",
    async ({ messageId, senderId, receiverId }) => {
      try {
        await updateMessageStatus(messageId, "delivered");

        const roomId = getRoomId(senderId, receiverId);
        const statusUpdate = {
          messageId: messageId,
          status: "delivered",
          sender: senderId,
          receiver: receiverId,
        };

        io.to(roomId).emit("message_status", statusUpdate);
      } catch (error) {}
    }
  );

  socket.on("messages_read", async ({ messageIds, senderId, receiverId }) => {
    try {
      for (const messageId of messageIds) {
        await updateMessageStatus(messageId, "read");
      }

      const roomId = getRoomId(senderId, receiverId);

      messageIds.forEach((messageId) => {
        const statusUpdate = {
          messageId: messageId,
          status: "read",
          sender: senderId,
          receiver: receiverId,
        };

        io.to(roomId).emit("message_status", statusUpdate);
      });
    } catch (error) {}
  });

  socket.on("mark_messages_read", async ({ userId, partnerId }) => {
    var count = await markMessageAsRead(userId, partnerId);

    const roomId = getRoomId(userId, partnerId);

    if (count > 0) {
      io.to(roomId).emit("messages_all_read", {
        reader: userId,
        sender: partnerId,
      });
    }

    if (onlineUsers.has(partnerId)) {
      const senderSocketId = onlineUsers.get(partnerId);
      const senderSocket = io.sockets.sockets.get(senderSocketId);

      if (senderSocket && !senderSocket.rooms.has(roomId)) {
        senderSocket.emit("messages_all_read", {
          reader: userId,
          sender: partnerId,
        });
      }
    }
  });

  socket.on("user_status_change", async ({ userId, status, lastSeen }) => {
    if (status == "offline") {
      await updateUserLastSeen(userId, lastSeen);

      if (onlineUsers.get(userId) === socket.id) {
        onlineUsers.delete(userId);
      }

      io.emit("user_status", {
        userId: userId,
        status: "offline",
        lastSeen: lastSeen,
      });
    } else {
      onlineUsers.set(userId, socket.id);

      io.emit("user_status", {
        userId: userId,
        status: "online",
      });
    }
  });

  socket.on("disconnect", async () => {
    if (currentUserId) {
      if (onlineUsers.get(currentUserId) === socket.id) {
        onlineUsers.delete(currentUserId);
      }

      const lastSeen = new Date().toISOString();
      await updateUserLastSeen(currentUserId, lastSeen);

      io.emit("user_status", {
        userId: currentUserId,
        status: "offline",
        lastSeen: lastSeen,
      });
    }
  });
});

async function checkPendingMessages(userId) {
  try {
    const pendingMessages = await Message.find({
      receiver: userId,
      status: "sent",
    }).populate("sender", "username");

    if (pendingMessages.length > 0) {
      // <---- Update DB to 'delivered' --- >
      await Message.updateMany(
        { receiver: userId, status: "sent" },
        { $set: { status: "delivered" } }
      );
      console.log(
        `Marked ${pendingMessages.length} messages as delivered for ${userId}`
      );

      // <--- Notify the SENDERS (Give them Double Ticks) --->
      pendingMessages.forEach((msg) => {
        const senderId = msg.sender._id.toString();

        // If the person who sent the message is online right now
        if (onlineUsers.has(senderId)) {
          const senderSocketId = onlineUsers.get(senderId);

          // Send the "Delivered" update to the sender
          io.to(senderSocketId).emit("message_status", {
            messageId: msg.messageId,
            status: "delivered",
            receiver: userId,
          });
        }
      });

      // Notify RECEIVER ( You ) about new chats --- >
      const messagesBySender = {};

      pendingMessages.forEach((msg) => {
        if (!messagesBySender[msg.sender._id]) {
          messagesBySender[msg.sender._id] = [];
        }

        messagesBySender[msg.sender._id].push(msg);
      });

      const userSocket = io.sockets.get(onlineUsers.get(userId));

      if (userSocket) {
        // 3. Loop through each sender and notify
        Object.keys(messagesBySender).forEach((senderId) => {
          const msgs = messagesBySender[senderId];
          const count = msgs.length;
          const senderName = msgs[0].sender.username;

          userSocket.emit("pending_messages", {
            senderId,
            senderName,
            count,
            latestMessage: msgs[msgs.length - 1].message, // Grab the last one in the array
          });
        });
      }
    }
  } catch (error) {}
}

//* <---------------SOCKET END ----------------------- >
httpServer.listen(process.env.PORT || 3000, () =>
  console.log("Server Started")
);
