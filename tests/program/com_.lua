-- 验证组合值
local helper = require 'helper'
local test = {
    com_pro1 = function ()
        local data_send = {seg_1=1.22}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_1, data_send.seg_1))
    end,
    com_pro2 = function ()
        local data_send = {seg_2=0.23334}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_2, data_send.seg_2,true))
    end,
    com_pro3 = function ()
        local data_send = {seg_3=-111}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_3, data_send.seg_3,true))
    end,
    com_pro4 = function ()
        local data_send = {seg_4=4294967293}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_4, data_send.seg_4))
    end,
    com_pro5 = function ()
        local data_send = {seg_4=4294967293,seg_1=1.2,seg_2=1.234,seg_3=234}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_4, data_send.seg_4,true))
        assert(math.isequal(data_recv.seg_1, data_send.seg_1))
        assert(math.isequal(data_recv.seg_2, data_send.seg_2,true))
        assert(math.isequal(data_recv.seg_3, data_send.seg_3,true))
    end,
    com_pro6 = function ()
        local data_send = {seg_4=4294967293,seg_1=1.2,seg_2=1.234,seg_3=234}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_4, data_send.seg_4,true))
        assert(math.isequal(data_recv.seg_1, data_send.seg_1))
        assert(math.isequal(data_recv.seg_2, data_send.seg_2,true))
        assert(math.isequal(data_recv.seg_3, data_send.seg_3,true))
    end,
    com_pro7 = function ()
        local data_send = {seg_5=1.234,seg_6=1.2,seg_7=22345,seg_8=23555774}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_5, data_send.seg_5))
        assert(math.isequal(data_recv.seg_6, data_send.seg_6))
        assert(math.isequal(data_recv.seg_7, data_send.seg_7,true))
        assert(math.isequal(data_recv.seg_8, data_send.seg_8,true))
    end,
    com_pro8 = function ()
        local data_send = {seg_9=-1.234,seg_10=-1.2,seg_11=-22345,seg_12=23555774}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_9, data_send.seg_9))
        assert(math.isequal(data_recv.seg_10, data_send.seg_10))
        assert(math.isequal(data_recv.seg_11, data_send.seg_11,true))
        assert(math.isequal(data_recv.seg_12, data_send.seg_12,true))
    end,
    com_pro9 = function ()
        local data_send = {seg_9=1.234,seg_10=1.2,seg_11=22345,seg_12=235557}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_9, data_send.seg_9))
        assert(math.isequal(data_recv.seg_10, data_send.seg_10))
        assert(math.isequal(data_recv.seg_11, data_send.seg_11,true))
        assert(math.isequal(data_recv.seg_12, data_send.seg_12,true))
    end,
    com_pro10 = function ()
        local data_send = {seg_13=0.6789,seg_14=2.4567,seg_15=-2233345,seg_16=777685}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_13, data_send.seg_13))
        assert(math.isequal(data_recv.seg_14, data_send.seg_14))
        assert(math.isequal(data_recv.seg_15, data_send.seg_15,true))
        assert(math.isequal(data_recv.seg_16, data_send.seg_16,true))
    end,
    com_pro11 = function ()
        local data_send = {seg_13=-0.6789,seg_14=-2.4567,seg_15=-233345,seg_16=777685}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_13, data_send.seg_13))
        assert(math.isequal(data_recv.seg_14, data_send.seg_14))
        assert(math.isequal(data_recv.seg_15, data_send.seg_15,true))
        assert(math.isequal(data_recv.seg_16, data_send.seg_16,true))
    end,
    com_pro12 = function ()
        local data_send = {seg_17=424,seg_18=43547,seg_19=127,seg_20=126}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_17, data_send.seg_17))
        assert(math.isequal(data_recv.seg_18, data_send.seg_18))
        assert(math.isequal(data_recv.seg_19, data_send.seg_19,true))
        assert(math.isequal(data_recv.seg_20, data_send.seg_20,true))
    end,
    com_pro13 = function ()
        local data_send = {seg_17=-424,seg_18=43547,seg_19=-127,seg_20=126}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_17, data_send.seg_17))
        assert(math.isequal(data_recv.seg_18, data_send.seg_18))
        assert(math.isequal(data_recv.seg_19, data_send.seg_19,true))
        assert(math.isequal(data_recv.seg_20, data_send.seg_20,true))
    end,
    com_pro14 = function ()
        local data_send = {seg_13=0,seg_15=0}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_13, data_send.seg_13))
        assert(math.isequal(data_recv.seg_15, data_send.seg_15))
        assert(math.isequal(data_recv.seg_15, data_send.seg_15,true))
    end,
    com_pro15 = function ()
        local data_send = {seg_17=0,seg_18=0,seg_19=0,seg_20=0}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_17, data_send.seg_17))
        assert(math.isequal(data_recv.seg_18, data_send.seg_18))
        assert(math.isequal(data_recv.seg_19, data_send.seg_19,true))
        assert(math.isequal(data_recv.seg_20, data_send.seg_20,true))
    end,
    com_pro16 = function ()
        local data_send = {seg_1=-1.234,seg_17=-0.0,seg_15=-22345}
        local buf = pack(protocol.prot_15, data_send)
        local data_recv = unpack(protocol.prot_15, buf)
        assert(math.isequal(data_recv.seg_1, data_send.seg_1))
        assert(math.isequal(data_recv.seg_17, data_send.seg_17))
        assert(math.isequal(data_recv.seg_15, data_send.seg_15,true))
    end
}


function entry(vars)
    local filter = "c"
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