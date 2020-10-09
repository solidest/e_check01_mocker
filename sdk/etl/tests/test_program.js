const path = require('path');
const fs = require('fs');
const yaml = require('js-yaml');
const { assert } = require('console');
const program = require('../program');
const helper = require('../helper');

function test_program(idx_obj, out_apath) {
    let db_tree = program.program_tree_etl2dev(idx_obj);
    let db_runs = program.program_runs_etl2dev(idx_obj, db_tree);
    let etl_runs = program.program_runs_dev2etl(db_runs);

    let tree_db = path.resolve(out_apath, 'tree_db.json');
    let runs_db = path.resolve(out_apath, 'runs_db.json');
    let runs_etl = path.resolve(out_apath, 'runs.yaml');
    fs.writeFileSync(tree_db, JSON.stringify(db_tree, null, 4));
    fs.writeFileSync(runs_db, JSON.stringify(db_runs, null, 4));
    fs.writeFileSync(runs_etl, yaml.safeDump(etl_runs));

    assert(db_tree && db_runs && etl_runs);

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

test_program(idx_obj, out_apath1);

console.log('test passed')

