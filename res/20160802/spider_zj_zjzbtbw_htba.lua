--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="浙江招标投标网_合同备案";
--代码 区域代码_网站代码_栏目代码
spiderCode="zj_zjzbtbw_htba";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=5;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-04-22 01:10:01";
--执行频率30分钟
spiderRunRate=30;
--下载内容写入表名 统一为：bidding，测试除外
spider2Collection="bidding";
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
spiderTargetChannelUrl="http://www.zjbid.cn/zjwz/template/default/GGInfo.aspx?CategoryNum=037"
local trylistnum=0 --防止死循环
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download(spiderTargetChannelUrl,{})
	local tmp = findOneText("#MoreInfoListGG_DataGrid1 tr:eq(0) td:eq(2)",content)
	while trylistnum<5 and tmp==nil and string.match(tmp,"(%d+)")==nil do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return getLastPublishTime()
	end
	trylistnum=0
	
	return com.parseDate(tmp,"yyyyMMdd")
end

--下载分析列表页
local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true

local cks =""
local head={}
local param={}
local __VIEWSTATE=""
local __EVENTTARGET = "MoreInfoListGG$Pager"
local __EVENTARGUMENT = ""
local content = ""

function downloadAndParseListPage(pageno)
	local page={}	
	head={
		["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
		["Accept-Encoding"]="deflate",
		["Accept-Language"]="zh-CN,zh;q=0.8",
		["Connection"]="keep-alive",
		["Content-Type"]="application/x-www-form-urlencoded",
		["Cookie"]=cks,
		["Origin"]="http://www.zjbid.cn",
		["Upgrade-Insecure-Requests"]="1",
		["Host"]="hgcg.customs.gov.cn",
		["Referer"]="http://www.zjbid.cn/zjwz/template/default/GGInfo.aspx?CategoryNum=037",
		["User-Agent"]="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36",
	}
	if pageno == 1 then
		
		content,cks = downloadAdv(spiderTargetChannelUrl,"get",{},{},"")
	else
		param={
			["__EVENTTARGET"]=__EVENTTARGET,
			["__EVENTARGUMENT"]=tostring(pageno),
			["__VIEWSTATE"]=__VIEWSTATE,
			
		}
	
		content,cks = downloadAdv(spiderTargetChannelUrl,"post",param,head,cks)
	end
	__VIEWSTATE = encodeURI(findOneText("#__VIEWSTATE:attr(value)",content))
	local list = findListHtml("#MoreInfoListGG_DataGrid1 tbody:eq(0) tr",content)
	while trylistnum<5 and table.getn(list)<1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	local tmpstr = ""
	for k,v in pairs(list) do
		local item = {}
		tmpstr=tmpstr..v
		tmpstr="<table><tr>"..tmpstr.."</tr></table>"
		item["title"]=findOneText("td:eq(1) a:attr(title)",tmpstr)
		item["publishtime"]=findOneText("td:eq(2)",tmpstr)
		item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
		item["href"]=findOneText('td:eq(1) a:attr(href)',tmpstr)
		item["href"]="http://www.zjbid.cn"..item["href"]
		
		tmpstr=""
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
	for i=1,5 do 	--5次下载任务不成功，退出
		local con = download(data["href"],{})
		data["site"]="浙江招标投标网"
		data["channel"]="合同备案"
		data["toptype"]="信用"
		data["subtype"]="合同"
		data["type"]="other"
		data["area"]="浙江"
		data["spidercode"]=spiderCode
		data["detail"]=findOneText("#_Sheet1",con)
		data["contenthtml"]=findOneHtml("#_Sheet1",con)
		--内容模板不统一
		if data["detail"]==nil or data["detail"]=="" then
			data["detail"]=findOneText("style","#TDContent",con)
			data["contenthtml"]=findOneHtml("style","#TDContent",con)
		end
		if data["detail"]==nil or data["detail"]=="" then
			data["detail"]=findOneText("style",".MsoNormalTable",con)
			data["contenthtml"]=findOneHtml("style",".MsoNormalTable",con)
		end
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
