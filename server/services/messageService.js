const message = require("../models/message.js");
const Message = require("../models/message.js");
const { deleteImageService } = require("./cloudinaryService.js");

const editMessage = async (id, text) => {
  try {
    const message = await Message.findOne({ messageId: id });

    if (!message) {
      throw new Error("Error : No message found");
    }

    message.isEdited = true;
    message.message = text;
    await message.save();

    return true;
  } catch (e) {
    console.log(e);
    return false;
  }
};

const deleteMessage = async (id) => {
  try {
    const message = await Message.findOne({ messageId: id });

    if (!message) {
      throw new Error("Error : No message found");
    }

    message.isDeleted = true;
    message.message = "deleted";

    const filePublicId = message.filePublicId;

    if (filePublicId) {
      await deleteImageService(message.filePublicId);
    }

    await message.save();

    return true;
  } catch (e) {
    console.log(e);
    return false;
  }
};

const likeMessage = async (id) => {
  try {
    const message = await Message.findOne({ messageId: id });

    if (!message) {
      throw new Error("Error : No message found");
    }

    message.isLiked = true;
    await message.save();

    return true;
  } catch (e) {
    console.log(e);
    return false;
  }
};

module.exports = {
  editMessage,
  deleteMessage,
  likeMessage,
};
