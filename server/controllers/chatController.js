import Message from "../models/message.js";
import { chatRoom, fetchChatMessages } from "../services/chatService.js";

export const getMessages = async (req, res) => {
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
    console.log(e)
    res.status(500).json({
      message: "Error Fetching Messages",
    });
  }
};

export const getChatRoom = async (req, res) => {
  try {
    const rooms = await chatRoom(req.userId);

    res.json(rooms);
  } catch (e) {
    res.status(500).json({
      message: "Error Fetching Messages",
    });
  }
};
