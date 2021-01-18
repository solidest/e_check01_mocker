
local helper = require 'helper'

local test = {

    timer_timeout = function ()
        local t1 = now()
        local _fn_out = nil
        local count = 0
        local fn_out = function (aaa, bbb, contiue, ddd)
            count = count + 1
            assert(aaa == 1)
            assert(bbb == 'a')
            assert(ddd == nil)
            local t2 = now()
            assert(t2 - t1 >= 999 and t2 - t1 < 1050, t1 .. '-' .. t2)
            t1 = now()
            if contiue then
                async.timeout(1000, _fn_out, aaa, bbb, false)
            end
        end
        _fn_out = fn_out
        async.timeout(1000, fn_out, 1, 'a', true)
        delay(2100)
        assert(count == 2)
    end,

    timer_interval = function ()
        local t1 = now()
        local count = 1
        local fn_tick = function (aaa, bbb, ccc)
            local t2 = now()
            count  = count + 1
            assert(aaa == 1)
            assert(bbb == 'a')
            assert(ccc == nil)
            assert(t2 - t1 > 90 and t2 - t1 < 150)
            t1 = now()
        end
        async.interval(100, 100, fn_tick, 1, 'a')
        delay(1000)
        assert(count == 10, '' .. count)
    end
}


function entry(vars)
    DEBUG = false
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
