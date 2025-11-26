const User = require("../models/user");
const mongoose = require("mongoose");

const getUserProfile = async (userId) => {
  try {
    const user = await User.findById(userId).select("-password");

    if (!user) {
      throw new Error("User Not Found");
    }

    return user;
  } catch (e) {
    console.log(e);
    return null;
  }
};

module.exports = { getUserProfile };
