const { Router } = require("express");
const { upload } = require("../middleware/multer");
const { uploadImage, deleteImage } = require("../controllers/uploadController");
const authMiddleware = require("../middleware/authMiddleware");

const router = Router();

// Ensure the string "photo" matches the key used in your frontend FormData
router.post("/upload", authMiddleware, upload.single("photo"), uploadImage);
router.delete("/delete", authMiddleware, deleteImage);

module.exports = router;
