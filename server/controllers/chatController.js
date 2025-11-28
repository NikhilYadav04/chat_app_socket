const Message = require("../models/message");
const { chatRoom, fetchChatMessages } = require("../services/chatService");
const {
  uploadImageService,
  uploadFileWrapper,
} = require("../services/cloudinaryService");

const getMessages = async (req, res) => {
  const { senderId, receiverId, page, limit } = req.query;

  try {
    const message = await fetchChatMessages({
      currentUserId: req.userId,
      senderId,
      receiverId,
      page: parseInt(page, 10),
      limit: parseInt(limit, 10),
    });

    res.json(message);
  } catch (e) {
    console.log(e);
    res.status(500).json({
      message: "Error Fetching Messages",
    });
  }
};

const getChatRoom = async (req, res) => {
  try {
    const rooms = await chatRoom(req.userId);

    res.json(rooms);
  } catch (e) {
    console.log(e);
    res.status(500).json({
      message: "Error Fetching Messages",
    });
  }
};

const upload_media = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });

    const result = await uploadFileWrapper(req.file);

    const url = result.secure_url;
    const publicURL = result.public_id;

    return res.status(200).json({
      url: url,
      public_id: publicURL,
    });
  } catch (e) {
    console.log(e);
    res.status(500).json({
      message: "Error Uploading Messages",
    });
  }
};

module.exports = {
  getMessages,
  getChatRoom,
  upload_media,
};
