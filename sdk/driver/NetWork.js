const net = require('net');
const Frame = require('./Frame');

class NetWork {

    on(event, callback) {
        if (event === 'recv') {
            this.on_recv = callback;
        } else if (event === 'error') {
            this.on_error = callback;
        }
    }

    is_open() {
        return !!this._socket;
    }

    
    close(reason) {
        if(reason) {
            // console.log('net closed, reason:', reason)
        }
        this.on_error = null;
        this.on_recv = null;
        if(this._timer) {
            clearTimeout(this._timer);
            this._timer = null;
        }
        if (this._socket) {
            this._socket.removeAllListeners('close');
            this._socket.removeAllListeners('error');
            this._socket.removeAllListeners('end');
            this._socket.removeAllListeners('timeout');
            this._socket.removeAllListeners('data');
            this._socket.destroy();
            this._socket = null;
        }
    }

    open(ip, port) {
        if(ip && port) {
            this._ip = ip;
            this._port = port;            
        }
        if(!this._ip || !this._port) {
            throw new Error('未设置网络连接');
        }
        this._frm = new Frame();

        this._timer = setTimeout(() => {
            self._timer = null;
            self.close('timeout1');
            return {
                result: 'error',
                value: '连接执行器失败',
            }
        }, 600);

        let self = this;
        return new Promise(resolve => {
            try {
                self._socket = net.connect(this._port, this._ip, ()=> {
                    clearTimeout(self._timer);
                    self._timer = null;
                    self._socket.on('data', function (data) {
                        let body = self._frm.unpack(data);
                        while (body) {
                            self.on_recv(body);
                            body = self._frm.unpack(null);
                        }
                    });
                    return resolve({
                        result: 'ok'
                    });
                });
                self._socket.setKeepAlive(true, 1);

                self._socket.on('close', function () {
                    let is_conning = !!self._timer;
                    self.close('close');
                    if(is_conning) {
                        return (resolve({
                            result: 'error',
                            value: '连接被关闭',
                        }));
                    }
                });

                self._socket.on('error', function (err) {
                    let is_conning = !!self._timer;
                    self.close('error:' + err.message);
                    if(is_conning) {
                        return (resolve({
                            result: 'error',
                            value: err.message,
                        }));                        
                    } else if(self.on_error) {
                        self.on_error(err.message);
                    }
                });

                self._socket.on('end', function () {
                    self.close('end');
                    if (self.on_error) {
                        return self.on_error('与执行器的连接已断开');
                    }
                });

                self._socket.on('timeout', function () {
                    self.close('timeout2');
                    if (self.on_error) {
                        return self.on_error('连接执行器超时');
                    }
                });

            } catch (error) {
                console.error('net error', error.message);
            }
        });
    }


    send(body) {
        if (!this._socket) {
            if(this.on_error) {
                this.on_error('未连接执行器');
            } else {
                console.error('_socket is null');
            }
        }
        this._socket.write(Frame.pack(body));
    }
}

module.exports = NetWork;