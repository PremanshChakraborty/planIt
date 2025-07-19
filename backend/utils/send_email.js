const nodemailer = require( 'nodemailer');
const winston = require('winston');
const config = require('config');
const { google } = require("googleapis");
const OAuth2 = google.auth.OAuth2;

// const oauth2Client = new OAuth2(
//     config.get('clientId'),
//     config.get('clientSecret'),
//     "https://developers.google.com/oauthplayground"
// );

// oauth2Client.setCredentials({
//     refresh_token: config.get('refreshToken'),
// });

// const accessToken = oauth2Client.getAccessToken();

let transporter = nodemailer.createTransport({
    // host: "smtp.gmail.com",
    // port: 465,
    // secure: true,
    service: 'gmail',
    auth: {
        //type: 'OAuth2',
        user: config.get('adminEmail'),
        pass: config.get('adminEmailPass'),
        // clientId: config.get('clientId'),
        // clientSecret: config.get('clientSecret'),
        // refreshToken: config.get('refreshToken'),
        // accessToken
    }
});

transporter.verify((error, success) => {
    if(error){
        winston.error(error);
    } else{
        winston.info('ready for messages');
    }
});

module.exports = async function sendEmail(email,otp){
    const mailoptions = {
        from: config.get('adminEmail'),
        to: email,
        subject: 'Email Verification Planit',
        text: `Your OTP is ${otp}. it will expire in 10 mins`
    };
    try{
        await transporter.sendMail(mailoptions);
        return;
    } catch (error) {
        throw error;
    }
}
