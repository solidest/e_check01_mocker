local helper = require 'helper'
local test = {
    -- 验证uint的8的整数倍数
    uint_pro = function ()
        local data_send = {seg_8=127,seg_16=65535,seg_24=16777213,seg_32=4294967293}
        local buf = pack(protocol.prot_12, data_send)
        local data_recv = unpack(protocol.prot_12, buf)

        assert
            (
                data_recv.seg_8 == data_send.seg_8 
            and data_recv.seg_16 == data_send.seg_16 
            and data_recv.seg_24 == data_send.seg_24  
            and data_recv.seg_32 == data_send.seg_32
            ) 
    end,
    -- 验证unit特殊值
    unit_T_pro = function ()

        local data_send = {seg_1=0,seg_31=2147483639,seg_2=1,seg_30=1073741823}
        local buf = pack(protocol.prot_12, data_send)
        local data_recv = unpack(protocol.prot_12, buf)

        assert
            (
                data_recv.seg_1 == 0 
            and data_recv.seg_2 == data_send.seg_2 
            and data_recv.seg_30 == data_send.seg_30 
            and data_recv.seg_31 == data_send.seg_31 
            ) 
    end,

    -- 验证uint随机值
    unit_S_pro = function ()
        local data_send = {seg_15=32761,seg_17=131071,seg_14=16383,seg_18=26143}
        local buf = pack(protocol.prot_12, data_send)
        local data_recv = unpack(protocol.prot_12, buf)
        assert(
            data_recv.seg_14 == data_send.seg_14 
        and data_recv.seg_15 == data_send.seg_15 
        and data_recv.seg_17 == data_send.seg_17 
        and data_recv.seg_18 == data_send.seg_18
        ) 
    end,


-- 验证uint随机值
    unit_S_pro_int = function ()
        local data_send = {seg_15=0,seg_17=1,seg_14=1,seg_18=0}
        local buf = pack(protocol.prot_12, data_send)
        local data_recv = unpack(protocol.prot_12, buf)
        assert(
            data_recv.seg_14 == data_send.seg_14 
        and data_recv.seg_15 == data_send.seg_15 
        and data_recv.seg_17 == data_send.seg_17 
        and data_recv.seg_18 == data_send.seg_18
        ) 
    end
}
function entry(vars)
    local filter = "u"
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