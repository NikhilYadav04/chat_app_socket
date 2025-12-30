const { fetchCallHistory } = require("../services/callServices.js");

const getCallHistory = async (req, res) => {
  try {
    const { page, limit } = req.query;
    const currentUserId = req.userId;

    const history = await fetchCallHistory({
      currentUserId,
      page: parseInt(page) || 1,
      limit: parseInt(limit) || 20,
    });

    res.status(200).json({
      success: true,
      data: history,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

const deleteCallHistory = async (req, res) => {
  try {
    const currentUserId = req.userId;

    const deletedData = await deleteCallHistory({
      currentUserId,
    });

    res.status(200).json({
      success: true,
      data: deletedData,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

module.exports = {
  getCallHistory,
  deleteCallHistory,
};
