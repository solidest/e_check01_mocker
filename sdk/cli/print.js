/**
 * 命令行输出模块
 * 负责在命令行输出信息
 * 约定: ETL发送给UI的信息 <-
 * 约定: ETL发送给ETestD的信息 ->
 * 约定: 系统信息灰色文字
 * 约定: 普通信息白色文字 
 * 约定: 警告信息黄色文字
 * 约定: 错误信息红色文字
 */


//SYSTEM ETL -> ETestD
function sys_sended(id, info) {
    console.log('\x1B[90m%s\x1B[39m', id + " -> " + info);
}

//SYSTEM UI <- ETL
function sys_recved(id, info) {
    console.log('\x1B[90m%s\x1B[39m', id + " <- " + info);
}

//SYSTEM::WARN UI <- ETL
function sys_warn(info) {
    console.log('\x1B[33m%s\x1B[39m', '  <- ' + info);
}

//SYSTEM::ERROR UI <- ETL
function sys_error(info, id) {
    console.error('\x1B[31m%s\x1B[39m', (id ? id : ' ') + ' <- ' + info);
}

//USER::PRINT UI <- ETL
function usr_print(info) {
    console.log('  <- ' + info);
}

//USER::LOG UI <- ETL
function usr_log(type, info) {
    // let info = JSON.parse(inlog);
    let fmt = '';
    switch (type) {
        case "info":
            fmt = '\x1B[30;42m INFO \x1B[32;49m%s\x1B[0m ';
            break;
        case "error":
            fmt = '\x1B[30;41m ERROR \x1B[31;49m%s\x1B[0m ';
            break;
        case "warn":
            fmt = '\x1B[30;43m WARNING \x1B[33;49m%s\x1B[0m ';
            break;
        case "check": {
            if(info.result) {
                fmt = '\x1B[30;42m CHECK \x1B[32;49m%s\x1B[0m ';
            } else {
                fmt = '\x1B[30;41m CHECK \x1B[31;49m%s\x1B[0m ';
            }
            break;
        }
        case "doing": 
            fmt = '\x1B[30;42m DOING \x1B[32;49m%s\x1B[0m ';
            break;
        default:
            fmt = `\x1B[44;30m ${type.toLocaleUpperCase()} \x1B[34;49m%s\x1B[0m`
            break;
    }
    console.log(fmt, ' ' + info.message);
}


module.exports = {
    sys_error, sys_sended, sys_recved, sys_warn,
    usr_log, usr_print
}