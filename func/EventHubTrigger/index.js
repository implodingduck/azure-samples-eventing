const { BlobServiceClient } = require('@azure/storage-blob');
const { DefaultAzureCredential } = require('@azure/identity');
const { parse } = require('csv-parse/sync')
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
    await eventHubMessages.forEach(async (messageStr, index) => {
        const messageArr = JSON.parse(messageStr)
        context.log(`This is messageArr ${messageArr}`);
        await messageArr.forEach(async (message, index) => {
            context.log(`${JSON.stringify(message)}`);
            
            if (message.data.url.indexOf("/upload/") > -1){
                const blobName = message.data.url.split(`https://${accountName}.blob.core.windows.net/upload/`)[1]
                context.log(`Downloading ${blobName}`);
                const blobClient = containerClient.getBlobClient(blobName);
                const downloadResponse = await blobClient.download();
                context.log(downloadResponse)
                const downloaded = await streamToBuffer(downloadResponse.readableStreamBody, context);
                const blobcontent = downloaded.toString()
                context.log(`Downloaded blob content: ${blobcontent}`);
                const records = parse(blobcontent, {
                    delimiter: ',',
                    skip_empty_lines: true
                })
                await records.forEach(async (record, index) => {
                    context.log(`Record: ${record}`);
                    messages.push({
                        "v1": record[0],
                        "v2": record[1],
                        "operation": record[2]
                    })
                })
            }
        })
        
    });
    if (messages.length > 0) {
        context.bindings.outputSbTopic = messages;
    }
};