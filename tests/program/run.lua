function Test1()

    function recv_data(data,opt)
        
        print(data,opt)

    end
    async.on_recv(device.main_ctr.conn,nil,recv_data)
    print("ping dev_a")
    async.send(device.main_ctr.conn,"ping\0",{to="dev_a.conn"})
    print("ping dev_b")
    async.send(device.main_ctr.conn,"ping\0",{to="dev_b.conn"})
    print("ping dev_c")
    async.send(device.main_ctr.conn,"ping\0",{to="dev_c.conn"})

    print("\n ","send command to dev_a")
    send(device.main_ctr.conn,"cacl\0",{to="dev_a.conn"})
    delay(5000)
    print("\n ","send command to dev_b")
    send(device.main_ctr.conn,"cacl\0",{to="dev_b.conn"})
    delay(5500)
    print("\n","send command to dev_c")
    send(device.main_ctr.conn,"cacl\0",{to="dev_c.conn"})
    delay(8000) 

end


function entry(vars, option)
    Test1()
    exit()

end