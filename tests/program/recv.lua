local helper = require 'helper'
local test = {
    test_recv = function ()
        send(device.dev12.s2, "msf\0",{to="dev12.s1"})
        delay(1000)
        local s1, s2 = recv(device.dev12.s1, nil);
    end,
    test_recv1 = function ()
        local msg = message(protocol.prot_arrays)
        msg.head = 1
        send(device.dev12.s2, msg,{to="dev12.s1"})
        delay(100)
        local s1, s2 = recv(device.dev12.s1, nil)
        local data = unpack(protocol.prot_arrays,s1)
        assert(data.array.list.seg_1 == 1)
        assert(data.array.list.seg_1 == 1)
        assert(data.array.number == 1)
        assert(data.head == msg.head)
    end,
    test_recv2 = function ()
        local msg = "msfasdfasdfsadfdddddddddddddddddddddddddddddddddddddsdgdffffgsertweytyu \
        ddddddfgsdfddrfw3qrwerfiopsadufsrsd1f354d5s21f2ds1fq43w4rew54rr5asd45asfd f asdf"
        send(device.dev12.s2, msg,{to="dev12.s1"})
        delay(100)
        local s1, s2 = recv(device.dev12.s1, nil)
        assert(s1==msg)
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