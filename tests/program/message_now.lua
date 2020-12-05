local helper = require 'helper'
local test = {
    test_message = function ()
        local msg = message(protocol.prot_message)
        msg.seg_message = 255
        msg.seg_messages = {msg_string = "wer", msg = {"---", "///"}, uint = 18446744073709551615}
        local buf = pack(msg)
        local msg1 = unpack(protocol.prot_message, buf)
        verify(msg1.seg_message == msg.seg_message,"断言失败")
        verify(msg.seg_messages.uint == 18446744073709551615, "断言失败")
        
    end,
    test_message1 = function ()
        local msg = message(protocol.prot_message,{seg_message = 0,seg_messages={msg_string = "$#@", msg = {"-*-", "0o="}, uint =0xffffffffffffffff}})
        local buf = pack(msg)
        local msg1 = unpack(protocol.prot_message, buf)
        verify(msg1.seg_message == msg.seg_message,"断言失败")
        verify(msg.seg_messages.uint == msg1.seg_messages.uint, "断言失败")
        assert(msg.seg_messages.msg[1] == msg1.seg_messages.msg[1])
       
    end,
    test_now = function ()
        local t1 = now()
        delay(10)
        local t2 = now()
        print("ms",t2-t1)
    end,
    test_now1 = function ()
        local t1 = now('us')
        delay(10)
        local t2 = now("us")
        print("us",t2-t1)
    
    end,
    test_now2 = function ()
        local t1 = now('ns')
        delay(10)
        local t2 = now("ns")
        print("ns",t2-t1)
        
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