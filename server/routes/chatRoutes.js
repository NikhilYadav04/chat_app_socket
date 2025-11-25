import express from "express";
import { getChatRoom, getMessages } from "../controllers/chatController.js";

import authMiddleware from "../middleware/authMiddleware.js";

const router = express.Router();

router.get("/messages", authMiddleware, getMessages);
router.get("/chat-room", authMiddleware, getChatRoom);

export default router;
