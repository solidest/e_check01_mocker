const path = require('path');
const fs = require('fs');
const yaml = require('js-yaml');
const { assert } = require('console');
const makeout = require('../makeout');
const helper = require('../helper');

function test_make_env(idx_obj) {
    let env1 = makeout.makeout_etl2env(idx_obj);
    assert(env1);
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

const out_apath1 = path.resolve('./demo_out1/');
const out_apath2 = path.resolve('./demo_out2/');
deleteFolderRecursive(out_apath1);
deleteFolderRecursive(out_apath2);
fs.mkdirSync(out_apath1)
fs.mkdirSync(out_apath2)
const idx_obj = yaml.safeLoad(helper.read_text('index.yml', './'));

test_make_env(idx_obj);
console.log('test passed')

