const path = require('path');
const fs = require('fs');
const yaml = require('js-yaml');
const msgpack = require("msgpack-lite");
const shortid = require('shortid');

const impexp = require('../impexp');
const helper = require('../helper');
const { assert } = require('console');

function test_import_exprot_proj(idx_obj, out_path1, outpath2) {
    let proj = impexp.import_etl(idx_obj, path.resolve('./tests'), shortid.generate());
    assert(proj);

    let doc = {version: 1, name: 'demo_proj', project: proj }

    let jsonf = path.resolve(out_path1, 'dmeo_proj.json');
    fs.writeFileSync(jsonf, JSON.stringify(doc, null, 4));

    let binf = path.resolve(out_path1, 'dmeo_proj.dev');
    fs.writeFileSync(binf, msgpack.encode(doc));

    doc = msgpack.decode(fs.readFileSync(binf));
    assert(doc.version === 1 && doc.name === 'demo_proj');
    impexp.export_etl(outpath2, doc.project);
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



const out_apath1 = path.resolve('./demo_out1');
const out_apath2 = path.resolve('./demo_out2');

deleteFolderRecursive(out_apath1);
deleteFolderRecursive(out_apath2);
fs.mkdirSync(out_apath1)
fs.mkdirSync(out_apath2)

const idx_obj = yaml.safeLoad(helper.read_text('index.yml', './'));
test_import_exprot_proj(idx_obj, out_apath1, out_apath2);

console.log('passed');
