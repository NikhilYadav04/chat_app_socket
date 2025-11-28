const cloudinary = require("../config/cloudinary");
const streamifier = require("streamifier");

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

/**
 * Uploads a file buffer (image or audio) directly to Cloudinary using streams.
 * * @param {object} file The file object (must contain 'buffer' property from multer).
 * @returns {Promise<object>} The Cloudinary result object.
 */

const uploadMediaService = (file) => {
  return new Promise((resolve, reject) => {
    //* 1. Create the upload stream
    const cld_upload_stream = cloudinary.uploader.upload_stream(
      {
        resource_type: "auto",
        folder: "chat_media",
      },
      (error, result) => {
        if (result) {
          resolve(result);
        } else {
          reject(error || new Error("Cloudinary upload failed."));
        }
      }
    );

    //* 2. Pipe the file buffer directly to the Cloudinary stream
    streamifier.createReadStream(file.buffer).pipe(cld_upload_stream);
  });
};

//* Upload Function ( image and video both )
const uploadFileWrapper = async (file) => {
  try {
    return await uploadMediaService(file);
  } catch (error) {
    console.error("Cloudinary upload error:", error);
    throw error;
  }
};

module.exports = {
  uploadImageService,
  deleteImageService,
  uploadFileWrapper
};
