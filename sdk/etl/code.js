

function code2db(script, proj_id, kind_id, memo, kind) {
    return {
        id: kind_id,
        proj_id: proj_id,
        kind: kind,
        content: {
            script: script,
            memo: memo,
        }
    };
}

function db2script(item) {
    return item.content.script;
}

module.exports = {
    code2db,
    db2script,
};