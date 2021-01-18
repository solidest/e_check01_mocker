local helper = require "helper"
local test = {
    test_array = function ()
        local data1 = {}
        data1.seg_1 = {34, 45, 98, 345, 1, 0, 234, 12344}
        data1.seg_2 = {7, -9, 2688}
        data1.seg_3 = 9999.88889
        data1.seg_4 = 2
        local buf = pack(protocol.prot19,data1)
        local data2 = unpack(protocol.prot19, buf)
        assert(data1.seg_2[1] == data2.seg_2[1])
        assert(data1.seg_2[2] == data2.seg_2[2])
        assert(data1.seg_2[3] == data2.seg_2[3])
        assert(data1.seg_1[1] == data2.seg_1[1])
        assert(data1.seg_1[2] == data2.seg_1[2])
        assert(data1.seg_1[3] == data2.seg_1[3])
        assert(data1.seg_1[4] == data2.seg_1[4])
        assert(data1.seg_1[5] == data2.seg_1[5])
        assert(data1.seg_1[6] == data2.seg_1[6])
        assert(data1.seg_1[7] == data2.seg_1[7])
        assert(data1.seg_1[8] == data2.seg_1[8])
    end,
    test_array1 = function ()
        local data1 = {}
        data1.seg_1 = {34,}
        data1.seg_2 = {1.2, -1.123}
        data1.seg_4 = 2.34
        local buf = pack(protocol.prot20,data1)
        local data2 = unpack(protocol.prot20, buf)
        assert(data1.seg_1[1] == data2.seg_1[1])
        assert(math.isequal(data1.seg_2[1], data2.seg_2[1]))
        assert(math.isequal(data1.seg_2[2], data2.seg_2[2]))
        assert(data1.seg_4 == data2.seg_4)
    end,
    test_array2 = function ()
        local data1 = {}
        data1.seg_1 = {1}
        data1.seg_2 = {1123, -12133,0}
        data1.seg_3 = 123
        data1.seg_4 = {1.222,0,-2.345}
        local buf = pack(protocol.prot21,data1)
        local data2 = unpack(protocol.prot21, buf)
        assert(data1.seg_1[1] == data2.seg_1[1])
        assert(math.isequal(data1.seg_2[1], data2.seg_2[1]),true)
        assert(math.isequal(data1.seg_2[2], data2.seg_2[2]),true)
        assert(math.isequal(data1.seg_4[1], data2.seg_4[1]))
        assert(math.isequal(data1.seg_4[2], data2.seg_4[2]))
        assert(math.isequal(data1.seg_4[3], data2.seg_4[3]))
    end,
    test_array3 = function ()
        local data1 = {}
        data1.seg_1 = {0}
        data1.seg_2 = {1, -1,0}
        data1.seg_3 = 123
        data1.seg_4 = {1.222,0,-2.345}
        data1.seg_5 = {0}
        local buf = pack(protocol.prot22,data1)
        local data2 = unpack(protocol.prot22, buf)
        assert(data1.seg_1[1] == data2.seg_1[1])
        assert(math.isequal(data1.seg_2[1], data2.seg_2[1]))
        assert(math.isequal(data1.seg_2[2], data2.seg_2[2]))
        assert(math.isequal(data1.seg_4[1], data2.seg_4[1]))
        assert(math.isequal(data1.seg_4[2], data2.seg_4[2]))
        assert(math.isequal(data1.seg_4[3], data2.seg_4[3]))
    end,
    test_array4 = function ()
        local msg = message(protocol.prot_array)
        msg.seg_1 = {0,1}
        msg.seg_2 = {"@#$","!!!"}
        local data = pack(msg)
        local data1 = unpack(protocol.prot_array,data)
        assert(math.isequal(data1.seg_1[1], msg.seg_1[1]))
        assert(math.isequal(data1.seg_1[2], msg.seg_1[2]))
        assert(data1.seg_2[1] == msg.seg_2[1])
        assert(data1.seg_2[2] == msg.seg_2[2])
    end,
    test_array5 = function ()
        local msg = message(protocol.prot_arrays)
        msg.head = 0
        msg.array ={number=255,list={seg_1=65535,seg_2="65535"}} 
        local da = pack(msg)
        local data1 = unpack(protocol.prot_arrays,da)
        assert(msg.head == data1.head)
        assert(msg.array.number == data1.array.number)
        assert(msg.array.list.seg_1 == data1.array.list.seg_1)
        assert(msg.array.list.seg_2 == data1.array.list.seg_2)
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