local helper = require 'helper'
local test = {
    test_checkcode = function ()
        local data = {}
        data.seg_1 = "1.3"
        local buf = pack(protocol.prot32,data)
        local data1 = unpack(protocol.prot32,buf)
        assert(data.seg_1 == data1.seg_1)
    end,
    
    test_checkcode1 = function ()
        local data = {}
        data.seg_1 = 34567
        local buf = pack(protocol.prot33,data)
        local data1 = unpack(protocol.prot33,buf)
        assert(data.seg_1 == data1.seg_1)
    end,
    
    test_checkcode2 = function ()
        local data = {}
        data.seg_1 = - 34567
        local buf = pack(protocol.prot34,data)
        local data1 = unpack(protocol.prot34,buf)
        assert(data.seg_1 == data1.seg_1)
    end,
    test_checkcode3 = function ()
        local data = {}
        data.seg_1 = {-22,34}
        local buf = pack(protocol.prot36,data)
        local data1 = unpack(protocol.prot36,buf)
        assert(data.seg_1[1] == data1.seg_1[1])
    end,
    
    
    test_checkcode4 = function ()
        local data = {}
        data.seg_1 = {"@#\0","rt\0"}
        local buf = pack(protocol.prot35,data)
        local data1 = unpack(protocol.prot35,buf)
        assert(data.seg_1[1] == data1.seg_1[1].."\0")
    end,
    test_checkcode5 = function ()
        local data = {}
        data.seg_1 = "1.3"
        local buf = pack(protocol.prot37,data)
        local data1 = unpack(protocol.prot37,buf)
        assert(data.seg_1 == data1.seg_1)
    end,
    test_checkcode6 = function ()
        local data = {}
        data.seg_1 = 34567
        local buf = pack(protocol.prot38,data)
        local data1 = unpack(protocol.prot38,buf)
        assert(data.seg_1 == data1.seg_1)
    end,
    test_checkcode7 = function ()
        local data = {}
        data.seg_1 = - 34567
        local buf = pack(protocol.prot39,data)
        local data1 = unpack(protocol.prot39,buf)
        assert(data.seg_1 == data1.seg_1)
    end,
    test_checkcode8 = function ()
        local data = {}
        data.seg_1 = {"qwe\0","qwe\0"}
        local buf = pack(protocol.prot40,data)
        local data1 = unpack(protocol.prot40,buf)
        assert(data.seg_1[1] == data1.seg_1[1].."\0")
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