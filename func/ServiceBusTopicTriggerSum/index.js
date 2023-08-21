module.exports = async function(context, mySbMsg) {
    context.log('JavaScript ServiceBus topic trigger function processed message', mySbMsg);
    context.log(`${mySbMsg.v1} + ${mySbMsg.v2} = ${mySbMsg.v1 + mySbMsg.v2}`) 
};