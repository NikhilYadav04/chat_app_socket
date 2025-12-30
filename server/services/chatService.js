const mongoose = require("mongoose");
const Message = require("../models/message");
const User = require("../models/user");
const { getRoomId } = require("../utils/chatHelper");

const ObjectId = mongoose.Types.ObjectId;

const createMessage = async (data) => {
  try {
    const newMessage = new Message({
      chatRoomId: data.roomId,
      messageId: data.messageId,
      sender: data.sender,
      receiver: data.receiver,
      message: data.message,

      messageType: data.messageType || "text",
      fileURL: data.fileURL || "",
      filePublicId: data.filePublicId || "",

      repliedTo: data.repliedTo || "",
      repliedMessage: data.repliedMessage || "",

      status: data.status || "sent",
    });

    await newMessage.save();
    return newMessage;
  } catch (error) {
    throw error;
  }
};

const fetchChatMessages = async ({
  currentUserId,
  senderId,
  receiverId,
  page = 1,
  limit = 20,
}) => {
  const roomId = getRoomId(senderId, receiverId);
  const query = { chatRoomId: roomId };

  try {
    if (currentUserId !== senderId && currentUserId !== receiverId) {
      throw new Error("Unauthorized: You cannot view this chat.");
    }

    const updateQuery = {
      chatRoomId: roomId,
      receiver: new mongoose.Types.ObjectId(currentUserId),
      status: "sent",
    };

    await Message.updateMany(updateQuery, {
      $set: { status: "delivered" },
    });

    // FETCH MESSAGES
    const messages = await Message.aggregate([
      {
        $match: query,
      },
      {
        $sort: { createdAt: -1 },
      },
      {
        $skip: (page - 1) * limit,
      },
      {
        $limit: limit,
      },
      {
        $addFields: {
          isMine: {
            $eq: ["$sender", { $toObjectId: currentUserId }],
          },
        },
      },
    ]);

    return messages;
  } catch (error) {
    console.log(error);

    throw error;
  }
};

const updateMessageStatus = async (messageId, status) => {
  try {
    const message = await Message.findOneAndUpdate(
      { messageId: messageId },
      { status: status },
      { new: true }
    );

    return message;
  } catch (error) {
    throw error;
  }
};

const getUndeliveredMessages = async (userId, partnerId) => {
  try {
    const message = await Message.find({
      receiver: userId,
      sender: partnerId,
      status: "sent",
    });

    return message;
  } catch (error) {
    throw error;
  }
};

const updateUserLastSeen = async (userId, lastSeen) => {
  try {
    const user = await User.findByIdAndUpdate(
      userId,
      {
        lastSeen: lastSeen,
      },
      { new: true }
    );

    return user;
  } catch (error) {
    throw error;
  }
};

const getUserLastSeen = async (userId) => {
  try {
    const user = await User.findById(userId).select("lastSeen");

    if (!user) {
      return null;
    }

    return user.lastSeen ? user.lastSeen.toISOString() : null;
  } catch (error) {
    throw error;
  }
};

const getUserOnlineStatus = async (userId) => {
  try {
    const user = await User.findById(userId).select("isOnline lastSeen");

    if (!user) {
      return {
        isOnline: false,
        lastSeen: null,
      };
    }

    return {
      isOnline: user.isOnline || false,
      lastSeen: user.lastSeen ? user.lastSeen.toISOString() : null,
    };
  } catch (error) {
    throw error;
  }
};

const markMessageAsDelivered = async (userId, partnerId) => {
  try {
    const result = await Message.updateMany(
      {
        receiver: new ObjectId(userId),
        sender: new ObjectId(partnerId),
        status: "sent",
      },
      {
        $set: {
          status: "delivered",
        },
      }
    );

    return result.modifiedCount;
  } catch (error) {
    throw error;
  }
};

const markMessageAsRead = async (userId, partnerId) => {
  try {
    const result = await Message.updateMany(
      {
        receiver: new ObjectId(userId),
        sender: new ObjectId(partnerId),
        status: { $in: ["sent", "delivered"] },
      },
      {
        $set: {
          status: "read",
        },
      }
    );

    return result.modifiedCount;
  } catch (error) {
    throw error;
  }
};

