-- 打包函数
-- 协议段打包时调用
-- 输入参数 seg_name: 协议段名称、seg_value：协议段值
-- 返回值：返回打包后的string

--将浮点数打包成字符串 字符D替换小数点
function PackFloat_D(seg_name, seg_value)
    local str = string.format("%.5f", seg_value)
    if seg_name=='WD' then  --纬度是最后一个字符串，不需要分割符F
        return string.gsub(str, "%.", "D")
    else 
        return string.gsub(str, "%.", "D")..'F'
    end
end




--将浮点数放大10倍后打包成整数字符串
function PackFloat_I(seg_name, seg_value, prot_data)
    return string.format("%.0f", seg_value*10)..'F'
end

