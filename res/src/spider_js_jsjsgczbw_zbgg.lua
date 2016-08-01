local com=require "res.util.comm"
--名称
spiderName="江苏建设工程招标网_招标公告";
--代码
spiderCode="js_jsjsgczbw_zbgg";
--是否下载3级页
spiderDownDetailPage=false;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=10;
--上次下载时间
spiderLastDownloadTime="2010-01-01 01:10:01";
--执行频率30分钟
spiderRunRate=30;
--下载内容写入表名
spider2Collection="huangweidong";
--下载页面时使用的编码
spiderPageEncoding="GBK";
--是否使用代理
spiderUserProxy=false;
--是否是安全协议
spiderUserHttps=false;
--下载详细页线程数
spiderThread=1
--存储模式 1 直接存储，2 调用消息总线 ...
spiderStoreMode=1
spiderStoreToMsgEvent=4002 --消息总线event
--判重字段 空默认不判重，spiderCoverAttr="title" 按title判重覆盖
spiderCoverAttr="title"
--延时毫秒 基本延时(spiderSleepBase)+随机延时(spiderSleepRand)
spiderSleepBase=1000
spiderSleepRand=5000
spiderTargetChannelUrl="http://www.jszb.com.cn/jszb/YW_info/ZhaoBiaoGG/MoreInfo_ZBGG.aspx?categoryNum=012"
local cks =""
local head={}
local param={}
local __CSRFTOKEN = ""
local __EVENTTARGET = "MoreInfoList1$Pager"
local __VIEWSTATE = ""
local __VIEWSTATEGENERATOR = ""
local __EVENTVALIDATION = ""
local content = ""


local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download("http://www.jszb.com.cn/jszb/YW_info/ZhaoBiaoGG/MoreInfo_ZBGG.aspx?categoryNum=012",{})
	local tmp = findOneText("table#MoreInfoList1_DataGrid1 tr:eq(0) td:eq(3)",content)
	local lastpushtime=com.parseDate(tmp,"yyyyMMdd")
	return lastpushtime
end

--下载分析列表页
function downloadAndParseListPage(pageno)
	print("pageno:"..pageno)
	head={
	["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
	["Accept-Encoding"]="deflate",
	["Accept-Language"]="zh-CN,zh;q=0.8",
	["Cache-Control"]="max-age=0",
	["Connection"]="keep-alive",
	["Content-Type"]="application/x-www-form-urlencoded",
	["Cookie"]=cks,
	["Upgrade-Insecure-Requests"]="1",
	["Origin"]="http://www.jszb.com.cn",
	["Host"]="www.jszb.com.cn",
	["Referer"]="http://www.jszb.com.cn/jszb/YW_info/ZhaoBiaoGG/MoreInfo_ZBGG.aspx?categoryNum=012",
	["User-Agent"]="Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2552.0 Safari/537.36",
	}
	if pageno == 1 then

		param={
			["categoryNum"]="012",
		}
		content,cks = downloadAdv("http://www.jszb.com.cn/jszb/YW_info/ZhaoBiaoGG/MoreInfo_ZBGG.aspx","get",param,{},cks)

	else
		param={
			["__CSRFTOKEN"]=__CSRFTOKEN,
			["__EVENTTARGET"]=__EVENTTARGET,
			["__EVENTARGUMENT"]=pageno.."",
			["__VIEWSTATE"]=__VIEWSTATE,
			["__VIEWSTATEGENERATOR"]=__VIEWSTATEGENERATOR,
			["__EVENTVALIDATION"]=__EVENTVALIDATION,
			["MoreInfoList1$jpdDi"]="-1",
			["MoreInfoList1$jpdXian"]="-1",
		}
	
		content,cks = downloadAdv("http://www.jszb.com.cn/jszb/YW_info/ZhaoBiaoGG/MoreInfo_ZBGG.aspx?categoryNum=012","post",param,{},cks)
	end
	__CSRFTOKEN = encodeURI(findOneText("input#__CSRFTOKEN:attr(value)",content))
	__VIEWSTATE =encodeURI(findOneText("input#__VIEWSTATE:attr(value)",content))
	__VIEWSTATEGENERATOR = encodeURI(findOneText("input#__VIEWSTATEGENERATOR:attr(value)",content))
	__EVENTVALIDATION = encodeURI(findOneText("input#__EVENTVALIDATION:attr(value)",content))


	local list = findListHtml("table#MoreInfoList1_DataGrid1 tr",content)
	local csTemp = 0
	while table.getn(list)<1 do
		csTemp = csTemp + 1
		if csTemp == 5 then
			break
		end
		timeSleep(30)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
 
	local page={}	
	for k,v in pairs(list) do
		
		item={}
		item["href"]="a:attr(onclick)"
		item["title"]="a"
		item["publishtime"]="td:eq(3)"
		item=findMap(item,"<table><tr>"..v.."</tr></table>")
		item["href"] = string.gsub(item["href"],"\"","'")
		item["href"] = string.match(item["href"],"Z.*%d'")
		item["href"] = string.gsub(item["href"],"'","")
		item["title"] = com.trim(item["title"])
		item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
		item["href"]="http://www.jszb.com.cn/jszb/YW_info/"..item["href"]
		print("title:"..item["title"])
		if k==1 and pageno==1 then
			if lastRoundTagId=="" then
				lastRoundTagId=item["href"]
			else
				firstStart=false
			end	
			currRoundTagId=item["href"]

		end
		if lastRoundTagId==item["href"] and not firstStart then
			lastRoundTagId=currRoundTagId	
			item["exit"]="true"
		end
		table.insert(page,item)
	end
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do
		local content = download(data["href"],{})
		local ret={}
		ret["title"]="table#Table1 tr:eq(0)"
		ret=findMap(ret,content)
		ret["detail"]=findOneText("style","span#zygg_kkk",content)
		ret["title"]=com.trim(ret["title"])
		ret["site"]="江苏建设工程招标网"
		ret["channel"]="招标公告"
		ret["toptype"]="招标"
		ret["subtype"]="公开招标"
		ret["contenthtml"]=findOneHtml("span#zygg_kkk",content)
		ret["type"]="tender"
		ret["area"]="江苏"
		ret["charset"]=spiderPageEncoding
		ret["spidercode"]=spiderCode
		ret["_d"]="comeintime"
		ret["href"]=data["href"]
		ret["l_np_publishtime"]=com.strToTimestamp(data["publishtime"])
		local checkAttr={"title","href","detail","contenthtml","l_np_publishtime"}
		local b,err=com.checkData(checkAttr,ret)
		if b then
			return ret
		else
			timeSleep(60)--延时60秒再次请求
			if i==5 then
				saveErrLog(spiderCode,spiderName,ret["href"],err..content)
			end
		end
	end
end


--保存错误日志
--saveErrLog(spiderCode,spiderName,,出错url,出错原因)

function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end
