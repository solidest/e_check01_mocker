


-- 解包函数
-- 协议段解包时调用
-- 输入参数 seg_name: 协议段名称、prot_buff：报文原始字节、 pos: 当前解析位置
-- 返回值：必须返回2个值，第1个为解析得到的值，第2个为解析使用的字节长度


--将含D字符的string解包成浮点数
function UnpackFloat_D(seg_name, prot_buff, pos)
    local pos_end = pos
    local str = ''
    if seg_name=='WD' then
        pos_end = string.len(prot_buff)
        str = string.sub(prot_buff, pos, pos_end)
    else 
        pos_end = string.find(prot_buff, 'F', pos)
        str = string.sub(prot_buff, pos, pos_end-1)
    end
    str = string.gsub(str, 'D', '.')
    return tonumber(str), pos_end-pos+1
end


--将整数字符串解包成缩小10倍的浮点数
function UnpackFloat_I(seg_name, prot_buff, pos)
    local pos_end = string.find(prot_buff, 'F', pos)
    local str = string.sub(prot_buff, pos, pos_end-1)
    return tonumber(str)/10, pos_end-pos+1
end