local helper = require 'helper'
local test = {
    t_user_ok = function ()
        --提示用户进行确认
        local answer1 = ask('ok',  {title='提示', msg='确认后继续'})
        print(answer1) ------>'ok'
    end,
    t_user_yesno = function ()
         --提示用户选择是与否,默认为true
        local answer2 = ask('yesno',  {title='提示', msg='请回答yes或no', default=true})
        print(answer2)------>true|false
    end,
    t_user_input_string = function ()
        --提示用户输入字符串,默认是abcd
        local answer3 = ask('text', {title='提示', msg='输入字符串', default='abcd'})
        print(answer3)-------->'abcd'
    end,
    t_user_input_number = function ()
        --提示用户输入数字,默认是3，
        local answer4 = ask('number', {title='提示', msg='输入数字', default=3})
        print(answer4)-------->3
    end,
    t_user_check = function ()
        --提示用户选择某一项,默认第一项
        local answer4 = ask('select', {title='提示', msg='请选择', default='第一项', items={'第一项','第二项', '第三项'} })
        print(answer4)------------> '第一项'
        
    end,
    t_user_state = function ()
        -- 提示用户按如下指示进行操作，on是默认状态，disabled是否可以编辑
        local answer5 = ask("multiswitch", 
                {
                    title = "提示", 
                    msg = "按照以下指示进行开关操作", 
                    items = {
                        {
                            name = "xxx开关名称1",
                            value = "x2-34",
                            on = true,
                            disabled = true,
                        }, {
                            name = "xxx开关名称2",
                            value = "x2-35",
                            on = false,
                            disabled = false,
                        }
                    }
                }
            )
        print(answer5)------------> ['x2-34']
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