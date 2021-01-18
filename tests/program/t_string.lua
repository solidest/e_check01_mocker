
local helper = require 'helper'

local test = {

    str_err = function ()
        local err_arr2buff = function (t)
            return string.arr2buff(t)
        end

        local err_hex2buff = function (t)
            return string.hex2buff(t)
        end

        local err_buff2hex = function (t)
            return string.buff2hex(t)
        end

        local res = true

        local bad = { {},  {'a'}, '', {[7] = 99, [9] = 100}, 1, 0, -9.8 }
        for i, v in ipairs(bad) do
            res = pcall(err_arr2buff, v)
            assert(not res)
            res = pcall(err_hex2buff, v)
            assert(not res)
            res = pcall(err_buff2hex, v)
            assert(not res)
        end

        res = pcall(err_arr2buff, nil)
        assert(not res)
        res = pcall(err_hex2buff, nil)
        assert(not res)
        res = pcall(err_buff2hex, nil)
        assert(not res)

    end,

    str_buf_hex = function ()

        local b1 = string.hex2buff('12 dx')
        assert(b1 ~= nil)
        local b2 = string.hex2buff('aa FF 00e 9ab')
        local b3 = string.hex2buff('aaF F 0 0e9 A B')
        assert(b2 == b3)

        local s1 = string.buff2hex(' ')
        assert(s1 ~= nil)
        local s2 = string.buff2hex(b2)
        local s3 = string.buff2hex(b3)
        assert(s2 == s3 and #s2 == #b2*3-1)

        local lens = { 1, 10, 100, 1024, 65*1024 }
        for idx, value in ipairs(lens) do
            local s1 = helper.create_bufstr(value)
            local s2 = string.buff2hex(string.hex2buff(s1))
            assert(s1 == s2)
        end

    end,

    str_array = function ()
        local ok = {}
        for i = 1, 2050 do
            table.insert( ok, i, i-1)
        end
        local buf1 = string.buff2hex(string.arr2buff(ok))
        local buf2 = helper.create_bufstr(2050)
        assert(buf1 == buf2)
    end
}


function entry(vars)

    local filter = "s"

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
