
const msgpack = require("msgpack-lite");
const magic = 0x7777;

class Frame {
    constructor () {
        this._bufs = [];
    }

    static pack(body) {
        let buf_body = msgpack.encode(body);
        let buf_magic = Buffer.alloc(4);
        buf_magic.writeInt32LE(magic);
        let buf_len = Buffer.alloc(4);
        buf_len.writeInt32LE(buf_body.length);
        return Buffer.concat([buf_magic, buf_len, buf_body]);
    }

    unpack(buf) {
        if(buf) {
            this._bufs.push(buf);
        }
        let count = this._bufs.length;
        if(count===0) {
            return null;
        }

        let first = this._bufs[0];
        if(first.length<8) {
            if(count===1) {
                return null;
            }
            first = Buffer.concat(this._bufs);
            this._bufs = [first];
            if(first.length<8) {
                return null;
            }
        }
        if(first.readInt16LE(2)!==magic) {
            throw new Error('json rpc error');
        }
        let body_len = first.readInt32LE(4);
        return this._unpack(body_len + 8);
    }

    _unpack(data_len) {

        let buf_len = 0;
        let idx = 0;

        for(let buf of this._bufs) {
            buf_len += buf.length;
            if(buf_len >= data_len) {
                break;
            }
            idx++;
        }

        //长度不足
        if(buf_len < data_len) {
            return null;
        }

        let buf = null;
        if(idx===0) {
            buf = this._bufs[0];
        } else {
            buf = Buffer.concat(this._bufs, data_len);
        }

        //去掉解析过的buffer
        if(buf_len === data_len) {
            this._bufs.splice(0, idx+1);
        } else {
            let first = this._bufs[idx];
            let bufs = [first.subarray(first.length-(buf_len-data_len))];
            let _blen = this._bufs.length;
            if(_blen > idx+1) {
                for(let i=idx+1; i<_blen; i++) {
                    bufs.push(this._bufs[i]);
                }
            }
            this._bufs = bufs;
        }
        return msgpack.decode(buf.subarray(8, 8+data_len));
    }

}

module.exports = Frame;
