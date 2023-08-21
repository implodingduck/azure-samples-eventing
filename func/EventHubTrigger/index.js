const { BlobServiceClient } = require('@azure/storage-blob');
const { DefaultAzureCredential } = require('@azure/identity');
require('dotenv').config()

const accountName = process.env.SANAME;
const blobServiceClient = new BlobServiceClient(
  `https://${accountName}.blob.core.windows.net`,
  new DefaultAzureCredential()
);

async function streamToBuffer(readableStream, context) {
    context.log("lets streamToBuffer")
    return new Promise((resolve, reject) => {
        const chunks = [];
        readableStream.on("data", (data) => {
            context.log("onData")
            chunks.push(data instanceof Buffer ? data : Buffer.from(data));
        });
        readableStream.on("end", () => {
            context.log("onEnd")
            resolve(Buffer.concat(chunks));
        });
        readableStream.on("error", reject);
    });
}

module.exports = async function (context, eventHubMessages) {
    context.log(`JavaScript eventhub trigger function called for message array ${eventHubMessages}`);
   
    const containerClient = await blobServiceClient.getContainerClient("upload");
    const messages = []
    eventHubMessages.forEach(async (messageArr, index) => {
        const message = messageArr[0]
        context.log(`Processed message ${JSON.stringify(message)}`);
        if (message.data.url.indexOf("/upload/") > -1){
            const blobName = message.data.url.split(`https://${accountName}.blob.core.windows.net/upload/`)[1]
            context.log(`Downloading ${blobName}`);
            const blobClient = containerClient.getBlobClient(blobName);
            const downloadResponse = await blobClient.download();
            context.log(downloadResponse)
            const downloaded = await streamToBuffer(downloadResponse.readableStreamBody, context);
            context.log("Downloaded blob content:", downloaded.toString());
        }
    });
    if (messages.length > 0) {
        context.bindings.outputSbTopic = messages;
    }
};