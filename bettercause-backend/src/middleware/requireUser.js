// src/middleware/requireUser.js
module.exports.requireUser = function requireUser(req, res, next) {
  // Option A (simple): X-User-Id header (works immediately)
  const userId = req.header("x-user-id");

  // Option B (if you already have auth middleware setting req.user)
  // const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({ message: "Missing user identity (x-user-id)" });
  }

  req.userId = userId;
  next();
};
