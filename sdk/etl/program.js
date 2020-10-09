
const path = require('path');
const helper = require('./helper');
const tman = require('../helper/tree_man');
const shortid = require('shortid');

function _get_name_list(p) {
    let dir = path.dirname(p);
    let idx = 0;
    let names = [];
    do {
        idx++;
        if(dir!=='.') {
            names.unshift(path.basename(dir));
        }
        dir = path.dirname(dir);
    } while(idx<10);
    return names;
}

function _append_tree_run(root, src_rpath) {
    let names = _get_name_list(src_rpath);
    let p = root;
    names.forEach(name => {
        let child = p.children.find(ch => ch.name === name);
        if(!child) {
            let item = { id: shortid.generate(), name: name, kind: 'dir', children: [] }
            tman.insert(p.children, item);
            p = item;
        } else {
            p = child;
        }
    });
    let file = path.basename(src_rpath, '.lua');
    let target = p.children.find(it => it.name === file);
    if(target) {
        return;
    }
    tman.insert(p.children, {
        id: shortid.generate(),
        kind: 'lua',
        name: file,
    });
}

function program_tree_etl2dev(idx_cfg) {
    let proj = idx_cfg.project;
    let proj_apath = path.resolve(proj.path);
    let root = { children: [], kind: 'dir' };
    let prog = idx_cfg.program;
    if(!prog) {
        return root.children;
    }
    for(let run_id in prog) {
        let run = prog[run_id];
        let run_apath = path.resolve(proj_apath, run.src);
        let src_rpath = path.relative(proj_apath, run_apath);
        _append_tree_run(root, src_rpath);
    }
    return root.children;
}

function _find_item(items, src_rpath) {
    let file = path.basename(src_rpath, '.lua');
    let dirs = _get_name_list(src_rpath);
    dirs.forEach(d => {
        items = items.find(it => it.name === d).children;
    });
    return items.find(it => it.name === file);
}

function program_runs_etl2dev(idx_cfg, tree) {
    let prog = idx_cfg.program;
    let proj_apath = path.resolve(idx_cfg.project.path);
    let runs = [];
    for(let run_id in prog) {
        let run = prog[run_id];
        let run_apath = path.resolve(proj_apath, run.src);
        let src_rpath = path.relative(proj_apath, run_apath);
        let item = _find_item(tree, src_rpath);
        let run_item = runs.find(it => it.id === item.id);
        let param = {
            id: run_id,
            title: run_id,
            vars: run.vars,
            option: run.option || {},             
        };
        if(run.topology) {
            param.option.topology = run.topology;
        }

        if(!run_item) {
            runs.push({
                id: item.id,
                code: helper.read_text(run.src, proj_apath),
                params: [param],
            });
        } else {
            run_item.params.push(param);
        }
    }
    return runs;
}

function program_runs_dev2etl(runs) {
    let prog = {};
    runs.forEach(dbr => {
        dbr.params.forEach(para => {
            let r = {};
            if(para.vars && para.vars!==0) {
                r.vars = para.vars;
            }
            if(para.option) {
                r.option = para.option;
            }
            prog[para.id] = r;
        })
    });
    return prog;
}

module.exports = {
    program_tree_etl2dev,
    program_runs_etl2dev,
    program_runs_dev2etl,
};