const chatRoom = async (userId) => {
  try {
    const userObjectId = new mongoose.Types.ObjectId(userId);

    const privateChatQuery = {
      $or: [{ sender: userObjectId }, { receiver: userObjectId }],
    };

    // const privateChats = await Message.aggregate([
    //   {
    //     $match: privateChatQuery,
    //   },
    //   {
    //     $sort: { createdAt: -1 },
    //   },
    //   {
    //     $group: {
    //       _id: {
    //         $cond: [{ $ne: ["$sender", userObjectId] }, "$sender", "$receiver"],
    //       },
    //       latestMessageTime: { $first: "$createdAt" },
    //       latestMessage: { $first: "$message" },
    //       latestMessageId: { $first: "$_id" },
    //       latestMessageStatus: { $first: "$status" },
    //       sender: { $first: "$sender" },
    //       messages: {
    //         $push: {
    //           sender: "$sender",
    //           receiver: "$receiver",
    //           status: "$status",
    //         },
    //       },
    //     },
    //   },
    //   {
    //     $lookup: {
    //       from: "users",
    //       localField: "_id",
    //       foreignField: "_id",
    //       as: "userDetails",
    //     },
    //   },
    //   {
    //     $unwind: "$userDetails",
    //   },
    //   {
    //     $project: {
    //       _id: 0,
    //       chatType: "private",
    //       messageId: "$latestMessageId",
    //       username: "$userDetails.username",
    //       userId: "$userDetails._id",
    //       latestMessageTime: 1,
    //       latestMessage: 1,
    //       sender: 1,
    //       unreadCount: {
    //         $size: {
    //           $filter: {
    //             input: "$messages",
    //             as: "msg",
    //             cond: {
    //               $and: [
    //                 { $eq: ["$$msg.receiver", userObjectId] },
    //                 { $in: ["$$msg.status", ["sent", "delivered"]] },
    //               ],
    //             },
    //           },
    //         },
    //       },
    //       latestMessageStatus: {
    //         $cond: [
    //           { $eq: ["$sender", userObjectId] },
    //           "$latestMessageStatus",
    //           null,
    //         ],
    //       },
    //     },
    //   },
    // ]);

    // return privateChats.sort((a, b) => {
    //   return new Date(b.latestMessageTime) - new Date(a.latestMessageTime);
    // });
    const privateChats = await Message.aggregate([
      // 1. Filter messages involving the user
      {
        $match: privateChatQuery,
      },
      // 2. Sort by newest first
      {
        $sort: { createdAt: -1 },
      },
      // 3. Group by conversation partner
      {
        $group: {
          _id: {
            $cond: [{ $ne: ["$sender", userObjectId] }, "$sender", "$receiver"],
          },
          latestMessageTime: { $first: "$createdAt" },
          latestMessage: { $first: "$message" },
          latestMessageId: { $first: "$messageId" },
          latestMessageStatus: { $first: "$status" },
          chatRoomId: { $first: "$chatRoomId" },
          sender: { $first: "$sender" },

          // <--- OPTIMIZATION START --->
          // Instead of pushing ALL messages into an array (RAM heavy),
          // we calculate the unread count directly during the group stage.
          unreadCount: {
            $sum: {
              $cond: [
                {
                  $and: [
                    { $eq: ["$receiver", userObjectId] }, // Message was sent TO me
                    { $in: ["$status", ["sent", "delivered"]] }, // Status is not read
                  ],
                },
                1, // If true, add 1 to count
                0, // If false, add 0
              ],
            },
          },
          // <--- OPTIMIZATION END --->
        },
      },
      // 4. Join User details
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "_id",
          as: "userDetails",
        },
      },
      {
        $unwind: "$userDetails",
      },
      // 5. Format the Final Output
      {
        $project: {
          _id: 0,
          chatType: "private",
          chatRoomId: 1,
          messageId: "$latestMessageId",
          username: "$userDetails.username",
          fullName: "$userDetails.fullName", // <--- Add Name
          profileURL: "$userDetails.profileURL",
          userId: "$userDetails._id",
          latestMessageTime: 1,
          latestMessage: 1,
          sender: 1,
          unreadCount: 1, // Pass the calculated count through
          latestMessageStatus: {
            $cond: [
              { $eq: ["$sender", userObjectId] },
              "$latestMessageStatus",
              null,
            ],
          },
        },
      },
    ]);

    // Sort the final list of chats by time in JS (usually faster for small result sets)
    return privateChats.sort((a, b) => {
      return new Date(b.latestMessageTime) - new Date(a.latestMessageTime);
    });
  } catch (error) {
    console.log(error);
    return [];
  }
};

module.exports = {
  createMessage,
  fetchChatMessages,
  updateMessageStatus,
  getUndeliveredMessages,
  updateUserLastSeen,
  getUserLastSeen,
  getUserOnlineStatus,
  markMessageAsDelivered,
  markMessageAsRead,
  chatRoom,
};
