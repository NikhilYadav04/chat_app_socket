import { register, login } from "../services/authService.js";
import User from "../models/user.js";

export const registerUser = async (req, res) => {
  const { username, password } = req.body;
  try {
    const user = await register(username, password);
    return res.status(201).json(user);
  } catch (error) {
    return res.status(500).json({ message: "Error registering user" });
  }
};

export const loginUser = async (req, res) => {
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

export const getUsers = async (req, res) => {
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
    const allUsers = await User.find(
      { _id: { $ne: userId } } // exclude current user
    );

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
