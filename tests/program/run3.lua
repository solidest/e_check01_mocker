function onrecved(msg,opt)

    print(msg,opt)
    if msg == "ping\0" then 
        send(device.dev_c.conn,"pong dev_c\0") 
        delay(1)
 
    elseif msg =="cacl\0" then
        cacl()
    end

end


function cacl()

    local a,b = 0,1
    for i = 1, 2000 do

        
        delay(3)
        a = a+0.001
        local a1 = a*1000
        if a1 < 1000 then
            local x = math.sin(a)
            send(device.dev_c.conn,"sin("..a..") = " ..x.."\0")
        else 
            local y = math.sin(b)
            send(device.dev_c.conn,"sin("..b..") = " ..y.."\0")
            b = b-0.001
        
        end
    end

end


function entry(vars, option)

    async.on_recv(device.dev_c.conn, nil, onrecved)

end