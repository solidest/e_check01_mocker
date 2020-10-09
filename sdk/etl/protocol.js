const shortid = require('shortid');
const helper = require('./helper');


function _set_props(obj, props) {
    if (!props) {
        return;
    }
    props.forEach(prop => {
        let v = helper.exp2str(prop.value, true);
        if(prop.name === 'autovalue') {
            switch (prop.value.kind) {
                case 'string':
                    obj[prop.name] = `'${v}'`;
                    break;
                case 'array':
                    obj[prop.name] = `${JSON.stringify(v)}`;
                    break;
                default:
                    obj[prop.name] = v;
                    break;
            }
        } else if(prop.name === 'endswith') {
            obj[prop.name] = `'${v}'`;
        } else if(prop.name === 'parser' && prop.value && helper.is_array(prop.value)) {
            let res = [];
            let pack = prop.value.find(it => it.name === 'pack');
            if(pack && pack.value && pack.value.kind === 'pid') {
                res.push(`pack: ${pack.value.list[0]}`);
            }
            let unpack = prop.value.find(it => it.name === 'unpack');
            if(unpack && unpack.value && unpack.value.kind === 'pid') {
                res.push(`unpack: ${unpack.value.list[0]}`);
            }
            obj.parser = `{ ${res.join(', ')} }`;
        } else {
            obj[prop.name] = v;
        }
    })
}

function _append_segment(items, seg) {
    let item = {
        id: shortid.generate(),
        kind: 'segment',
        name: seg.name,
    };
    if (seg.repeated) {
        item.arrlen = helper.exp2str(seg.repeated, true);
    }
    _set_props(item, seg.props);
    items.push(item);
}

function _append_segments(items, seg) {
    let sub_items = [];
    _append_seglist(sub_items, seg.seglist);

    let item = {
        id: shortid.generate(),
        kind: 'segments',
        name: seg.name,
        items: sub_items,
    }
    if (seg.repeated) {
        item.arrlen = helper.exp2str(seg.repeated, true);
    }
    items.push(item);
}

function _append_oneof(items, seg) {
    let exp = helper.exp2str(seg.exp, true);
    let seg_oneof;
    if (items.length > 0 && items[items.length - 1].kind === 'oneof') {
        seg_oneof = items[items.length - 1];
    } else {
        seg_oneof = {
            id: shortid.generate(),
            kind: 'oneof',
            items: [],
        };
        items.push(seg_oneof);
    }
    let seg_oneof_item = {
        id: shortid.generate(),
        kind: 'oneofitem',
        condition: exp,
        items: [],
    }
    _append_seglist(seg_oneof_item.items, seg.seglist);
    seg_oneof.items.push(seg_oneof_item);
}

function _append_seglist(items, seglist) {
    seglist.forEach(seg => {
        switch (seg.kind) {
            case 'segment':
                _append_segment(items, seg);
                break;
            case 'seggroup':
                _append_segments(items, seg);
                break;
            case 'oneof':
                _append_oneof(items, seg);
                break;
            default:
                console.error('segkind', seg.kind);
                break;
        }
    })
}

function protocol_etl2dev(ast, proj_id, kind_id, memo) {
    let items = [];

    let prot = {
        id: kind_id,
        proj_id: proj_id,
        kind: 'protocol',
        content: {
            items: items,
            bitalign: ast.bittype || 'lr',
            memo: memo,
        }
    };

    if (!ast.seglist) {
        return prot;
    }

    _append_seglist(items, ast.seglist);
    return prot;
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

function _append_code_segment(codes, level, it) {
    if (it.memo) {
        _append_code(codes, level, `//${it.memo}`);
    }
    _append_code(codes, level, it.arrlen ? `segment ${it.name}[${it.arrlen}] {` : `segment ${it.name} {`);

    let parser = (it.parser || '').trim();
    if (parser.startsWith('{')) {
        _append_code(codes, level + 1, helper.prop2raw(it, 'parser'));
    } else {
        _append_code(codes, level + 1, helper.prop2str(it, 'parser'));
    }

    ['autovalue', 'endswith', 'length', 'scale'].forEach(key => {
        _append_code(codes, level + 1, helper.prop2raw(it, key));
    });

    helper.append_codes_obj(codes, level + 1, it.option, 'option');
    _append_code(codes, level, `}`);
}

function _append_code_segments(codes, level, it) {
    _append_code(codes, level, it.arrlen ? `segments ${it.name}[${it.arrlen}] {` : `segments ${it.name} {`);
    _append_code_seglist(codes, level+1, it.items)
    _append_code(codes, level, `}`);
}

function _append_code_oneof(codes, level, it, last_kind) {
    if(!it.items || it.items.length === 0) {
        return;
    }
    if(last_kind === 'oneof') {
        _append_code(codes, level, `segment ${shortid.generate().replace('-', '_')} { }`);
        last_kind = 'segment';
    }
    it.items.forEach(it => {
        _append_code(codes, level, `oneof(${it.condition||''}) {`);
        _append_code_seglist(codes, level+1, it.items);
        _append_code(codes, level, '}');
    });
}

function _append_code_seglist(codes, level, items) {
    if (!items) {
        return;
    }
    let _last_kind = '';
    items.forEach(it => {
        switch (it.kind) {
            case 'segment':
                _append_code_segment(codes, level, it);
                break;
            case 'segments':
                _append_code_segments(codes, level, it);
                break;
            case 'oneof':
                _append_code_oneof(codes, level, it, _last_kind);
                break;
            default:
                console.error('segkind', it.kind);
                break;
        }
        _last_kind = it.kind;
    });
}

function protocol_dev2etl(prot, name) {
    if (!prot || !prot.content) {
        return `bitrl protocol ${name} {\n}`;
    }
    let content = prot.content;
    let codes = [];
    if (content.memo) {
        _append_code(codes, 0, `// ${content.memo}`);
    }
    _append_code(codes, 0, `bit${content.bitalign||'rl'} protocol ${name} {`);
    _append_code_seglist(codes, 1, content.items);
    _append_code(codes, 0, '}');
    let texts = codes.map(it => `${'\t'.repeat(it.level)}${it.code}`);
    return texts.join('\n');
}

module.exports = {
    protocol_etl2dev,
    protocol_dev2etl,
};