local helper = require 'helper'
local test = {
    -- 验证int8的整倍数
    int_Pro = function ()
        local data_send = {seg_8=127,seg_16=6533,seg_24=167215,seg_32=-42949293}
        local buf = pack(protocol.prot_11, data_send)
        local data_recv = unpack(protocol.prot_11, buf)
        assert
            (
                data_recv.seg_8 == data_send.seg_8 
            and data_recv.seg_16 == data_send.seg_16 
            and data_recv.seg_24 == data_send.seg_24  
            and data_recv.seg_32 == data_send.seg_32
            ) 
    end,
    -- 验证int特殊组合

    iEight_pro = function ()
        local data_send = {seg_1=1,seg_31=-64525591,seg_2=1,seg_30=-16177055}
        local buf = pack(protocol.prot_11, data_send)
        local data_recv = unpack(protocol.prot_11, buf)

        assert
            (
                data_recv.seg_1 == 1 
            and data_recv.seg_2 == data_send.seg_2 
            and data_recv.seg_30 == data_send.seg_30 
            and data_recv.seg_31 == data_send.seg_31 
            ) 

    end,
    -- 验证int随意位数组合
    iSun_pro = function ()
        local data_send = {seg_15=3268,seg_17=13172,seg_14=-1383,seg_18=2614}
        local buf = pack(protocol.prot_11, data_send)
        local data_recv = unpack(protocol.prot_11, buf)

        assert(
            data_recv.seg_14 == data_send.seg_14 
        and data_recv.seg_15 == data_send.seg_15 
        and data_recv.seg_17 == data_send.seg_17 
        and data_recv.seg_18 == data_send.seg_18
        ) 
    end,
}

function entry(vars)
    local filter = "i"
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