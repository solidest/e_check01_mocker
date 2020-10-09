/**
 * 执行输出信息解析模块
 */

const print = require('./print');
const reply_ask = require('./reply_ask');

//读取执行输出 返回是否应该退出的布尔值
function parse_out(res, auto_reply) {
    if (!res) {
        return;
    }

    for (let r of res) {
        if (r.catalog === 'system') {
            let msg = r.value.message;
            switch (r.kind) {
                case 'start':
                    print.sys_recved(' ', '::start:: ' + msg);
                    break;

                case 'entry':
                    print.sys_recved(' ', '::entry:: ' + msg);
                    console.log('')
                    break;

                case 'exit':
                    console.log('')
                    print.sys_recved(' ', '::exit:: ' + msg);
                    break;

                case 'stop': {
                    print.sys_recved(' ', `::stop:: ${msg} (${Math.round(r.time/1000000000)}s)\n`)
                    return true;
                }

                case 'print': {
                    print.usr_print(msg);
                    break;
                }

                case 'verifyFail':
                    print.sys_error(`${msg} (${r.value.src}:${r.value.line})`, ' ');
                    break;

                case 'assertFail':
                    print.sys_error(`${msg} (${r.value.src}:${r.value.line})`, ' ');
                    return true;
                    
                case 'error': {
                    //console.log('xxxxxxxxxxxxxxxxx')
                    print.sys_error(msg, ' ');
                    break;
                }

                default:
                    print.sys_recved('?', JSON.stringify(r));
                    break;
            }
        } else if (r.catalog === 'log') {
            print.usr_log(r.kind, r.value);
        } else if (r.catalog === 'ask') {
            reply_ask(r, auto_reply);
        } else {
            if(r.catalog!=="record") {
                print.sys_recved('?', r);
            }
        }
    }

    return false;

}

module.exports = parse_out;