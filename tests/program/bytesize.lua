local helper = require 'helper'
local test = {
    

    test_ByteSize1 = function ()
        local msg = {}
        msg.seg_1 = 0
        msg.seg_2 = "$%@#!~\0"
        msg.seg_3 = 0
        local buf = pack(protocol.prot30,msg)
        local data = unpack(protocol.prot30, buf)
        assert(msg.seg_3 == data.seg_1)
        assert(2 == data.seg_4)
    end,
    test_ByteSize2 = function ()
        local msg = {}
        msg.seg_1 = 12
        msg.seg_2 = "1234%dgjJLLL\0"
        msg.seg_3 = 112
        local buf = pack(protocol.prot30,msg)
        local data = unpack(protocol.prot30, buf)
        assert(2 == data.seg_4)
    end,
    test_ByteSize3 = function ()
        local msg = {}
        msg.seg_1 = -34
        msg.seg_2 = "FFFF\0"
        msg.seg_3 = -987
        local buf = pack(protocol.prot30,msg)
        local data = unpack(protocol.prot30, buf)
        assert(2 == data.seg_4)
    end,
    test_ByteSize4 = function ()
        local msg = {}
        msg.seg_1 = -34
        msg.seg_2 = 9223372036854775807
        msg.seg_3 = -987
        local buf = pack(protocol.prot31,msg)
        local data = unpack(protocol.prot31, buf)
        assert(4 == data.seg_4)
        assert(4 == data.seg_5)
        assert(4+4 == data.seg_6)
        assert(data.seg_4 + data.seg_5 == data.seg_6)
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