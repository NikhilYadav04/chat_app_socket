const mongoose = require("mongoose");

const CallSchema = new mongoose.Schema(
  {
    callId: {
      type: String,
      required: true,
      unique: true,
    },

    callerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    receiverId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    callerName: {
      type: String,
      required: true,
      trim: true,
    },

    callerFullName: {
      type: String,
      trim: true,
    },

    callerProfileURL: {
      type: String,
      trim: true,
    },

    callType: {
      type: String,
      enum: ["audio", "video"],
      required: true,
    },

    status: {
      type: String,
      enum: ["ringing", "active", "ended", "rejected", "missed"],
      default: "ringing",
    },

    startTime: {
      type: Date,
    },

    endTime: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

//* call lookup
CallSchema.index({ callId: 1 }, { unique: true });

//* Caller call history
CallSchema.index({ callerId: 1, createdAt: -1 });

//* Receiver call history
CallSchema.index({ receiverId: 1, createdAt: -1 });

//* sorting by recent calls
CallSchema.index({ createdAt: -1 });

module.exports = mongoose.model("Call", CallSchema);
