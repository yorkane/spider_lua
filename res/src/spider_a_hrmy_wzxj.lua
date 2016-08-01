--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="华润煤业_物质询价";
--代码 区域代码_网站代码_栏目代码
spiderCode="a_crcoal_wzxj";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=1;
--上次下载时间 yyyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-05-22 01:10:01";
--执行频率30分钟
spiderRunRate=5;
--下载内容写入表名 统一为：bidding，测试除外
spider2Collection="huangweidong";
--下载页面时使用的编码 根据页面编码填写,一般为utf8,gbk(gb2312也填gbk)
spiderPageEncoding="utf8";
--是否使用代理
spiderUserProxy=false;
--是否是安全协议
spiderUserHttps=false;
--下载详细页线程数
spiderThread=1
--存储模式 1 直接存储，2 调用消息总线 ...
spiderStoreMode=1
spiderStoreToMsgEvent=4002 --消息总线event
--消息传送判重字段统一按title判重覆盖
spiderCoverAttr="title"
--延时毫秒 基本延时(spiderSleepBase)+随机延时(spiderSleepRand)
spiderSleepBase=1000
spiderSleepRand=1000
--默认列表页第一页
spiderTargetChannelUrl="http://b2bcoal.crp.net.cn/Tender/ShowTenderList.aspx?type=Inquiry&mode=-1&pre=0"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	return os.date("%Y-%m-%d %H:%M:%S",os.time())
	
end

--下载分析列表页
local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true
local cookies =""
local head={}
local param={}
function downloadAndParseListPage(pageno)
	local page={}	
	local href=""
	if pageno==1 then
		href=spiderTargetChannelUrl
		content,cookies = downloadAdv(href,"get",param,head,cookies)
	else
		
		content,cookies = downloadAdv(spiderTargetChannelUrl,"post",param,head,cookies)
	end

	param={
		["__VIEWSTATE"]=encodeURI(findOneText("input#__VIEWSTATE:attr(value)",content)),
		["__EVENTTARGET"]="ctl00$ContentPlaceHolder1$pager",
		["__EVENTARGUMENT"]=pageno+1.."",
		["__EVENTVALIDATION"]=encodeURI(findOneText("input#__EVENTVALIDATION:attr(value)",content)),
		["__VIEWSTATEGENERATOR"]=encodeURI(findOneText("input#__VIEWSTATEGENERATOR:attr(value)",content)),
		["ctl00$CSS_value"]="true"
		["ctl00$ContentPlaceHolder1$pager_input"]=pageno,
		["ctl00_smMain_TSM"]=encodeURI(findOneText("input#ctl00_smMain_TSM:attr(value)",content))
	}	
	
	if table.getn(list)<1 then
		timeSleep(60)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	for k,v in pairs(list) do
		local tmpstr = ""
		local item = {}
		tmpstr=tmpstr..v

		tmpstr="<table><tr>"..tmpstr.."</tr></table>"
		item["title"]=findOneText("td:eq(1)",tmpstr)
		item["biddingCompany"]=findOneText("td:eq(2) span",tmpstr)
		item["status"]=findOneText("td:eq(3) span",tmpstr)

		local href=findOneText("td:eq(0)",tmpstr)
		item["href"]="http://b2bcoal.crp.net.cn/pub_v2/Tender/TenderItem.aspx?type=Inquiry&pre=0&TenderCode="..href
		item["publishtime"]=findOneText("td:eq(4)",tmpstr)
		item["endtime"]=findOneText("td:eq(5)",tmpstr)
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
	end
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local con = download(data["href"],{})
		data["sitename"]="华润煤业"
		
		data["channel"]="物资询价"
		data["detail"]=findOneText("#demo td",con)
		--去除空格
		data["detail"]=com.trim(data["detail"])
		data["contenthtml"]=findOneHtml("#demo",con)
		data["endtime"]=com.strToTimestamp(data["endtime"])
		data["l_np_publishtime"]=com.strToTimestamp(data["publishtime"])
		data["_d"]="comeintime"
		local checkAttr={"title","href","publishtime","detail","contenthtml"}
		local b,err=com.checkData(checkAttr,data)
		if b then
			return data
		else
			print("第",i,"次下载失败",err)
			timeSleep(60)--延时60秒再次请求
			if i==5 then
				saveErrLog(spiderCode,spiderName,data["href"],err)
				return nil
			end
		end
	end
end
--保存错误日志
--saveErrLog(spiderCode,spiderName,出错url,出错原因)
function encodeURI(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c) return string.format("%%%02X", string.byte(c)) end)
    return string.gsub(s, " ", "+")
end