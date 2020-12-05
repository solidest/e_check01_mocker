-- 验证double中间值
local helper = require 'helper'
local test = {
    double_T_pro = function ()
        local data_send = {seg_2=0,}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_2== data_send.seg_2)
    end,
    -- 验证double最小边界值
    double_Bmax_pro = function ()
        local data_send = {seg_2=-1.7976E+308}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_2== data_send.seg_2)
    end,
    -- 验证double最大边界值
    double_Bmin_pro = function ()
        local data_send = {seg_2=1.7976E+308}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_2== data_send.seg_2)
    end,
    -- 验证double随机值
    double_S_pro = function ()
        local data_send = {seg_2=1.797667}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_2== data_send.seg_2)
    end,
    -- 验证double随机值
    double_int_pro = function ()
        local data_send = {seg_2=0}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_2== data_send.seg_2)
    end,
    -- 验证double随机值
    double_ints_pro = function ()
        local data_send = {seg_2=1}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_2== data_send.seg_2)
    end,


}
function entry(vars)
    local filter = "d"
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