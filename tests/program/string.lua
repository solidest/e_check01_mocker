local helper = require 'helper'
local test = {
    test_string = function ()
        local data1 = {}
        data1.seg_1 = 4
        data1.seg_2= "FSDD"
        data1.seg_3= "的房dfr了ffd"
        data1.seg_4 = "qwe\0"
        data1.seg_5 = '111'
        local da = pack(protocol.prot16, data1)
        local data2 = unpack(protocol.prot16, da)
        assert(data1.seg_1 == data2.seg_1)
        assert(data1.seg_2 == data2.seg_2)
        assert(data1.seg_3 == data2.seg_3)
        assert(data1.seg_4 == data2.seg_4.."\0")
        assert(data1.seg_5 == data2.seg_5)
    end,
    test_string1 = function ()
        local data1 = {}
        data1.seg_1 = 4
        data1.seg_2= "0.00"
        data1.seg_3= "的房dd"
        data1.seg_4 = "qwe\0"
        data1.seg_5 = '111'
        local da = pack(protocol.prot16, data1)
        local data2 = unpack(protocol.prot16, da)
        assert(data1.seg_1 == data2.seg_1)
        assert(data1.seg_2 == data2.seg_2)
        assert(data1.seg_3 == data2.seg_3)
        assert(data1.seg_4 == data2.seg_4.."\0")
        assert(data1.seg_5 == data2.seg_5)
    end,
    test_string2 = function ()
        local data1 = {}
        data1.seg_1 = "qwer"
        data1.seg_2= "1212"
        data1.seg_3= "erdd"
        data1.seg_4 = "q.we"
        local da = pack(protocol.prot17, data1)
        local data2 = unpack(protocol.prot17, da)
        assert(data1.seg_1 == data2.seg_1)
        assert(data1.seg_2 == data2.seg_2)
        assert(data1.seg_3 == data2.seg_3)
        assert(data1.seg_4 == data2.seg_4)
        assert(data1.seg_5 == data2.seg_5)
    end,
    test_string3 = function ()
        local data1 = {seg_1="0xaa\0"}
        local da = pack(protocol.prot18, data1)
        local data2 = unpack(protocol.prot18, da)
        assert(data2.seg_1== data2.seg_1)
    end,
    test_string4 = function ()
        local msg = message(protocol.string_)
        msg.test = {str="weet",str1= "str1"}
        local buff = pack(msg)
        local data = unpack(protocol.string_,buff)
        assert(msg.test.str == data .test.str )
    end,
    test_string5 = function ()
        local msg = message(protocol.string_, {test={str="\0",str1='\3'},te = "13"})
        local buff = pack(msg)
        local data = unpack(protocol.string_ , buff)
        assert(msg.test.str == data .test.str )
        assert(msg.te == data.te )
    end,
    test_string6 = function ()
        local msg = message(protocol.string_)
        msg.test = {str="\0",str1='\3',int=123}
        msg.te = "12"
        local buff = pack(msg)
        local data = unpack(protocol.string_ , buff)
        assert(msg.test.str == data .test.str )
        assert(msg.te == data.te )
    end,
    -- 当定义协议规则为字符串并且以\0结尾的时候，不给此协议段赋值时，会出现打包失败，该协议段autovalue属性错误
    -- 定义的协议段为int或者uint时候,autovalue属性不支持数学库计算赋值 举例 autovalue赋值为math.pow(2,5)---得到2的5次方,会显示协议定义错误
    -- oneof 好像不能在协议组中使用,会报错error get bool value of ==
    -- oneof的真值表达式不支持math数学库的计算
    test_string7 = function ()
        local msg = message(protocol.string_)
        msg.test = {str='*'}
        local buff = pack(msg)
        local data = unpack(protocol.string_, buff)
        print(data)  
    end,
    test_string8 = function ()
        local msg = message(protocol.string_)
        
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