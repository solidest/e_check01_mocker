
/**
 * 命令操作模块
 */

const yaml = require('js-yaml');
const fs = require('fs');
const logdb = require('./logdb');
const SdkApi = require('../driver/SdkApi');
const print = require('./print');
const parse_out = require('./parse_out');

let _sdk = null;
let _run_uuid = null;
let _run_id = null;
let _timer = null;
let _timer_exit1 = null;
let _timer_exit2 = null;
let _exit_duration = 0
let _runs = null;
let _cfg = null;

//退出执行
function _exit() {
    if (_timer) {
        clearInterval(_timer);
        _timer = null;
    }
    _clear_exit_timers();
    logdb.close();
    if(_runs) {
        setTimeout(() => {
            _run_next();
        }, 800);
    } else {
        setTimeout(()=>{
            process.exit(0);
        }, 500);        
    }
}

//执行下一个用例
function _run_next() {
    logdb.close();
    let r = _runs.shift();
    if(_runs.length == 0) {
        _runs = null;
    }
    cmd_run(null, r);
}

//命令执行回调
function _callback(err, res, id) {
    if (err) {
        return print.sys_error(err.message ? err.message : err, id);
    }
    return print.sys_recved(id, res);
}

//读取执行输出
function _read_out() {
    if (!_run_uuid) {
        return;
    }

    _sdk.readoutSync(_run_uuid, (err, res, id) => {
        if (err) {
            print.sys_error(id, err);
            _exit();
            return;
        }
        logdb.save(_run_id, res);
        if(parse_out(res, _exit_duration>0)) {
            _exit();
            return;
        }
    });
}

//确认已连接服务器
function _initial(idxfile) {
    if(!_cfg) {
        _cfg = yaml.safeLoad(fs.readFileSync(idxfile, 'utf8'))
    }
    if(!_sdk) {
        _sdk = new SdkApi(_cfg.project.etestd_ip, _cfg.project.etestd_port);        
    }
}

function _clear_exit_timers() {
    if(_timer_exit1){
        clearTimeout(_timer_exit1);
        _timer_exit1 = null;
    }
    if(_timer_exit2){
        clearTimeout(_timer_exit2);
        _timer_exit2 = null;
    }
}

//查询下位机状态
function cmd_state(idxfile) {
    _initial(idxfile);
    let id = _sdk.stateSync((err, res, id) => {
        _callback(err, res, id);
        process.exit(0);
    });
    print.sys_sended(id, 'state');
}

//停止下位机执行
function cmd_stop(idxfile) {
    _initial(idxfile);
    let cid = _sdk.stateSync((err, res, id) => {
        _callback(err, res, id);
        if (res && res != 'idle') {
            _sdk.stopSync(res, (err, res, id) => {
                _callback(err, res, id);
                _exit();
            });
            print.sys_sended(id, 'stop');
        } else {
            _exit();
        }
    });
    print.sys_sended(cid, 'state');
}

//安装执行环境
function cmd_setup(idxfile) {
    _initial(idxfile);
    let id = _sdk.setupSync(_cfg, (err, res, id)=>{
        _callback(err, res, id);
        _exit();
    });
    print.sys_sended(id, 'setup');
}

//执行实例
function cmd_run(idxfile, runid) {
    _clear_exit_timers();
    if(_exit_duration>0) {
        _timer_exit1 = setTimeout(() => {
            _timer_exit1 = null;
            cmd_stop(idxfile);
            _timer_exit2 = setTimeout(() => {
                _timer_exit2 = null;
                _exit();
            }, 2000);
        }, _exit_duration*1000);
    }

    _initial(idxfile);
    _run_uuid = null;
    _run_id = runid;
    let id = _sdk.startSync(_cfg, runid, (err, res, id)=>{
        _callback(err, res, id);
        if (res) {
            _run_uuid = res;
        }
    });
    
    print.sys_sended(id || ' ', 'run ' + runid);
    _timer = setInterval(_read_out, 40);
}


//执行多个实例
function cmd_runs(idxfile, runsid) {
    _initial(idxfile);
    if(Array.isArray(runsid)) {
        _runs = runsid;
    } else {
        _runs = _cfg.runs[runsid];
    }
    _run_next();
}

//回复信息
function do_reply(answer) {
    _sdk.replySync(_run_uuid, answer, _callback);
}

//发送命令
function cmd_cmd(idxfile, cmd_id, params) {
    _initial(idxfile);
    if(!_run_uuid) {
        _sdk.stateSync((err, res, id) => {
            if (res && res != 'idle') {
                _run_uuid = res;
                let sid = _sdk.cmdSync(_run_uuid, cmd_id, params, _callback);
                print.sys_sended(sid || ' ', 'cmd ' + cmd_id);
            } else {
                print.sys_error(err || 'ETestX已经停止运行', id);
            }
        });
    } else {
        let sid = _sdk.cmdSync(_run_uuid, cmd_id, params, _callback);
        print.sys_sended(sid || ' ', 'cmd ' + cmd_id);
    }
    setTimeout(() => {
        _exit();
    }, 300);
}

//设置自动退出
function set_auto_exit(duration) {
    _exit_duration = duration;
}

function cmd_ping(idxfile) {
    _initial(idxfile);
    let id = _sdk.pingSync((err, res, id) => {
        _callback(err, res, id);
        process.exit(0);
    });
    print.sys_sended(id, 'ping');
}

module.exports = {
    cmd_ping, cmd_state, cmd_stop, cmd_setup, cmd_run, cmd_runs, cmd_cmd, do_reply, set_auto_exit
}
