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


module.exports = async function (context, req) {
    context.log('JavaScript HTTP trigger function processed a request.');

    message = [
        {
            "v1": 23,
            "v2": 12
        },
        {
            "v1": 32,
            "v2": 21,
        }
    ]

    
    
    const blobName = "sample.csv"
    context.log(`Downloading ${blobName}`);
    const containerClient = await blobServiceClient.getContainerClient("upload");
    const blobClient = containerClient.getBlobClient(blobName);
    const downloadResponse = await blobClient.download();
    const downloaded = await streamToBuffer(downloadResponse.readableStreamBody, context);
    const blobcontent = downloaded.toString()
    context.log(`Downloaded blob content: ${blobcontent}`);
    const records = parse(blobcontent, {
        delimiter: ',',
        skip_empty_lines: true
      })
    const messages = []
    await records.forEach(async (record, index) => {
        context.log(`Record: ${record}`);
        messages.push({
            "v1": record[0],
            "v2": record[1]
        })
    })
    context.bindings.outputSbTopic = messages;
    context.res = {
        // status: 200, /* Defaults to 200 */
        body: {
                "servicebusmessages": messages,
        }
    };
}