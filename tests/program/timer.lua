local helper = require 'helper'
local test = {
    -- 处理超时定时器
    
    timer1 = function ()
        local list = {}
        local timer_id = nil
        for i = 1, 500 do
            local mod = math.fmod(i, 2)
            if mod > 0 then
                local test_out = function (data)
                end
                timer_id = async.timeout(1000,test_out)
                table.insert(list, timer_id)
            end
        end
        for i in pairs(list) do
           async.clear(i)
        end 
    end,
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