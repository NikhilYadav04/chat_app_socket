import User from "../models/user.js";
import mongoose from "mongoose";
import jwt from "jsonwebtoken";

export const register = async (username, password) => {
  if (password.length < 8) {
    return {
      error: "Password must be at least 8 characters",
    };
  }

  try {
    const user = await User.create({ username, password });

    console.log(user)

    return {
      userId: user._id,
    };
  } catch (error) {
    console.log(error)
    if (error.code == 11000) {
      return {
        error: "Username already taken",
      };
    }

    return {
      error: "Failed to register",
    };
  }
};

export const login = async (username, password) => {
  try {
    const user = await User.findOne({ username });

    if (!user) {
      throw new Error("User not found");
    }

    const isMatch = await user.correctPassword(password, user.password);

    if (!isMatch) {
      throw new Error("Invalid Password");
    }

    return {
      token: jwt.sign({ userId: user._id }, process.env.JWT_SECRET, {
        expiresIn: "10d",
      }),
      userId: user._id,
    };
  } catch (error) {
    console.log(error.message);
    return null;
  }
};
