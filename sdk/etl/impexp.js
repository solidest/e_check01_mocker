const path = require('path');
const fs = require('fs');
const shortid = require('shortid');
const yaml = require('js-yaml');

const Project = require('./wrapper/Project');
const helper = require('./helper');
const tman = require('../helper/tree_man');
const protocol = require('./protocol');
const device = require('./device');
const topology = require('./topology');
const code = require('./code');
const program = require('./program');

function _udpate_etl_xtra(idx_obj, oproj, proj_apath) {
    let proj = idx_obj.project;
    if (proj.xtra) {
        if (proj.xtra.pack) {
            oproj.xtra.pack = helper.read_text(proj.xtra.pack, proj_apath);
        }
        if (proj.xtra.unpack) {
            oproj.xtra.unpack = helper.read_text(proj.xtra.unpack, proj_apath);
        }
        if (proj.xtra.check) {
            oproj.xtra.check = helper.read_text(proj.xtra.check, proj_apath);
        }
        if (proj.xtra.recvfilter) {
            oproj.xtra.recvfilter = helper.read_text(proj.xtra.recvfilter, proj_apath);
        }
    }
}

function _udpate_etl_lib(idx_obj, oproj, proj_apath) {
    let proj = idx_obj.project;
    if (proj.lib_path) {
        let plib = path.resolve(proj_apath, proj.lib_path);
        let dir = fs.readdirSync(plib);
        for (let p of dir) {
            if (path.extname(p) !== '.lua') {
                continue;
            }
            let obj = code.code2db(helper.read_text(p, plib), oproj.id, shortid.generate(), null, 'lib');
            oproj.push_lib(path.basename(p, '.lua'), obj);
        }
    }
}

function import_etl(idx_obj, proj_apath, proj_id) {
    let proj = new Project(proj_id);
    _udpate_etl_xtra(idx_obj, proj, proj_apath);
    _udpate_etl_lib(idx_obj, proj, proj_apath);

    let asts = helper.parse_proj_etl(proj_apath);

    asts.forEach(ast => {
        if (ast.kind === 'protocol') {
            let obj = protocol.protocol_etl2dev(ast, proj_id, shortid.generate());
            proj.push_prot(ast.name, obj);
        } else if (ast.kind === 'device') {
            let obj = device.device_etl2dev(ast, proj_id, shortid.generate());
            proj.push_dev(ast.name, obj);
        }
    });

    asts.forEach(ast => {
        if (ast.kind === 'topology') {
            let obj = topology.topology_etl2dev(ast, proj_id, shortid.generate, null, proj.devs.map(d => {
                return {
                    name: d[0],
                    ctx: d[1]
                }
            }));
            proj.push_topo(ast.name, obj);
        }
    });

    let tree = program.program_tree_etl2dev(idx_obj);
    proj.set_runtree(tree);
    proj.set_runs(program.program_runs_etl2dev(idx_obj, tree));
    return proj;
}

function _make_proj_dirs(outpath) {
    let files = fs.readdirSync(outpath);
    if (files && files.length > 0) {
        throw new Error('导出目录不为空');
    }
    let pathes = {
        protocol: path.resolve(outpath, 'protocol/'),
        device: path.resolve(outpath, 'device/'),
        topology: path.resolve(outpath, 'topology/'),
        libs: path.resolve(outpath, 'libs/'),
        xtra: path.resolve(outpath, 'xtra/'),
        program: path.resolve(outpath, 'program/'),
    }
    for (const key in pathes) {
        fs.mkdirSync(pathes[key]);
    }
    pathes.idx_file = path.resolve(outpath, 'index.yml');
    pathes.root = outpath;
    return pathes;
}

function _makeidx_xtra(xtra) {
    if (!xtra) {
        return {};
    }
    let res = {}
    for (const key in xtra) {
        res[key] = 'xtra/' + key + '.lua';
    }
    return res;
}

function _get_full_path(root_items, id) {
    let item = tman.findItem(root_items, id);
    let file = item.name + '.lua';
    let root = {
        id: 'root',
        kind: 'dir',
        children: root_items
    };
    let p = tman.findParent(root, id);
    while (p !== root) {
        file = p.name + '/' + file;
        p = tman.findParent(root, p.id);
    }
    return file;
}

function _make_idxfile(pathes, proj) {
    let project = {
        id: proj.id,
        path: '.',
        lib_path: path.relative(pathes.root, pathes.libs),
        xtra: _makeidx_xtra(proj.xtra),
        etestd_ip: 'etest',
        etestd_port: 1210,
    }

    let program = {}
    let all_runs = [];
    if (proj.runs) {
        proj.runs.forEach(run => {
            let params = run.params;
            params.forEach(para => {
                program[para.id] = {
                    src: _get_full_path(proj.runtree, run.id),
                    title: para.title,
                    vars: para.vars,
                    option: para.option,
                }
                all_runs.push(para.id);
            });
        });
    }


    return {
        project,
        program,
        runs: {
            all: all_runs
        },
    }
}

function _makeout_dir(parent_path, parent, runs) {
    if (!parent || !runs || !parent.children) {
        return;
    }
    parent.children.forEach(ch => {
        if (ch.kind === 'dir') {
            let dir = path.resolve(parent_path, ch.name);
            fs.mkdirSync(dir);
            _makeout_dir(dir, ch, runs);
        } else if (ch.kind === 'lua') {
            let r = runs.find(r => r.id === ch.id);
            fs.writeFileSync(path.resolve(parent_path, ch.name + '.lua'), r.code);
        }
    })
}

function _makeout_xtra(xpath, xtra) {
    if (!xtra) {
        return;
    }
    for (const key in xtra) {
        fs.writeFileSync(path.resolve(xpath, key + '.lua'), xtra[key]);
    }
}

function export_etl(outpath, proj) {
    let pathes = _make_proj_dirs(outpath);

    let idx_cfg = _make_idxfile(pathes, proj);
    fs.writeFileSync(pathes.idx_file, yaml.safeDump(idx_cfg));

    _makeout_dir(pathes.program, proj.runtree[0], proj.runs);
    _makeout_xtra(pathes.xtra, proj.xtra);

    proj.prots.forEach(prot => {
        fs.writeFileSync(path.resolve(pathes.protocol, prot[0] + '.etl'), protocol.protocol_dev2etl(prot[1], prot[0]));
    });
    proj.devs.forEach(dev => {
        fs.writeFileSync(path.resolve(pathes.device, dev[0] + '.etl'), device.device_dev2etl(dev[1], dev[0]));
    });
    let devs = proj.devs.map(d => {
        return {
            name: d[0],
            ctx: d[1]
        }
    });
    proj.topos.forEach(topo => {
        fs.writeFileSync(path.resolve(pathes.topology, topo[0] + '.etl'), topology.topology_dev2etl(topo[1], topo[0], devs));
    });
    proj.libs.forEach(lib => {
        fs.writeFileSync(path.resolve(pathes.libs, lib[0] + '.lua'), code.db2script(lib[1]));
    });
}

module.exports = {
    import_etl,
    export_etl,
};