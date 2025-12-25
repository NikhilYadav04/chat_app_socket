const mongoose = require("mongoose");

const messageSchema = new mongoose.Schema({
  chatRoomId: {
    type: String,
    required: true,
    index: true,
  },
  messageId: {
    type: String,
    required: true,
    unique: true,
    index: true,
  },
  receiver: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true,
  },
  sender: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
    required: true,
    index: true,
  },
  message: {
    type: String,
    required: true,
  },
  messageType: {
    type: String,
    enum: ["text", "image", "audio", "call"],
    default: "text",
  },
  fileURL: {
    type: String,
    default: "",
  },
  filePublicId: {
    type: String,
    default: "",
  },
  status: {
    type: String,
    enum: ["sent", "delivered", "read"],
    default: "sent",
    index: true,
  },
  isLiked: {
    type: Boolean,
    default: false,
  },
  repliedMessage: {
    type: String,
    default: "",
  },
  repliedTo: {
    type: String,
    default: "",
  },
  isEdited: {
    type: Boolean,
    default: false,
  },
  isDeleted: {
    type: Boolean,
    default: false,
  },
  createdAt: {
    type: Date,
    default: Date.now,
    index: true,
  },
});

// Compound indexes for performance optimization
messageSchema.index({ chatRoomId: 1, createdAt: -1 });
messageSchema.index({ receiver: 1, status: 1 });

module.exports = mongoose.model("Message", messageSchema);
