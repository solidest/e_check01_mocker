function onrecved(msg,opt)

    print(msg,opt)
    if msg == "ping\0" then 
        send(device.dev_a.conn,"pong dev_a\0") 
    elseif msg == "cacl\0" then
        cacl()
        
    end

end

function cacl()
    for i = 1, 100 do
        send(device.dev_a.conn,""..i.."\0")
        delay(40)
    end

end


function entry(vars, option)

    async.on_recv(device.dev_a.conn, nil, onrecved)

end