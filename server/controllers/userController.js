const { register, login } = require("../services/authService");
const User = require("../models/user");
const { getUserProfile } = require("../services/userService");
const message = require("../models/message");

const registerUser = async (req, res) => {
  const { fullName, username, password } = req.body;
  try {
    const user = await register(fullName, username, password);
    return res.status(201).json(user);
  } catch (error) {
    return res.status(500).json({ message: "Error registering user" });
  }
};

const loginUser = async (req, res) => {
  const { username, password } = req.body;
  try {
    const response = await login(username, password);
    if (!response) {
      return res.status(401).json({ message: "Login Failed" });
    }
    return res.status(200).json(response);
  } catch (error) {
    return res.status(500).json({ message: "Login error" });
  }
};

const getUsers = async (req, res) => {
  try {
    const userId = req.userId;

    //* Check if requester is authorized
    const authUser = await User.findById(userId);

    if (!authUser) {
      return res.status(404).json({
        message: "Not Authorized",
      });
    }

    //* Fetch ALL users from the database
    const allUsers = await User.find({ _id: { $ne: userId } });

    return res.status(200).json({
      allUsers,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Error fetching users",
      error: error.message,
    });
  }
};

const userProfile = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await getUserProfile(userId);

    if (!user) {
      return res.status(400).json({
        message: "No User Found",
      });
    }

    return res.status(200).json({
      user: user,
      message: "User Details",
    });
  } catch (error) {
    return res.status(500).json({
      message: "Error fetching users",
      error: error.message,
    });
  }
};

module.exports = {
  registerUser,
  loginUser,
  getUsers,
  userProfile,
};
