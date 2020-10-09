
class RpcTask {
    constructor(net) {
        let self = this;
        net.on('recv', (recv_info) => {
            self.recvedTask(recv_info);
        });
        this._tasks = [];
        this._nextid = 0;
        this._net = net;
    }

    sendTask(task_info, call_back) {
        task_info.id = ++this._nextid;
        this._tasks.push({info: task_info, cb: call_back});
        this._net.send(task_info);
        return task_info.id;
    }

    recvedTask(recv_info) {
        let id = recv_info.id;
        let idx = this._tasks.findIndex(it => it.info.id===id);
        if(idx<0) {
            throw new Error('bad info:', JSON.stringify(recv_info));
        }
        let cb = this._tasks[idx].cb;
        this._tasks.splice(idx, 1);
        if(cb) {
            if(recv_info.error) {
                cb(recv_info.error, null, id);
            } else {
                cb(null, recv_info.result, id);
            }
        }
    }
}

module.exports = RpcTask;
