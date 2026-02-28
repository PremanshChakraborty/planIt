const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");

const snsClient = new SNSClient({
    region: ap - south - 1
});

const publishEvent = async (payload) => {
    const topicArn = process.env.SNS_TOPIC_ARN;

    if (!topicArn) {
        throw new Error("SNS_TOPIC_ARN not configured");
    }

    const command = new PublishCommand({
        TopicArn: topicArn,
        Message: JSON.stringify(payload)
    });

    await snsClient.send(command);
}

module.exports = { publishEvent };