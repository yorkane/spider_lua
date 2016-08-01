--[[
企明星爬虫系统，公共文件
Author:a7
Date:2016/4/7
]]

common={}

--Lua的Eval函数
function common.eval(script)
	script=common.clearJson(script)
	local tmp = "return "..script;
	local s = loadstring(tmp);
	if s==nil then
		return nil
	end
	return s()
end

--输出
function printf(obj)
	print(dump(obj) )
end

function dump(obj)  
    local getIndent, quoteStr, wrapKey, wrapVal, isArray, dumpObj  
    getIndent = function(level)  
        return string.rep("\t", level)  
    end  
    quoteStr = function(str)  
        str = string.gsub(str, "[%c\\\"]", {  
            ["\t"] = "\\t",  
            ["\r"] = "\\r",  
            ["\n"] = "\\n",  
            ["\""] = "\\\"",  
            ["\\"] = "\\\\",  
        })  
        return '"' .. str .. '"'  
    end  
    wrapKey = function(val)  
        if type(val) == "number" then  
            return "[" .. val .. "]"  
        elseif type(val) == "string" then  
            return "[" .. quoteStr(val) .. "]"  
        else  
            return "[" .. tostring(val) .. "]"  
        end  
    end  
    wrapVal = function(val, level)  
        if type(val) == "table" then  
            return dumpObj(val, level)  
        elseif type(val) == "number" then  
            return val  
        elseif type(val) == "string" then  
            return quoteStr(val)  
        else  
            return tostring(val)  
        end  
    end  
    local isArray = function(arr)  
        local count = 0   
        for k, v in pairs(arr) do  
            count = count + 1   
        end   
        for i = 1, count do  
            if arr[i] == nil then  
                return false  
            end   
        end   
        return true, count  
    end  
    dumpObj = function(obj, level)  
        if type(obj) ~= "table" then  
            return wrapVal(obj)  
        end  
        level = level + 1  
        local tokens = {}  
        tokens[#tokens + 1] = "{"  
        local ret, count = isArray(obj)  
        if ret then  
            for i = 1, count do  
                tokens[#tokens + 1] = getIndent(level) .. wrapVal(obj[i], level) .. ","  
            end  
        else  
            for k, v in pairs(obj) do  
                tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","  
            end  
        end  
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"  
        return table.concat(tokens, "\n")  
    end  
    return dumpObj(obj, 0)  
end  

--JSON数据清理
function common.clearJson(json)
	--中括号替换
	json=string.gsub(json,"%[","{")
	json=string.gsub(json,"%]","}")
	--键的引号及冒号替换
	json=string.gsub(json,"\"([^\"]*)\":","%1=")
	return json
end

--返回通用日期格式
--日期解析
function common.parseDate(datestr,datetype)
	local tmp = {}
	local pos=0
	for i in string.gmatch(datestr,"(%d+)")  do 
		tmp[pos]=i
		pos=pos+1
	end
	if table.getn(tmp) == 0 then
		return os.date("%Y-%m-%d %H:%M:%S", os.time())
	end
	--传入的格式是：年月日（中间可以有任意分隔符）
	if datetype=="yyyyMMdd" then
		return tmp[0].."-"..common.padDigital(tmp[1]).."-"..common.padDigital(tmp[2]).. os.date(" %H:%M:%S", os.time())
	--年月日时分秒
	elseif datetype=="yyyyMMddHHmmss" then 
		return tmp[0].."-"..tmp[1].."-"..common.padDigital(tmp[2]).." "..common.padDigital(tmp[3])..":"..tmp[4]..":"..tmp[5]
	--年月日时分
	elseif datetype=="yyyyMMddHHmm" then 
		return tmp[0].."-"..tmp[1].."-"..common.padDigital(tmp[2]).." "..common.padDigital(tmp[3])..":"..tmp[4]..":00"
	--月日	
	elseif datetype=="MMdd" then 
		return tostring(os.date("%Y",os.time())).."-"..common.padDigital(tmp[0]).."-"..common.padDigital(tmp[1]).. os.date(" %H:%M:%S", os.time())
	end
end

--日期补全
function common.padDigital(src)
	if string.len(src)<2 then
		return "0"..src
	else
		return src
	end
end
--local datestr="2016年05月12日22:05:04"
--print(parseDate(datestr,"yyyyMMddHHmm"))
--print(parseDate("4月5日","MMdd"))

--字符日期转时间戳  原始时间字符串，要求格式yyyy-MM-dd HH:mm:ss,
function common.strToTimestamp(str)  
    --从日期字符串中截取出年月日时分秒  
	if string.len(str)<19 then
		return os.time()
	end
    local Y = tonumber(string.sub(str,1,4))
    local M = tonumber(string.sub(str,6,7)) 
    local D = tonumber(string.sub(str,9,10))  
    local H = tonumber(string.sub(str,12,13))  
    local MM = tonumber(string.sub(str,15,16))  
    local SS = tonumber(string.sub(str,18,19))  
 	return os.time{year=Y, month=M, day=D, hour=H,min=MM,sec=SS} 
end  

function common.trim(s) 
	return string.gsub(s, "[\r|\n| |\t]+", "")
end   

--分割字符串
function common.split(str, split_char)
    local sub_str_tab = {};
    while (true) do
        local pos = string.find(str, split_char);
        if (not pos) then
            sub_str_tab[#sub_str_tab + 1] = str;
            break;
        end
        local sub_str = string.sub(str, 1, pos - 1);
        sub_str_tab[#sub_str_tab + 1] = sub_str;
        str = string.sub(str, pos + 1, #str);
    end
    return sub_str_tab;
end

--正则匹配返回值修正
function common.regTab(con,reg)
	local tab=string.match(con,reg)
	if tab==nil then
		return ""
	else
		return tab
	end
end

--只验证属性字段不为空 tab1属性字段，tab2待验证对象
function common.checkData(tab1,tab2)
	local b=true
	local str=""
	for _,v in pairs(tab1) do
		if tab2[v]==nil or tab2[v]=="" then
			str=str..v..":值空"..","
			b=false
		end
	end
	return  b,str
end

--URL编码
function common.decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s
end

function common.encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end

--通用方法结束
return common;
