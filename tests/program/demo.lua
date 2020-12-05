

function entry()
    delay(10)
    local a = 1
    print(a)
    -- log.log("abc")
    log.warn("warn")
    log.error("err")
    local answer1 = ask('ok',  {title='提示', msg='确认后继续'})
      print(answer1) ------>'ok'
      record.x = 100
    exit()
end