local helper = require 'helper'
local test = {
    -- 记录普通日志信息输出结果为绿色
    test_info = function ()
        local msg = "记录普通日志信息输出结果为绿色"
        log.info(msg)
    end,
    -- 记录警告日志信息输出结果为黄色
    test_warn = function ()
        local msg = '记录警告日志信息输出结果为黄色'
        log.warn(msg)
    end,
    -- 记录错误的日志信息输出结果为红色
    test_error = function ()
        local msg = "记录错误的日志信息输出结果为红色"
        log.error(msg)
    end,
    -- 记录测试步骤信息
    test_step = function ()
        local msg = "测试步骤"
        log.step(msg)
    end,
    -- 记录测试动作执行记录
    test_action = function ()
        local msg = "记录测试动作执行记录"
        log.action(msg)
    end,
    -- 输出正在执行的测试信息
    test_doing = function ()
        local msg = "输出正在执行的测试信息"
        log.action(msg)
    end,
    -- 输出检查结果的日志，第一个参数是字符串，第二个为布尔值
    test_check = function ()
        local msg = '检查结果日志'
        log.check(msg,true)
        
    end
}
function entry(vars)
    local filter = "t"
    for k, t in pairs(test) do
        if string.sub(k, 1, 1) == filter then
            local t1 = now()
            local ok, res = pcall(t, vars)
            local t2 = now()
            if ok then
                log.info('【' .. k .. '】测试通过(' .. (t2-t1) .. 'ms)')
            else
                record.test_case = k
                record.test_result = res
                log.error('【' .. k .. '】测试失败, ' .. helper.trim_error_info(res))
            end
        end
    end
    exit()
end