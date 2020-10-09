
const num_propers = [
    'port', 'keepalive', 'baudrate', 'bytesize', 'stopbits', 'ttl'
];

function _get_mapping(doc, all_devs) {
    let raw = doc.mapping || [];
    let mapping = [];
    for (let d of all_devs) {
        let rd = raw.find(it => it.dev_id === d.id);
        mapping.push({
            dev_id: d.id,
            used: (rd && rd.used) ? rd.used : 'none'
        });
    }
    return mapping;
}


function _get_linking(doc, all_conns) {
    let raw = doc.linking || [];
    let linking = [];
    for (let l of raw) {
        let cids = l.conns || [];
        let new_conns = [];
        for (let cid of cids) {
            let c = all_conns.find(it => it.id === cid);
            if (c) {
                new_conns.push(cid);
            }
        }
        if (new_conns.length === 0) {
            continue;
        }
        linking.push({
            id: l.id,
            conns: new_conns
        });
    }
    return linking;
}

function _get_binding(doc, all_conns) {
    let raw = doc.binding || [];
    let binding = [];
    for (let bind of raw) {
        let c = all_conns.find(it => it.id === bind.conn_id);
        if (c) {
            binding.push(bind);
        }
    }
    return binding;
}

function load_topo(devs, content) {
    let conns = [];
    for (let d of devs) {
        let items = d.items || [];
        d.conns = items.map(it => {
            return {
                id: it.id,
                name: it.name,
                kind: it.kind
            }
        });
        for (let c of d.conns) {
            conns.push({
                id: c.id,
                conn_obj: c,
                dev_obj: d
            });
        }
    }
    return {
        devs: devs,
        conns: conns,
        mapping: _get_mapping(content, devs),
        linking: _get_linking(content, conns),
        binding: _get_binding(content, conns),
        draw_data: content.draw_data,
        memo: content.memo || '',
    }
}

class Topology {
    constructor(data, name, devs) {
        this.data = data;
        this.devs = devs;
        this.name = name;
    }

    get id() {
        return this.data.id;
    }

    
    _get_config(cfg) {
        if(!cfg) {
            return null;
        }
        let res = {};
        for(let k in cfg) {
            if(num_propers.includes(k)) {
                if(isNaN(cfg[k])) {
                    continue;
                }
                let v = Number.parseInt(cfg[k]);
                if(!isNaN(v)) {
                    res[k] = v;
                }
            } else {
                res[k] = cfg[k]
            }
        }
        return res;
    }

    get_dev_name(id) {
        let dev = this.devs.find(it => it.id === id);
        return dev ? dev.name : '';
    }

    set_conn_target(oconn, conn_id) {
        let linking = this.topo.linking;
        if(!linking) {
            return;
        }
        // console.log(linking, oconn, conn_id);
        let link = linking.find(l => l.conns && l.conns.includes(conn_id));
        
        if(link) {
            if(link.conns.length === 2) {
                let t_id = link.conns.find(id => id !== conn_id);
                oconn.target = this.get_dev_conn_name(t_id);
                return;
            }
            let targets = [];
            link.conns.forEach(id => {
                if(id !== conn_id) {
                    targets.push(this.get_dev_conn_name(id));
                }
            })
            oconn.targets = targets;
            return;
        }
    }

    get_dev_conn_name(conn_id) {
        let conns = this.topo.conns;
        if(!conns) {
            return '';
        }
        let oo = conns.find(c => c.id === conn_id);
        return {device: oo.dev_obj.name, connector: oo.conn_obj.name}
    }

    get_conn_uri(id) {
        let binding = this.topo.binding;
        if(!binding) {
            return null;
        }
        let bind = binding.find(b => b.conn_id === id);
        if(bind) {
            return bind.uri;
        }
    }

    get_dev_conns(id) {
        let dev = this.devs.find(it => it.id === id);
        let res = [];
        let conns = dev.connectors;
        conns.forEach(conn => {
            let oconn = {name: conn.name, config: this._get_config(conn.config), type: conn.kind };
            let uri = this.get_conn_uri(conn.id);
            if(uri) {
                oconn.uri = uri;
            }
            this.set_conn_target(oconn, conn.id);
            res.push(oconn);
        })
        // console.log(res)
        return res;
    }

    make_out() {
        let devs = this.devs.map(it => {
            return {
                id: it.id,
                name: it.name,
                items: it.items
            }
        });
        let doc = (this.data && this.data.content) ? this.data.content : {};
        this.topo = load_topo(devs, doc);

        devs = [];
        let mapping = this.topo.mapping;
        if(mapping) {
            mapping.forEach(dev => devs.push({'map': dev.used, name: this.get_dev_name(dev.dev_id), connectors: this.get_dev_conns(dev.dev_id)}))
        }
        return {name: this.name, devices: devs};
    }
}

module.exports = Topology;