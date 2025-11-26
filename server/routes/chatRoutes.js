const express = require("express");
const { getChatRoom, getMessages } = require("../controllers/chatController");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/messages", authMiddleware, getMessages);
router.get("/chat-room", authMiddleware, getChatRoom);

module.exports = router;
