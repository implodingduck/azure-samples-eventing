module.exports = async function (context, req) {
    context.log('JavaScript HTTP trigger function processed a request.');

    message = [
        {
            "v1": 23,
            "v2": 12,
            "operation": "sum"
        },
        {
            "v1": 32,
            "v2": 21,
            "operation": "multiply"
        }
    ]

    context.bindings.outputSbTopic = message;
    context.res = {
        // status: 200, /* Defaults to 200 */
        body: message
    };
}