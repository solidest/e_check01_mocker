const path = require('path');
const fs = require('fs');
const shortid = require('shortid');
const { assert } = require('console');

const helper = require('../helper');
const etl_dev = require('../index');

function test_etl_dev(proj_apath, out_apath, etl_outs) {
    let asts = helper.parse_proj_etl(proj_apath);
    let proj_id = shortid.generate();

    asts.forEach(ast => {
        let ast_json = path.resolve(out_apath, ast.name + '_ast.json');
        let db_json = path.resolve(out_apath, ast.name + '_db.json');
        let out_etl = path.resolve(out_apath, ast.name + '.etl');
        fs.writeFileSync(ast_json, JSON.stringify(ast, null, 4));
        if (ast.kind === 'protocol') {
            let obj = etl_dev.protocol_etl2dev(ast, proj_id, shortid.generate(), 'memo text');
            fs.writeFileSync(db_json, JSON.stringify(obj, null, 4));
            let db_ctx = require(db_json);
            db_ctx.content.memo = '说明文本';
            let code = etl_dev.protocol_dev2etl(db_ctx, ast.name);
            fs.writeFileSync(out_etl, code);
            etl_outs.push({name: ast.name, file: out_etl});
        }
    });

    let devs = [];

    asts.forEach(ast => {
        let ast_json = path.resolve(out_apath, ast.name + '_ast.json');
        let db_json = path.resolve(out_apath, ast.name + '_db.json');
        let out_etl = path.resolve(out_apath, ast.name + '.etl');
        fs.writeFileSync(ast_json, JSON.stringify(ast, null, 4));
        if (ast.kind === 'device') {
            let obj = etl_dev.device_etl2dev(ast, proj_id, shortid.generate(), 'memo text');
            devs.push({name: ast.name, ctx: obj});
            fs.writeFileSync(db_json, JSON.stringify(obj, null, 4));
            let db_ctx = require(db_json);
            db_ctx.content.memo = '说明文本';
            let code = etl_dev.device_dev2etl(db_ctx, ast.name);
            fs.writeFileSync(out_etl, code);
            etl_outs.push({name: ast.name, file: out_etl});
        }
    });

    asts.forEach(ast => {
        let ast_json = path.resolve(out_apath, ast.name + '_ast.json');
        let db_json = path.resolve(out_apath, ast.name + '_db.json');
        let out_etl = path.resolve(out_apath, ast.name + '.etl');
        fs.writeFileSync(ast_json, JSON.stringify(ast, null, 4));
        if (ast.kind === 'topology') {
            let obj = etl_dev.topology_etl2dev(ast, proj_id, shortid.generate(), 'memo text', devs);
            fs.writeFileSync(db_json, JSON.stringify(obj, null, 4));
            let db_ctx = require(db_json);
            db_ctx.content.memo = '说明文本';
            let code = etl_dev.topology_dev2etl(db_ctx, ast.name, devs);
            fs.writeFileSync(out_etl, code);
            etl_outs.push({name: ast.name, file: out_etl});
        }
    });
}

function test_result(outs1, outs2) {
    assert(outs1.length == outs2.length, outs1.length + ':' + outs2.length);
    for(let info1 of outs1) {
        let info2 = outs2.find(it => it.name === info1.name);
        let code1 = fs.readFileSync(info1.file, 'utf8');
        let code2 = fs.readFileSync(info2.file, 'utf8');
        assert(code1 === code2, info1.name);
    }
    console.log('test passed') 
}

function deleteFolderRecursive(url) {
    var files = [];
    if (fs.existsSync(url)) {
        files = fs.readdirSync(url);
        files.forEach(function (file) {
            var curPath = path.join(url, file);
            if (fs.statSync(curPath).isDirectory()) { // recurse
                deleteFolderRecursive(curPath);
            } else {
                fs.unlinkSync(curPath);
            }
        });
        fs.rmdirSync(url);
    } else {
        console.log("给定的路径不存在，请给出正确的路径");
    }
}

const demo_apath = path.resolve('./demo/');
const out_apath1 = path.resolve('./demo_out1/');
const out_apath2 = path.resolve('./demo_out2/');
deleteFolderRecursive(out_apath1);
deleteFolderRecursive(out_apath2);
fs.mkdirSync(out_apath1)
fs.mkdirSync(out_apath2)

let etl_outs1 = [];
let etl_outs2 = [];
test_etl_dev(demo_apath, out_apath1, etl_outs1);
test_etl_dev(out_apath1, out_apath2, etl_outs2);
test_result(etl_outs1, etl_outs2);






