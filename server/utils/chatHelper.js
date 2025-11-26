const getRoomId = (user1, user2) => {
  return [user1, user2].sort().join("_");
};

module.exports = { getRoomId };