const cloudinary = require("../config/cloudinary");

const uploadImageService = async (file) => {
  try {
    // Convert buffer → base64 string
    const base64 = file.buffer.toString("base64");
    const dataUri = `data:${file.mimetype};base64,${base64}`;

    return await cloudinary.uploader.upload(dataUri, {
      resource_type: "auto",
      folder: "uploads",
    });
  } catch (error) {
    console.error("Cloudinary upload error:", error);
    throw error;
  }
};

const deleteImageService = async (publicId) => {
  return await cloudinary.uploader.destroy(publicId);
};

module.exports = {
  uploadImageService,
  deleteImageService,
};
