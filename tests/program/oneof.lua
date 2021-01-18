local helper = require 'helper'
local test = {
    test_oneof1 =function ()
        local data1 = {type1=2, type2=1}
        local buf = pack(protocol.prot23, data1)
        local data2 = unpack(protocol.prot23, buf)
        assert(data2.z==nil)
        assert(math.isequal(data1.type1, data2.type1))
        assert(math.isequal(data1.type2, data2.type2))
    end,
    
    
    test_oneof2 = function ()
        local data1 = {type1=0, type2=1,  x1=1.11}
        -- local data1 = {type1=0, type2=1}
        local buf = pack(protocol.prot23, data1,true)
        local data2 = unpack(protocol.prot23, buf)
        assert(data2.y==nil)
        assert(data2.z==nil)
        assert(math.isequal(data1.type2, data2.type2))
        -- assert(math.isequal(n, data2.x))
        assert(math.isequal(1.11, data2.x1))
    end,
    test_oneof3 = function ()
        local data1 = {type1=2, type2=1}
        local buf = pack(protocol.prot24, data1)
        local data2 = unpack(protocol.prot24, buf)
        assert(math.isequal(data2.p,1.6))
        assert(math.isequal(data2.type1,data1.type1))
        assert(math.isequal(data2.type2,data1.type2))
        assert(math.isequal(data2.x,3))
        assert(math.isequal(data2.x1,2.23))
        assert(math.isequal(data2.p,1.6))
    end,
    test_oneof4 = function ()
        local data1 = {type1=3, type2=1}
        local buf = pack(protocol.prot25, data1)
        local data2 = unpack(protocol.prot25, buf)
        assert(math.isequal(data2.p,-6))
        assert(math.isequal(data2.type1,data1.type1))
        assert(math.isequal(data2.type2,data1.type2))
        assert(math.isequal(data2.x,2))
        assert(math.isequal(data2.x1,15))
        assert(math.isequal(data2.p1,-15))
    end,
    test_oneof5 = function ()
        local data1 = {type1=3, type2=1}
        local buf = pack(protocol.prot26, data1)
        local data2 = unpack(protocol.prot26, buf)
        assert(math.isequal(data2.p,-6))
        assert(math.isequal(data2.type1,data1.type1))
        assert(math.isequal(data2.type2,data1.type2))
        assert(math.isequal(data2.x,2))
        assert(math.isequal(data2.x1,15))
        assert(math.isequal(data2.p1,-15))
        assert(data1.p2 == nil)
        assert(data2.p2 == "qwe")
    end,
    test_oneof_segments = function ()
        -- local msg = {xx = 2,oneof_name = {str = "qqq",seg_name =1.11,list={12,11},test={qq=5,qs={ww=24,ee=(math.pow(2,40)-1),tt={"ew","er"}}}}}
        local msg = {xx=2,aa=6}
        local data = pack(protocol.oneof_prot, msg)
        local data2 = unpack(protocol.oneof_prot, data)
        assert(data2.oneof_name.test.qs.string == "123")
        
    end,
    test_oneofs = function ()
        local msg = {str="123"}
        local buff = pack(protocol.one_prot,msg)
        local data = unpack(protocol.one_prot,buff)
        assert(msg.str == data.str)
        assert(data.name == 0)
        assert(data.float == 0)
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