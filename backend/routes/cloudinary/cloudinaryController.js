const {User} = require('../../models/user');
const cloudinary = require('cloudinary').v2;

// Ensure your config is loaded
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

exports.getUploadSignature = (req, res) => {
  // Cloudinary requires a timestamp in seconds (not milliseconds)
  const timestamp = Math.round((new Date()).getTime() / 1000);

  // 1. Define the parameters you want to sign
  const paramsToSign = {
    timestamp: timestamp,
    folder: 'planit/users',       // Must match the folder you set in Dashboard
    upload_preset: 'planit_user_uploads', // Must match the preset you created
  };

  // 2. Generate the signature
  const signature = cloudinary.utils.api_sign_request(
    paramsToSign,
    process.env.CLOUDINARY_API_SECRET
  );

  // 3. Send only the public data to the client (NEVER send the secret)
  res.json({
    signature,
    timestamp,
    cloudName: process.env.CLOUDINARY_CLOUD_NAME,
    apiKey: process.env.CLOUDINARY_API_KEY,
    folder: paramsToSign.folder, 
    uploadPreset: paramsToSign.upload_preset
  });
};

exports.updateProfileImage = async (req, res) => {
    try {
      // 1. Get the data sent from Flutter
      const { imageUrl, publicId } = req.body;
      const userId = req.user._id; // Assuming you get this from your auth middleware
  
      // 2. Find the current user
      const user = await User.findById(userId);
      if (!user) {
        return res.status(404).json({ status: 'fail', message: 'User not found' });
      }
  
      // 3. SMART STEP: Delete the OLD image from Cloudinary if it exists
      // We check if there is a public ID and if it's different from the new one
      if (user.imagePublicId && user.imagePublicId !== publicId) {
        await cloudinary.uploader.destroy(user.imagePublicId);
      }
  
      // 4. Update database with new info
      user.imageUrl = imageUrl;
      user.imagePublicId = publicId;
      await user.save();
  
      res.status(200).json({
        status: 'success',
        data: {
          user: user
        }
      });
  
    } catch (err) {
      console.error(err);
      res.status(500).json({ status: 'error', message: 'Server error updating image' });
    }
  };