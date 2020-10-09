const path = require('path');
const fs = require('fs');
const parser = require("../parser");

function _set_etl_props(obj, props) {
    if (!props) {
        return;
    }
    props.forEach(prop => {
        obj[prop.name] = exp2str(prop.value, true);
    });
}

function _get_etl_files(pf, results) {
    if (!fs.existsSync(pf)) {
        return;
    }

    let st = fs.statSync(pf);
    if (st.isFile()) {
        if (path.extname(pf) !== '.etl') {
            return;
        }
        results.push(pf);
        return;
    }

    if (st.isDirectory()) {
        let dir = fs.readdirSync(pf);
        for (let p of dir) {
            _get_etl_files(path.join(pf, p), results);
        }
    }
}

function _parse_etl(files, proj_apath) {
    let asts = [];
    for (let f of files) {
        let text = fs.readFileSync(f, "utf8");
        let ast = parser.parseEtl(text);
        if (ast) {
            for (let a of ast) {
                a.src = path.relative(proj_apath, f);
            }
            asts = asts.concat(ast);
        }
    }
    return asts;
}

function read_text(file, proj_apath) {
    let f = path.resolve(proj_apath, file);
    if (fs.existsSync(f)) {
        return fs.readFileSync(f, 'utf8');
    }
    throw new Error(`文件 ${f} 未找到`);
}

function is_array(o) {
    return Object.prototype.toString.call(o) == '[object Array]';
}

function parse_proj_etl(proj_apath) {
    let files = [];
    _get_etl_files(proj_apath, files);
    return _parse_etl(files, proj_apath);
}

function exp2str(exp, is_top, need_str_quot) {
    if (!exp) {
        return '';
    }
    switch (exp.kind) {
        case 'bool':
        case 'number':
            return exp.value;
        case 'string': {
            let res = exp.value.replace('\0', '\\0');
            return need_str_quot ? `'${res}'` : res;
        }
        case 'uminus': {
            if (exp.exp && exp.exp.kind === 'number') {
                return -exp.exp.value;
            } else {
                return is_top ? `-${exp2str(exp.exp)}` : `(-${exp2str(exp.exp)})`;
            }
        }
        case 'pid': {
            if (exp.list) {
                return exp.list.join('.');
            } else {
                return '';
            }
        }
        case 'array': {
            let arr = [];
            if (exp.list) {
                exp.list.forEach(it => {
                    arr.push(exp2str(it));
                });
            }
            return arr;
        }
        case 'not':
            return is_top ? `not ${exp2str(exp.exp)}` : `(not ${exp2str(exp.exp)})`;
        case 'eq_eq': {
            return is_top ? `${exp2str(exp.left, false, true)} == ${exp2str(exp.right, false, true)}` : `(${exp2str(exp.left, false, true)} == ${exp2str(exp.right, false, true)})`;
        }
        case 'not_eq': {
            return is_top ? `${exp2str(exp.left, false, true)} ~= ${exp2str(exp.right, false, true)}` : `(${exp2str(exp.left, false, true)} ~= ${exp2str(exp.right, false, true)})`;
        }
        case 'gt': {
            return is_top ? `${exp2str(exp.left)} > ${exp2str(exp.right)}` : `(${exp2str(exp.left)} > ${exp2str(exp.right)})`;
        }
        case 'lt': {
            return is_top ? `${exp2str(exp.left)} < ${exp2str(exp.right)}` : `(${exp2str(exp.left)} < ${exp2str(exp.right)})`;
        }
        case 'gt_eq': {
            return is_top ? `${exp2str(exp.left)} >= ${exp2str(exp.right)}` : `(${exp2str(exp.left)} >= ${exp2str(exp.right)})`;
        }
        case 'lt_eq': {
            return is_top ? `${exp2str(exp.left)} <= ${exp2str(exp.right)}` : `(${exp2str(exp.left)} <= ${exp2str(exp.right)})`;
        }
        case 'add': {
            return is_top ? `${exp2str(exp.left)} + ${exp2str(exp.right)}` : `(${exp2str(exp.left)} + ${exp2str(exp.right)})`;
        }
        case 'subtract': {
            return is_top ? `${exp2str(exp.left)} - ${exp2str(exp.right)}` : `(${exp2str(exp.left)} - ${exp2str(exp.right)})`;
        }
        case 'multiply': {
            return is_top ? `${exp2str(exp.left)} * ${exp2str(exp.right)}` : `(${exp2str(exp.left)} * ${exp2str(exp.right)})`;
        }
        case 'divide': {
            return is_top ? `${exp2str(exp.left)} / ${exp2str(exp.right)}` : `(${exp2str(exp.left)} / ${exp2str(exp.right)})`;
        }
        case 'and': {
            return is_top ? `${exp2str(exp.left)} and ${exp2str(exp.right)}` : `(${exp2str(exp.left)} and ${exp2str(exp.right)})`;
        }
        case 'or': {
            return is_top ? `${exp2str(exp.left)} or ${exp2str(exp.right)}` : `(${exp2str(exp.left)} or ${exp2str(exp.right)})`;
        }
        case 'CheckCode':
        case 'ByteSize': {
            let ps = [];
            exp.params.forEach(p => {
                let v = exp2str(p, true);
                if (is_array(v)) {
                    v = `[${v.join(', ')}]`;
                }
                ps.push(v);
            })
            return (`${exp.kind}(${ps.join(', ')})`)
        }
        default:
            if (is_array(exp)) {
                let o = {};
                _set_etl_props(o, exp);
                return o;
            } else {
                console.error('unknow exp:', exp.kind);
            }
            break;
    }
}

