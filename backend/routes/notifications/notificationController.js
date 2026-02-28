const Notification = require("../../models/notification");

exports.getNotifications = async (req, res) => {
    try {
        const userId = req.user.id;

        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;

        const notifications = await Notification.find({ userId })
            .sort({ createdAt: -1 })
            .skip((page - 1) * limit)
            .limit(limit)
            .populate("tripId", "destination type name")
            .populate("actorId", "name imageUrl");

        const unreadCount = await Notification.countDocuments({
            userId,
            read: false
        });

        res.status(200).json({
            notifications,
            unreadCount
        });
    } catch (error) {
        console.error("Error fetching notifications:", error);
        res.status(500).json({ message: "Failed to fetch notifications" });
    }
};