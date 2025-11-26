const express = require("express");
const {
  registerUser,
  loginUser,
  getUsers,
  userProfile,
} = require("../controllers/userController");
const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/register", registerUser);
router.post("/login", loginUser);
router.get("/users", authMiddleware, getUsers);
router.get("/profile", authMiddleware, userProfile);

module.exports = router;
