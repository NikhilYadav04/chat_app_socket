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
const callRoutes = require("./routes/callRoutes.js");

const Message = require("./models/message.js");
const User = require("./models/user.js");

const { getRoomId } = require("./utils/chatHelper.js");

const {
  createMessage,
  getUndeliveredMessages,
  getUserLastSeen,
  markMessageAsDelivered,
  markMessageAsRead,
  updateMessageStatus,
  updateUserLastSeen,
} = require("./services/chatService.js");
const {
  editMessage,
  deleteMessage,
  likeMessage,
} = require("./services/messageService.js");
const call = require("./models/call.js");

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
app.use("/api/call", callRoutes);

//* <-------- CLOUDINARY ------------------->

require("./config/cloudinary");

//* <------------------------------------->

//* <------------------SOCKET ON----------------------------->

const httpServer = createServer(app);
const io = new Server(httpServer, { cors: { origin: "*" } });

const onlineUsers = new Map();

app.get("/check-online", (req, res) => {
  console.log(onlineUsers);
});

io.on("connection", (socket) => {
  console.log("New client connected", socket.id);
  let currentUserId = null;

  //* register user
  socket.on("register_user", ({ userId }) => {
    if (!userId) return;

    console.log(`User id receiver is ${userId}`);

    currentUserId = userId;
    onlineUsers.set(userId, socket.id);

    console.log(`User ${userId} registered with socket ${socket.id}`);

    console.log(onlineUsers);

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

  //* Edit message
  socket.on("edit_message", async ({ messageId, text, sender, receiver }) => {
    try {
      if (!messageId || !text || !sender || !receiver) {
        console.log("empty fields !!");
        return;
      }

      const isEdited = await editMessage(messageId, text);

      const roomId = getRoomId(sender, receiver);

      if (isEdited) {
        io.to(roomId).emit("message_edited", {
          id: messageId,
          text: text,
        });
      } else {
        const message = await Message.findOne({ messageId: id });

        const originalText = "";

        if (message) {
          originalText = message.message;
        }
        io.to(roomId).emit("message_edited_error", {
          id: messageId,
          text: originalText,
        });
      }
    } catch (e) {
      console.log(e);
      io.to(roomId).emit("message_edited_error", {
        id: messageId,
        text: "",
      });
    }
  });

  //* Delete message
  socket.on("delete_message", async ({ messageId, sender, receiver }) => {
    try {
      if (!messageId || !sender || !receiver) {
        console.log("empty fields !!");
        return;
      }

      const isEdited = await deleteMessage(messageId);

      const roomId = getRoomId(sender, receiver);

      if (isEdited) {
        io.to(roomId).emit("message_deleted", {
          id: messageId,
        });
      } else {
        io.to(roomId).emit("message_deleted_error", {
          id: messageId,
        });
      }
    } catch (e) {
      console.log(e);
      io.to(roomId).emit("message_deleted_error", {
        id: messageId,
      });
    }
  });

  //* Like message
  socket.on("like_message", async ({ messageId, sender, receiver }) => {
    try {
      if (!messageId || !sender || !receiver) {
        console.log("empty fields !!");
        return;
      }

      const isEdited = await likeMessage(messageId);

      const roomId = getRoomId(sender, receiver);

      if (isEdited) {
        io.to(roomId).emit("message_liked", {
          id: messageId,
        });
      } else {
        io.to(roomId).emit("message_liked_error", {
          id: messageId,
        });
      }
    } catch (e) {
      console.log(e);
      io.to(roomId).emit("message_liked_error", {
        id: messageId,
      });
    }
  });

  //* <------------------ CALLING OTHER USER ----------------------->

  //* Initiate a call
  socket.on(
    "call_initiate",
    async ({
      callId,
      callerId,
      receiverId,
      callType,
      callerName,
      receiverName,
      receiverProfileURL,
    }) => {
      try {
        if (!callerId || !receiverId || !callType) {
          console.log("Invalid call_initiate request");
          return;
        }

        //* Check if receiver is busy on another call
        const isUserBusy = await call.exists({
          status: "active",
          $or: [{ callerId: callerId }],
        });

        if (isUserBusy) {
          const callerSocketId = onlineUsers.get(callerId);

          //* Notify the caller that receiver is busy and end the call
          if (onlineUsers.has(callerSocketId)) {
            const otherSocketId = onlineUsers.get(callerSocketId);
            io.to(otherSocketId).emit("call_ended", {
              callId,
              endedBy: callerSocketId,
              status: "busy",
              startedAt: new Date(),
            });
          }
        }

        //* store call information
        const newCall = new call({
          callId: callId,
          callerId: callerId,
          receiverId: receiverId,
          callType,
          callerName: callerName,
          receiverName: receiverName,
          receiverProfileURL: receiverProfileURL,
          status: "ringing",
          startTime: new Date(),
        });

        await newCall.save();

        console.log(
          `Call initiated: ${callId} from ${callerId} to ${receiverId}`
        );

        //* Check if receiver is online
        if (onlineUsers.has(receiverId)) {
          const receiverSocketId = onlineUsers.get(receiverId);

          //* Get caller details
          const caller = await User.findById(callerId).select(
            "username fullName profileURL"
          );

          //* notify receiver about incoming call
          io.to(receiverSocketId).emit("incoming_call", {
            callId,
            callerId,
            callerName: caller.username,
            callerFullName: caller.fullName,
            callerProfileURL: caller.profileURL,
            callType,
            receiverName: receiverName,
            receiverProfileURL: receiverProfileURL,
          });
        } else {
          //* Receiver is offline - call failed
          socket.emit("call_failed", {
            callId,
            reason: "User is offline",
          });

          console.log("call failed");

          await call.findOneAndDelete({ callId });
        }
      } catch (error) {
        console.error("Error initiating call:", error);
        socket.emit("call_failed", {
          reason: "Server error",
        });
      }
    }
  );

  //* Miss Call
  socket.on("call_missed", async ({ callId, message }) => {
    try {
      const activeCall = await call.findOne({ callId: callId });

      if (!activeCall) {
        console.log("Call not found:", callId);
        return;
      }

      activeCall.status = "missed";
      activeCall.endTime = new Date();

      console.log(`Call missed : ${callId}`);

      //* Notify caller that call is missed and send end_call to both
      if (onlineUsers.has(activeCall.callerId.toString())) {
        const callerSocketId = onlineUsers.get(activeCall.callerId.toString());

        io.to(callerSocketId).emit("call_ended", {
          callId,
          endedBy: activeCall.callerId.toString(),
          status: "missed",
          startedAt: activeCall.startTime,
        });
      }

      if (onlineUsers.has(activeCall.receiverId.toString())) {
        const callerSocketId = onlineUsers.get(
          activeCall.receiverId.toString()
        );

        io.to(callerSocketId).emit("call_ended", {
          callId,
          endedBy: activeCall.receiverId.toString(),
          startedAt: activeCall.startTime,
        });
      }

      await activeCall.save();
    } catch (error) {
      console.error("Error ending call:", error);
    }
  });

  //* Accept a call
  socket.on("call_accept", async ({ callId, receiverId }) => {
    try {
      const activeCall = await call.findOne({ callId: callId });

      if (!activeCall) {
        console.log("Call not found:", callId);
        return;
      }

      activeCall.status = "active";
      activeCall.startTime = new Date();

      await activeCall.save();
      console.log(`Call accepted: ${callId}`);

      console.log(`caller id is ${activeCall.callerId}`);
      console.log(`has is ${onlineUsers.has(activeCall.callerId)}`);
      console.log(`maps is ${onlineUsers.get(activeCall.callerId)}`);

      //* Notify caller that call was accepted
      if (onlineUsers.has(activeCall.callerId.toString())) {
        const callerSocketId = onlineUsers.get(activeCall.callerId.toString());
        // console.log(`sent call accepted to owner ${callerSocketId}`)
        io.to(callerSocketId).emit("call_accepted", {
          callId,
          receiverId,
        });
      }
    } catch (error) {
      console.error("Error accepting call:", error);
    }
  });

  //* Reject a call
  socket.on("call_reject", async ({ callId, receiverId, reason }) => {
    try {
      const activeCall = await call.findOne({ callId: callId });

      if (!activeCall) {
        console.log("Call not found:", callId);
        return;
      }

      console.log(`Call rejected: ${callId}, reason: ${reason || "declined"}`);

      //* Notify caller that call was rejected
      if (onlineUsers.has(activeCall.callerId.toString())) {
        const callerSocketId = onlineUsers.get(activeCall.callerId.toString());
        io.to(callerSocketId).emit("call_rejected", {
          callId,
          reason: reason || "Call declined",
        });
      }

      activeCall.endTime = new Date();
      activeCall.status = "rejected";

      await activeCall.save();
    } catch (error) {
      console.error("Error rejecting call:", error);
    }
  });

  //* End a call
  socket.on("call_end", async ({ callId, userId, status }) => {
    try {
      const activeCall = await call.findOne({ callId: callId });

      if (!activeCall) {
        console.log("Call not found:", callId);
        return;
      }

      const otherUserId =
        activeCall.callerId == userId
          ? activeCall.receiverId
          : activeCall.callerId;

      console.log(`User id receiver is ${userId}`);
      console.log(`Call ended: ${callId} by ${userId}`);
      console.log(`Otheruser id is ${otherUserId}`);

      //* Notify the other user
      if (onlineUsers.has(otherUserId.toString())) {
        const otherSocketId = onlineUsers.get(otherUserId.toString());
        io.to(otherSocketId).emit("call_ended", {
          callId,
          endedBy: userId,
          startedAt: activeCall.startTime,
        });
      }

      activeCall.status = "ended";

      if (status == "isRinging") {
        activeCall.endTime = activeCall.startTime;
      } else {
        activeCall.endTime = new Date();
      }

      await activeCall.save();
    } catch (error) {
      console.error("Error ending call:", error);
    }
  });

  //* WebRTC Signalling: Offer
  socket.on("webrtc_offer", ({ callId, offer, callerId, receiverId }) => {
    try {
      console.log(`WebRTC offer from ${callerId} to ${receiverId}`);

      if (onlineUsers.has(receiverId)) {
        const receiverSocketId = onlineUsers.get(receiverId);
        io.to(receiverSocketId).emit("webrtc_offer", {
          callId,
          offer,
          callerId,
        });
      }
    } catch (error) {
      console.error("Error sending WebRTC offer:", error);
    }
  });

  //* WebRTC SIgnalling : Answer
  socket.on("webrtc_answer", ({ callId, answer, receiverId, callerId }) => {
    try {
      console.log(`WebRTC answer from ${receiverId} to ${callerId}`);

      if (onlineUsers.has(callerId)) {
        const callerSocketId = onlineUsers.get(callerId);
        io.to(callerSocketId).emit("webrtc_answer", {
          callId,
          answer,
          receiverId,
        });
      }
    } catch (error) {
      console.error("Error sending WebRTC answer:", error);
    }
  });

  //* WebRTC Signalling: ICE Candidate
  socket.on(
    "webrtc_ice_candidate",
    ({ callId, candidate, fromUserId, toUserId }) => {
      try {
        console.log(`ICE candidate from ${fromUserId} to ${toUserId}`);

        if (onlineUsers.has(toUserId)) {
          const toSocketId = onlineUsers.get(toUserId);
          io.to(toSocketId).emit("webrtc_ice_candidate", {
            callId,
            candidate,
            fromUserId,
          });
        }
      } catch (error) {
        console.error("Error sending ICE candidate:", error);
      }
    }
  );

  //* Toggle audio/video from call
  socket.on(
    "call_toggle_media",
    async ({ callId, userId, mediaType, enabled }) => {
      try {
        const activeCall = await call.findOne({ callId: callId });

        if (!activeCall) {
          console.log("Call not found:", callId);
          return;
        }

        const otherUserId =
          activeCall.callerId === userId
            ? activeCall.receiverId
            : activeCall.callerId;

        if (onlineUsers.has(otherUserId.toString())) {
          const otherSocketId = onlineUsers.get(otherUserId.toString());
          io.to(otherSocketId).emit("call_media_toggled", {
            callId,
            userId,
            mediaType, // "audio" or "video"
            enabled,
          });
        }
      } catch (error) {
        console.error("Error toggling media:", error);
      }
    }
  );

  //*<-------------------------------------------------------------->

  socket.on("manual_disconnect", async () => {
    if (currentUserId) {
      if (onlineUsers.get(currentUserId) === socket.id) {
        onlineUsers.delete(currentUserId);
      }

      const lastSeen = new Date().toISOString();
      await updateUserLastSeen(currentUserId, lastSeen);

      console.log(`User ${currentUserId} disconnected`);

      console.log(onlineUsers);

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