function prop2str(obj, key) {
    let value = obj[key];
    if (value === undefined || value === null || value === '') {
        return undefined;
    }
    return `${key}: '${value}',`;
}

function prop2raw(obj, key) {
    let value = obj[key];
    if (value === undefined || value === null || value === '') {
        return undefined;
    }
    return `${key}: ${value},`;
}

function append_codes_arr(codes, level, arr) {
    if(!arr) {
        return;
    }
    for(let v of arr) {
        let t = typeof v;
        switch (t) {
            case 'string':
                codes.push({level: level, code: `'${v}',`})
                break;
            case 'boolean':
            case 'number':
                codes.push({level: level, code: `${v},`})
                break;
            case 'object':{
                if(is_array(v)) {
                    codes.push({level: level, code: `[`});
                    append_codes_arr(codes, level+1, v);
                    codes.push({level: level, code: '],'});
                } else {
                    append_codes_obj(codes, level, v);
                }
                break;
            }
            default:
                console.error('unkonw type:', t);
                break;
        }
    }
}

function append_codes_objprops(codes, level, obj) {
    if (!obj) {
        return;
    }
    for(let k in obj) {
        let v = obj[k];
        let t = typeof v;
        switch (t) {
            case 'string':
                codes.push({level: level, code: `${k}: '${v}',`})
                break;
            case 'boolean':
            case 'number':
                codes.push({level: level, code: `${k}: ${v},`})
                break;
            case 'object':{
                if(is_array(v)) {
                    codes.push({level: level, code: `${k}: [`});
                    append_codes_arr(codes, level+1, v);
                    codes.push({level: level, code: '],'});
                } else {
                    append_codes_obj(codes, level+1, v, k);
                }
                break;
            }
            default:
                console.error('unkonw type:', t);
                break;
        }
    }
}

function append_codes_obj(codes, level, value, key) {
    if (!value) {
        return;
    }
    codes.push({level: level, code: key ? `${key}: {`: '{'});
    append_codes_objprops(codes, level+1, value);
    codes.push({level: level, code: '},'});
}

module.exports = {
    read_text,
    parse_proj_etl,
    is_array,
    exp2str,
    prop2str,
    prop2raw,
    append_codes_obj,
    append_codes_arr,
    append_codes_objprops,
};