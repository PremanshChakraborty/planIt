const { MongoClient, ObjectId } = require("mongodb");

let cachedClient = null;

async function getMongoClient() {
  if (cachedClient) return cachedClient;

  const uri = process.env.MONGO_URI;
  const client = new MongoClient(uri);
  await client.connect();
  cachedClient = client;
  return client;
}

exports.handler = async (event) => {
  try {
    const client = await getMongoClient();
    const db = client.db();
    const notifications = db.collection("notifications");

    for (const record of event.Records) {
      const message = JSON.parse(record.Sns.Message);

      if (message.eventType === "COLLABORATOR_ADDED") {
        const {
          tripId,
          actorId,
          newCollaboratorId,
          allCollaboratorIds,
          timestamp
        } = message;

        const notificationDocs = allCollaboratorIds.map((userId) => ({
          userId: new ObjectId(userId),
          tripId: new ObjectId(tripId),
          type: "COLLABORATOR_ADDED",
          actorId: new ObjectId(actorId),
          message: "A collaborator was added to your trip",
          read: false,
          createdAt: new Date(timestamp)
        }));

        await notifications.insertMany(notificationDocs);
      }
    }

    return { status: "success" };
  } catch (error) {
    console.error("Error processing SNS event:", error);
    throw error;
  }
};