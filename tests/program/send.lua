
local helper = require 'helper'
local test = {
    test_send = function ()
        local msg = message(protocol.send_1)
        msg.seg1 = 4
        msg.seg2 = {0,2,3, 4}
    
        local sta = "qwerrrrewqrfasfasdfdftjhuiangiweas;ddfl;ksafffowqpa'wojtsafsdfsdfsdffasdfasadffatteryfggdjgdfjferrrrewqrfasfasdfdftjhuiangiweas;ddfl;ksafffowqpa'wojtsafsdfsdfsdffasdfasadffatteryfggdjgdfjfhrewyysdfijerrrrewqrfasfasdfdftjhuiangiweas;ddfl;ksafffowqpa'wojtsafsdfsdfsdffasdfasadffatteryfggdjgdfjfhrewyysdfijerrrrewqrfasfasdfdftjhuiangiweas;ddfl;ksafffowqpa'wojtsafsdfsdfsdffasdfasadffatteryfggdjgdfjfhrewyysdfijhrewyysdfijsdljgjgsdklfjoweapruiweerpawesdffsafdsafasoiperwafsdlkff;lskfa;sdkfals;akfoweairpoqwererrrwwwwwwaarsdzffffaaaaaasdffgdsffgdaaffsdfearrerrrtgadtsgdfsdgsdfgdsfsgdgsdfgheaytgwajfksdjfa;ssfjoweiporujsaafjksdjflsafisdoafihwawejopqqruosajfaklsdjfgisahgiosdetjgfsd1112223"
        send(device.dev12.udp_name, msg)
        send(device.dev12.udp_name, "msg")
        send(device.dev12.udp_name, "msg\0")
        send(device.dev12.udp_name, "")
        send(device.dev12.udp_name, sta)
        send(device.dev12.s1, "msg\0",{to_port=8000})
        -- 总线连接中通过设置`to`属性标识目标设备接口
        send(device.dev12.s3,msg,{to='dev11.c2'})
     
        -- send(device.dev12.s1, msg)
        -- send(device.dev12.s3, msg)
        -- send(device.dev12.s4, msg, {to_port=8000})
        -- send(device.dev12.udp_name, string.buf('AA 55 E2 B3'))
        -- send(device.dev2.uu2, msg)
 
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