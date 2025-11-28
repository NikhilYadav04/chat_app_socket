const express = require("express");
const {
  getChatRoom,
  getMessages,
  upload_media,
} = require("../controllers/chatController");
const authMiddleware = require("../middleware/authMiddleware");
const { upload } = require("../middleware/multer");

const router = express.Router();

router.get("/messages", authMiddleware, getMessages);
router.get("/chat-room", authMiddleware, getChatRoom);

router.post(
  "/upload-media",
  authMiddleware,
  upload.single("media"),
  upload_media
);

module.exports = router;
