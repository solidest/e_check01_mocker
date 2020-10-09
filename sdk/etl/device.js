const shortid = require("shortid");
const helper = require("./helper");

function _set_props(obj, props) {
    if (!props) {
        return;
    }
    props.forEach(prop => {
        let v = helper.exp2str(prop.value, true);
        obj[prop.name] = v;
    });
}

function device_etl2dev(ast, proj_id, kind_id, memo) {
    let items = [];

    let dev = {
        id: kind_id,
        proj_id: proj_id,
        kind: 'device',
        content: {
            items: items,
            memo: memo,
        }
    };

    if (!ast.value) {
        return dev;
    }

    ast.value.forEach(conn => {
        if(conn.kind === 'connector') {
            let cfg = {};
            _set_props(cfg, conn.config);
            let item = {
                id: shortid.generate(),
                kind: conn.type,
                name: conn.name,
                config: cfg,
            }
            items.push(item);
        }
    })
    return dev;
}

function _append_code(codes, level, code) {
    if(code === undefined || code === null) {
        return;
    }
    codes.push({
        level: level,
        code: code
    });
}

function _append_code_conn(codes, level, it) {
    if (it.option && it.option.memo) {
        _append_code(codes, level, `//${it.memo}`);
    }
    _append_code(codes, level, `${it.kind} ${it.name}{`);
    if(it.config) {
        helper.append_codes_objprops(codes, level+1, it.config);
    }
    _append_code(codes, level, '}');
}

function device_dev2etl(dev, name) {
    if (!dev || !dev.content) {
        return `device ${name} {\n}`;
    }
    let content = dev.content;
    let codes = [];
    if (content.memo) {
        _append_code(codes, 0, `// ${content.memo}`);
    }
    _append_code(codes, 0, `device ${name} {`);
    if(content.items) {
        content.items.forEach(it => {
            _append_code_conn(codes, 1, it);
        })
    }
    _append_code(codes, 0, '}');
    let texts = codes.map(it => `${'\t'.repeat(it.level)}${it.code}`);
    return texts.join('\n');
}


module.exports = {
    device_etl2dev,
    device_dev2etl,
};