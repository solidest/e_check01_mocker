const shortid = require("shortid");


function _get_link(devs, items) {
    if(!items) {
        return null;
    }
    let conns = [];
    items.forEach(it => {
        if(it.kind === 'dev_connector') {
            let dev = devs.find(d => d.name === it.device);
            if(dev && dev.ctx.content && dev.ctx.content.items) {
                let conn = dev.ctx.content.items.find(c => c.name === it.connector);
                if(conn) {
                    conns.push(conn.id);
                }
            }
        }
    });
    if(conns.length===0) {
        return null;
    }
    return {
        id: shortid.generate(),
        conns: conns,
    }
}

function _get_maps(devs, items, kind) {
    if(!items) {
        return null;
    }
    let maps = [];
    items.forEach(it => {
        let dev = devs.find(d => d.name === it);
        if(dev) {
            maps.push({
                dev_id: dev.ctx.id,
                used: kind,
            });
        }
    });
    if(maps.length===0){
        return null;
    }
    return maps;
}

function _get_bind(devs, item) {
    if(!item || !item.bind) {
        return null;
    }
    let dev = devs.find(d => d.name === item.device);
    if(dev && dev.ctx.content && dev.ctx.content.items) {
        let conn = dev.ctx.content.items.find(c => c.name === item.connector);
        if(conn) {
            return {
                conn_id: conn.id,
                uri: item.bind,
            }
        }
    }
    return null;
}

function topology_etl2dev(ast, proj_id, kind_id, memo, devs) {
    let mapping = [];
    let linking = [];
    let binding = [];
    if(!devs) {
        devs = [];
    }

    if(ast.value) {
        ast.value.forEach(item => {
            if(item.kind === 'linking') {
                let link = _get_link(devs, item.value);
                if(link) {
                    linking.push(link);
                }
            } else if(['etest', 'uut'].includes(item.kind)) {
                let maps = _get_maps(devs, item.value, item.kind);
                if(maps) {
                    mapping.push(...maps);
                }
            } else if(item.kind === 'binding') {
                let bind = _get_bind(devs, item);
                if(bind) {
                    binding.push(bind);
                }
            }
        });
    }

    let topo = {
        id: kind_id,
        proj_id: proj_id,
        kind: 'topology',
        content: {
            mapping: mapping,
            linking: linking,
            binding: binding,
            memo: memo,
        }
    };
    return topo;
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

function _append_code_mapping(codes, level, mapping, devs) {
    if(!mapping || mapping.length === 0) {
        return;
    }

    let res = {uut: [], etest: []}
    _append_code(codes, level, 'mapping: {');
    mapping.forEach(map => {
        if(['uut', 'etest'].includes(map.used)) {
            let dev = devs.find(d => d.ctx.id === map.dev_id);
            if(dev) {
                res[map.used].push(dev.name);
            }
        }
    });
    if(res.uut.length>0) {
        _append_code(codes, level+1, `uut: [${res.uut.join(', ')}],`);
    }
    if(res.etest.length>0) {
        _append_code(codes, level+1, `etest: [${res.etest.join(', ')}],`);
    }
    _append_code(codes, level, '}');
}

function _get_devconn_name(devs, conn_id) {
    if(!devs) {
        return null;
    }

    for(let d of devs) {
        if(d.ctx && d.ctx.content && d.ctx.content.items) {
            let c = d.ctx.content.items.find(it => it.id === conn_id);
            if(c) {
                return `${d.name}.${c.name}`;
            }
        }
    }
    return null;
}

function _append_code_linking(codes, level, linking, devs) {
    if(!linking) {
        linking = [];
    }

    _append_code(codes, level, 'linking: {');
    linking.forEach(link => {
        if(link.conns) {
            let conns = [];
            link.conns.forEach(c => {
                let devconn_name = _get_devconn_name(devs, c);
                if(devconn_name) {
                    conns.push(devconn_name);
                }
            });
            if(conns.length>0) {
                _append_code(codes, level+1, `_ : [${conns.join(', ')}], `);
            }
        }
    });
    _append_code(codes, level, '}');
}


function _append_code_binding(codes, level, binding, devs) {
    if(!binding) {
        binding = [];
    }

    _append_code(codes, level, 'binding: {');
    binding.forEach(bind => {
        _append_code(codes, level+1, `${_get_devconn_name(devs, bind.conn_id)}: '${bind.uri}',`)
    });
    _append_code(codes, level, '}');
}


function topology_dev2etl(topo, name, devs) {
    if (!topo || !topo.content) {
        return `topology ${name} {\n}`;
    }
    if(!devs) {
        devs = [];
    }
    let content = topo.content;
    let codes = [];
    if (content.memo) {
        _append_code(codes, 0, `// ${content.memo}`);
    }
    _append_code(codes, 0, `topology ${name} {`);
    _append_code_mapping(codes, 1, content.mapping, devs);
    _append_code_linking(codes, 1, content.linking, devs);
    _append_code_binding(codes, 1, content.binding, devs);
    _append_code(codes, 0, '}');
    let texts = codes.map(it => `${'\t'.repeat(it.level)}${it.code}`);
    return texts.join('\n');
}

module.exports = {
    topology_etl2dev,
    topology_dev2etl,
};