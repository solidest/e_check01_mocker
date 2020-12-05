function onrecved(msg,opt)

    print(msg,opt)
    if msg == "ping\0" then 
        send(device.dev_b.conn,"pong dev_b\0") 
    elseif msg == "cacl\0" then
        cacl()
        
    end
end

function cacl()

    for i = 1, 10 do
        x = math.random()*100
        y = math.random()*100
        x = math.floor(x)
        y = math.floor(y)
        send(device.dev_b.conn,"x=".. ""..x..  "  y="..y.."\0")
        delay(500)
    end

end


function entry(vars, option)

    async.on_recv(device.dev_b.conn, nil, onrecved)

end