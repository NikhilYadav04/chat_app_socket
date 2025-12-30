const express = require("express");

const authMiddleware = require("../middleware/authMiddleware.js");
const {
  getCallHistory,
  deleteCallHistory,
} = require("../controllers/callController.js");
const router = express.Router();

router.get("/history", authMiddleware, getCallHistory);
router.delete("/history", authMiddleware, deleteCallHistory);

module.exports = router;
