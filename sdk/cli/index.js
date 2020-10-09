#!/usr/bin/env node

/**
 * ETL命令行执行入口模块
 */

const fs = require('fs');
const yaml = require('js-yaml');
const { program } = require('commander');
const pkg = require('../../package.json');

program.version(pkg.version, '-v, --version', 'output the current version');

function _get_idxfile() {
    let idxfile = program.idxfile;
    if(!idxfile) {
        return 'index.yml';
    } 
    return idxfile;
}

function _get_params() {
    let params = program.params;
    if(!params) {
        return null;
    }
    return yaml.safeLoad(fs.readFileSync(params, 'utf8'));
}

program
    .option('-i, --idxfile <idxfile>', 'specify index file')
    .option('-t, --times <times>', 'repeat the specified number of times')
    .option('-p, --params <params>', 'params of command')
    .option('-a, --duration <duration>', 'auto run test program, no more than duration seconds ');

program
    .command('state')
    .description('query status of etestd')
    .action(()=>{
        const cmd = require('./command');
        cmd.cmd_state(_get_idxfile());
    });

program
    .command('stop')
    .description('stop run on etestd')
    .action(()=>{
        const cmd = require('./command');
        cmd.cmd_stop(_get_idxfile());
    });

program
    .command('setup')
    .description('setup environment into etestd')
    .action(()=>{
        const cmd = require('./command');
        cmd.cmd_setup(_get_idxfile());
    });

program
    .command('run <run_id>')
    .description('run special case on etestd')
    .action((run_id)=>{
        const cmd = require('./command');
        if (program.duration && program.duration>0) {
            cmd.set_auto_exit(program.duration);
        }
        let ts = program.times;
        if(ts && ts >0) {
            let runs = [];
            for (let index = 0; index < ts; index++) {
                runs.push(run_id);
            }
            cmd.cmd_runs(_get_idxfile(), runs);
        } else {
            cmd.cmd_run(_get_idxfile(), run_id);
        }
    });

program
    .command('runs <runs_id>')
    .description('run multi case on etestd')
    .action((runs_id)=>{
        const cmd = require('./command');
        if (program.duration && program.duration>0) {
            cmd.set_auto_exit(program.duration)
        }
        cmd.cmd_runs(_get_idxfile(), runs_id);
    });

program
    .command('cmd <cmd_id>')
    .description('send special command to etestd')
    .action((cmd_id)=>{
        const cmd = require('./command');
        cmd.cmd_cmd(_get_idxfile(), cmd_id, _get_params());
    });

program
    .command('ping')
    .description('send ping cmmand to etestd')
    .action(async ()=>{
        const cmd = require('./command');
        await cmd.cmd_ping(_get_idxfile());
    });

program.parse(process.argv);




