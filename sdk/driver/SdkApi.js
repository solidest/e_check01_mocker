const path = require('path');
const RpcTask = require('./RpcTask');
const NetWork = require('./NetWork');
const ETL = require('../etl');

class SdkApi {
    constructor(ip, port) {
        this._net = new NetWork();
        this._rpc = new RpcTask(this._net);
        if(ip && port) {
            this._ip = ip;
            this._port = port;
            this._net.open(ip, port);
        }
    }

    async open(ip, port) {
        if(ip && port) {
            this._ip = ip;
            this._port = port;
        }
        return await this._net.open(this._ip, this._port);
    }

    on_error(cb) {
        this._net.on('error', cb);
    }



    _xfnSync(method, params, callback) {
        try {
            return this._rpc.sendTask({
                method: method,
                params: params
            }, callback);
        } catch (error) {
            if (callback) {
                callback(error, null);
            }
        }
    }

    setupSync(cfg, callback) {
        try {
            let env = ETL.makeout_etl2env(cfg);
            return this._xfnSync('makeenv', env, callback);
        } catch (error) {
            if (callback) {
                callback(error);
            }
        }
    }

    start_quickSync(cfg, run_id, callback) {
        try {
            let pf = cfg.project.path;
            pf = path.isAbsolute(pf) ? pf : path.resolve(pf);
            let run = cfg.program[run_id];
            if (!run) {
                throw new Error(`实例"${run_id}"未找到`);
            }
            let run_info = ETL.makeout_etl2run(cfg.project.id, pf, run);
            return this._xfnSync('start', run_info, callback);
        } catch (error) {
            if (callback) {
                callback(error);
            }
        }
    }

    startSync(cfg, run_id, callback) {
        return this.setupSync(cfg, (err) => {
            if (err) {
                return callback(err);
            }
            return this.start_quickSync(cfg, run_id, callback);
        });
    }

    readoutSync(run_id, callback) {
        try {
            return this._xfnSync('readout', {
                key: run_id
            }, callback);
        } catch (error) {
            if (callback) {
                callback(error);
            }
        }
    }

    stateSync(callback) {
        try {
            return this._xfnSync('state', null, callback);
        } catch (error) {
            if (callback) {
                callback(error);
            }
        }
    }

    pingSync(callback) {
        try {
            return this._xfnSync('ping', null, callback);
        } catch (error) {
            if (callback) {
                callback(error);
            }
        }
    }

    stopSync(run_id, callback) {
        try {
            return this._xfnSync('stop', {
                key: run_id
            }, callback);
        } catch (error) {
            if (callback) {
                callback(error);
            }
        }
    }

    replySync(run_id, answer, callback) {
        try {
            answer.key = run_id;
            return this._xfnSync('reply', answer, callback);
        } catch (error) {
            if (callback) {
                callback(error);
            }
        }
    }

    cmdSync(run_id, command, params, callback) {
        try {
            return this._xfnSync('command', {
                key: run_id,
                command: command,
                params: params
            }, callback);
        } catch (error) {
            if (callback) {
                callback(error);
            }
        }
    }

}

module.exports = SdkApi;