const {
  uploadImageService,
  deleteImageService,
} = require("../services/cloudinaryService");
const User = require("../models/user");
const message = require("../models/message");

const uploadImage = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });

    const userId = req.userId;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    const result = await uploadImageService(req.file);

    const url = result.secure_url;
    const publicURL = result.public_id;

    //* delete old urls if exists
    if (user.publicURL != "") {
      await deleteImageService(user.publicURL);
    }

    user.profileURL = url;
    user.publicURL = publicURL;

    await user.save();

    res.json({
      message: "Upload successful",
      url: result.secure_url,
      public_id: result.public_id,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Upload failed" });
  }
};

const deleteImage = async (req, res) => {
  try {
    const userId = req.userId;

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    const public_id = user.publicURL;

    if (!public_id)
      return res.status(400).json({ error: "public_id required" });

    const result = await deleteImageService(public_id);

    if (result) {
      user.publicURL = "";
      user.profileURL = "";
      await user.save();
    }

    res.json({ message: "Delete successful", result });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Delete failed" });
  }
};

module.exports = {
  uploadImage,
  deleteImage,
};
