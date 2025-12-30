const mongoose = require("mongoose");
const call = require("../models/call");

const fetchCallHistory = async ({ currentUserId, page = 1, limit = 20 }) => {
  try {
    const userId = new mongoose.Types.ObjectId(currentUserId);

    const calls = await call.aggregate([
      //* Match calls where user is Caller OR Receiver
      {
        $match: {
          $or: [{ callerId: userId }, { receiverId: userId }],
        },
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
      //* Add ONLY the 'isCaller' boolean
      {
        $addFields: {
          isCaller: {
            $eq: ["$callerId", userId],
          },
        },
      },
    ]);

    return calls;
  } catch (error) {
    console.error("Error fetching call history:", error);
    throw error;
  }
};

const clearCallerHistory = async ({ currentUserId }) => {
  try {
    const userId = new mongoose.Types.ObjectId(currentUserId);

    //* PERMANENTLY delete all call logs where 'currentUserId' was the Caller.
    const result = await calls.deleteMany({
      callerId: userId,
    });

    return {
      success: true,
      deletedCount: result.deletedCount,
      message: `Successfully deleted ${result.deletedCount} outgoing calls.`,
    };
  } catch (error) {
    console.error("Error clearing caller history:", error);
    throw error;
  }
};

module.exports = { fetchCallHistory , clearCallerHistory};
