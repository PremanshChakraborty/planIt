const express = require('express');
const router = express.Router();
const { User } = require('../../models/user');
const auth = require('../../middleware/auth');

// GET user details by ID
router.get('/:userId', auth, async (req, res) => {
    try {
        const user = await User.findById(req.params.userId).select('_id name email imageUrl emergencyContacts');

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'User not found'
            });
        }

        res.status(200).json({
            success: true,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                imageUrl: user.imageUrl,
                emergencyContacts: user.emergencyContacts
            }
        });
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error'
        });
    }
});

module.exports = router;
