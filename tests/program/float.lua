local helper = require 'helper'
local test = {
    -- 验证float中间值
    float_T_pro = function ()
        local data_send = {seg_1=0}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_1== data_send.seg_1)
    end,

    -- 验证float最小边界值
    float_Bmin_pro = function ()
        local data_send = {seg_1=-3.3999999521443642e+38,}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_1== data_send.seg_1)
    end,
        -- 验证float最大边界值
    float_Bmax_pro =  function ()
        local data_send = {seg_1=3.3999999521443642e+38,}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_1== data_send.seg_1)
    end,
    -- 验证float随机值 小数位需要为15位
    float_S_pro =function ()
        local data_send = {seg_1=3.399519920349121}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_1== data_send.seg_1)  
    end,
    float_s_pro =function ()
        local data_send = {seg_1=1}
        local buf = pack(protocol.prot_13, data_send)
        local data_recv = unpack(protocol.prot_13, buf)
        assert(data_recv.seg_1== data_send.seg_1)  
    end,
}

function entry(vars)
    local filter = "f"
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