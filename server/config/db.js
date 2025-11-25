import mongoose from "mongoose";
import "dotenv/config.js";

export const connectDB = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log("MongoDB connected...");
  } catch (err) {
    console.log(err.message);
    process.exit(1);
  }
};
