const path = require('path');
const fs = require('fs');
const shortid = require('shortid');
const yaml = require('js-yaml');

const protocol = require('./protocol');
const device = require('./device');
const topology = require('./topology');
const helper = require('./helper');

const MKPprotocol = require('./wrapper/Protocol');
const MKDevice = require('./wrapper/Device');
const MKTopology = require('./wrapper/Topology');


function _project_etlenv(idx_cfg) {
    let proj = idx_cfg.project;
    let proj_apath = path.resolve(proj.path);
    let proj_id = proj.id;

    let prots = [];
    let devs = [];
    let topos = [];
    let libs = [];
    let xtra = {};
    
    let asts = helper.parse_proj_etl(proj_apath);
    asts.forEach(ast => {
        if (ast.kind === 'protocol') {
            let obj = protocol.protocol_etl2dev(ast, proj_id, shortid.generate(), '');
            prots.push({name: ast.name, ctx: obj})
        }
    });
    asts.forEach(ast => {
        if (ast.kind === 'device') {
            let obj = device.device_etl2dev(ast, proj_id, shortid.generate(), '');
            devs.push({name: ast.name, ctx: obj});
        }
    });
    asts.forEach(ast => {
        if (ast.kind === 'topology') {
            let obj = topology.topology_etl2dev(ast, proj_id, shortid.generate(), '', devs);
            topos.push({name: ast.name, ctx: obj});
        }
    });

    if(proj.lib_path) {
        let plibs = path.resolve(proj_apath, proj.lib_path);
        let dir = fs.readdirSync(plibs);
        for (let p of dir) {
            if (path.extname(p) !== '.lua') {
                continue;
            }
            libs.push({name: p, ctx: helper.read_text(p, plibs)});
        }
    }
    if(proj.xtra) {
        if(proj.xtra.pack) {
            xtra.pack = helper.read_text(proj.xtra.pack, proj_apath);
        }
        if(proj.xtra.unpack) {
            xtra.unpack = helper.read_text(proj.xtra.unpack, proj_apath);
        }
        if(proj.xtra.check) {
            xtra.check = helper.read_text(proj.xtra.check, proj_apath);
        }
        if(proj.xtra.recvfilter) {
            xtra.recvfilter = helper.read_text(proj.xtra.recvfilter, proj_apath);
        }
    }
    return {
        prots,
        devs,
        topos,
        libs,
        xtra: xtra,
    }
}

function _project_devenv(oproj) {
    let prots = oproj.protocol||[];
    let devs = oproj.device||[];
    let topos = oproj.topology||[];
    let libs = oproj.libs||[];
    let xtra = {};
    if(oproj.xtra) {
        if(oproj.xtra.pack) {
            xtra.pack = oproj.xtra.pack;
        }
        if(oproj.xtra.unpack) {
            xtra.unpack = oproj.xtra.unpack
        }
        if(oproj.xtra.check) {
            xtra.check = oproj.xtra.check;
        }
        if(oproj.xtra.recvfilter) {
            xtra.recvfilter = oproj.xtra.recvfilter;
        }
    }
    return {
        prots,
        devs,
        topos,
        libs,
        xtra,
    }
}

function _makeout_topos(devs, topos) {
    let odevs = devs.map(dev=>new MKDevice(dev.ctx, dev.name));
    let otopos = topos.map(topo => new MKTopology(topo.ctx, topo.name, odevs));
    return otopos.map(otopo => otopo.make_out());
}

function _makeout_env(oenv, proj_id) {
    let res = {
        proj_id,
        xtra: oenv.xtra,
        libs: oenv.libs.map(it => {
            return {
                file: it.name,
                code: it.ctx,
            }
        }),
        prots: oenv.prots.map(it => {
            let mk = new MKPprotocol(it.ctx, it.name);
            return mk.make_out();
        }),
        topos: _makeout_topos(oenv.devs, oenv.topos),
    }
    return res;
}

function makeout_etl2env(idx_cfg) {
    try {
        let oenv = _project_etlenv(idx_cfg);
        return _makeout_env(oenv, idx_cfg.project.id);        
    } catch (error) {
        console.error(error.message, error.stack);
    }
}

function makeout_dev2env(oproj, proj_id) {
    try {
        let oenv = _project_devenv(oproj);
        return _makeout_env(oenv, proj_id);
    } catch (error) {
        console.error(error.message, error.stack);
    }
}

function _load_etl_vars(run, proj_apath) {
    let vars
    if(typeof run.vars === 'object') {
        if(Array.isArray(run.vars)) {
            let vs = [];
            for(let f of run.vars) {
                vs = vs.concat(yaml.safeLoad(fs.readFileSync(f, 'utf8')));
            }
            vars = vs;
        } else {
            vars = run.vars;
        }
    } else if(typeof run.vars === 'string'){
        let f = path.resolve(proj_apath, run.vars) 
        vars = yaml.safeLoad(fs.readFileSync(f, 'utf8'));
    } else {
        if(run.vars !== undefined) {
            console.log('type of vars is ', typeof run.vars);
        }
    }
    return vars;
}

function makeout_etl2run(proj_id, proj_path, run) {
    if (!run.src) {
        throw new Error(`未设置src属性`);
    }
    let src_path = path.resolve(proj_path, run.src);
    if (!fs.existsSync(src_path)) {
        throw new Error(`文件"${src_path}"未找到`);
    }
    if (!src_path.endsWith('.lua')) {
        throw new Error('无效脚本文件');
    }

    let proj_apath = path.isAbsolute(proj_path) ? proj_path : path.resolve(proj_path);
    let src_apath = path.isAbsolute(src_path) ? src_path : path.resolve(proj_apath, src_path);
    let src_rpath = path.relative(proj_apath, src_apath);
    src_rpath = src_rpath.replace('\\', '/');
  
    if(src_rpath.startsWith('.')) {
      throw new Error(`无法解析文件"${src_path}"`);
    }
  
    let code = fs.readFileSync(src_apath, "utf8");
    let option = run.option || {};
    if (run.topology) {
        option.topology = run.topology;
    }    

    return {
        proj_id,
        script: code,
        rpath_src: src_rpath,
        vars: _load_etl_vars(run, proj_apath),
        option,
    }
  }


module.exports = {
    makeout_etl2env,
    makeout_dev2env,
    makeout_etl2run,
};