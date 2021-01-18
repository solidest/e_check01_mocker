
local helper = require 'helper'
local test = {
    test_str_array = function ()
        local data1 = {}
        data1.seg_1 = {65535}
        data1.seg_2 = {"12rt2\0","qwer\0"}
        data1.seg_3 = 1.2345
        local buf = pack(protocol.prot27,data1)
        local data2 = unpack(protocol.prot27, buf)
        assert(data1.seg_1[1] == data2.seg_1[1])
        assert(math.isequal(data1.seg_3,data2.seg_3))
        assert(data1.seg_2[1] == data2.seg_2[1].."\0")
        assert(data1.seg_2[2] == data2.seg_2[2].."\0")
    end,

    test_str_array1 = function ()
        local data1 = {type1=3, type2=1}
        local buf = pack(protocol.prot28, data1)
        local data2 = unpack(protocol.prot28, buf)
        assert(math.isequal(data2.p,-6))
        assert(math.isequal(data2.type1,data1.type1))
        assert(math.isequal(data2.type2,data1.type2))
        assert(math.isequal(data2.x,2))
        assert(math.isequal(data2.x1,15))
        assert(math.isequal(data2.p1,-15))
        assert(data1.p2 == nil)
    end,
    test_str_array2 = function ()
        local data1 = {type1=1, type2=1}
        local buf = pack(protocol.prot28, data1)
        local data2 = unpack(protocol.prot28, buf)
        assert(math.isequal(data2.type1,data1.type1))
        assert(math.isequal(data2.type2,data1.type2))
        assert(math.isequal(data2.x11,2))
        assert(math.isequal(data2.x1,15))
        assert(math.isequal(7,data2.test))
    end,
    test_str_array3 = function ()
        local data1 ={}
        data1.seg_3 = 1.002
        local buf = pack(protocol.prot29, data1)
        local data2 = unpack(protocol.prot29, buf)
        assert(math.isequal(data1.seg_3,data2.seg_3))  
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