
const loki = require('lokijs');
const fs = require('fs');

let _db = null;


//初始化数据库
function _databaseInitialize(run_id) {
    let dbf = 'logdb/' + run_id + '.json';
    if(fs.existsSync(dbf)) {
        fs.unlinkSync(dbf);
    }
    _db = new loki(dbf, {
        autoload: true,
        autosave: true, 
        autosaveInterval: 4000
    });

    _db.addCollection("output", {
        unique: ['time']
    });
    _db.addCollection("record", {
        unique: ['$time']
    });
}

//输出记录到数据库
function save(run_id, data) {
    if(!_db) {
        _databaseInitialize(run_id);
    }
    let coll = _db.getCollection("output");
    let rcd = _db.getCollection("record");
    for(let r of data) {
        if(r.catalog === 'record' && r.value) {
            let rv = r.value;
            rv['$time'] = r.time;
            rcd.insert(rv);
            delete r.value;
        }
        coll.insert(r);
    }
}

//关闭之前保存数据
function close() {
    if(!_db) {
        return;
    }
    _db.saveDatabase();
    _db = null;
}

module.exports = {
    save, close
}