const {
    Confirm,
    Input,
    NumberPrompt,
    Select,
    MultiSelect,
    prompt
} = require('enquirer');

function _ok_then(info) {
    let msg = (info.title || '') + " : " + (info.msg || '');
    prompt({
        type: 'input',
        name: 'ok',
        message: msg
    }).then(() => {
        const cmd = require('./command');
        cmd.do_reply({
            result: 'ok'
        });
    });
}

function _confirm(info) {
    let msg = (info.title || '') + " : " + (info.msg || '');
    const prompt = new Confirm({
        name: 'question',
        message: msg,
        initial: info.default
    });

    prompt.run()
        .then(answer => {
            const cmd = require('./command');
            cmd.do_reply({
                result: answer
            });
        })
        .catch(console.error);
}

function _input_text(info) {
    let msg = (info.title || '') + " : " + (info.msg || '');
    const prompt = new Input({
        message: msg,
        initial: info.default||'',
    });

    prompt.run()
        .then(answer => {
            const cmd = require('./command');
            cmd.do_reply({
                result: answer
            });
        })
        .catch(console.error);
}


function _input_number(info) {
    let msg = (info.title || '') + " : " + (info.msg || '');
    const prompt = new NumberPrompt({
        name: 'number',
        message: msg,
        initial: info.default
      });

    prompt.run()
        .then(answer => {
            const cmd = require('./command');
            cmd.do_reply({
                result: answer
            });
        })
        .catch(console.error);
}

function _choice(info) {
    let msg = (info.title || '') + " : " + (info.msg || '');
    const prompt = new Select({
        name: 'value',
        message: msg,
        choices: info.items
    });

    prompt.run()
        .then(answer => {
            const cmd = require('./command');
            cmd.do_reply({
                result: answer
            });
        })
        .catch(console.error);
}

function _multiswitch(info) {
    let msg = (info.title || '') + " : " + (info.msg || '');
    let selected = [];
    let diabled = 0;
    for(let i of info.items) {
        if(i.readonly) {
            i.disabled = true;
            i.name = i.name + (i.on ? "(打开)":"(关闭)");
            diabled += 1;
        } else {
            if(i.on) {
                selected.push(i.name);
            }
        }
    }

    if(diabled == info.items.length) {  //自动添加一个可以被选中的项
        info.items.push({name: '确定', value: 'ok'})
    }

    const prompt = new MultiSelect({
        message: msg,
        choices: info.items,
        initial: selected,
        result(names) {
            let res = [];
            for(let n of names) {
                res.push(info.items.find(it=>it.name===n).value);
            }
            return res;
        },
    });
    prompt.selected = info.items
    prompt.run()
        .then(answer => {
            const cmd = require('./command');
            cmd.do_reply({
                result: answer
            });
        })
        .catch(console.error);
}

function _auto_reply(kind, info) {
    let res = true
    switch (kind) {
        case 'ok':
            res = 'ok';
            break;
        case 'yesno':
            res = true;
            break;
        case 'text':
            res = info.defaul;
            break;
        case 'number':
            res = info.default;
            break;
        case 'select':
            res = (info.items && info.items.length>0) ? info.items[0] : null;
            break;
        case 'multiswitch':
            {
                res = [];
                for(let i of info.items) {
                    if(i.on) {
                        res.push(i.value)
                    }
                }
            }
            break;
    }
    const cmd = require('./command');
    cmd.do_reply({
        result: res
    });
}

//回复问讯
function reply_ask(ask, auto_reply) {
    
    let info = ask.value;
    if(auto_reply) {
        return _auto_reply(ask.kind, info);
    }
    switch (ask.kind) {
        case 'ok':
            _ok_then(info);
            break;
        case 'yesno':
            _confirm(info);
            break;
        case 'text':
            _input_text(info);
            break;
        case 'number':
            _input_number(info);
            break;
        case 'select':
            _choice(info);
            break;
        case 'multiswitch':
            _multiswitch(info);
            break;

        default:
            console.error('ask error: ', JSON.stringify(ask));
            break;
    }


}

module.exports = reply_ask;