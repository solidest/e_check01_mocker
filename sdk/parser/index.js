
const etlParser = require('./etxParser');
const blockPraser = require('./etlParser');
const segParser = require('./segParser');
const expParser = require('./expParser');


function parseEtl(code) {
    return etlParser.parse(code);
}

function parseSegtype(code) {
    return segParser.parse(code);
}

function parseExp(code) {
    return expParser.parse(code);
}

function parseBlock(code) {
    return blockPraser.parse(code);
}

module.exports = {
    parseEtl,
    parseExp,
    parseSegtype,
    parseBlock,
};
