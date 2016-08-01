--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="中国海关政府采购网_中标公告";
--代码 区域代码_网站代码_栏目代码
spiderCode="a_zghgzfcgw_zhbgg";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=2;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-05-22 01:10:01";
--执行频率30分钟
spiderRunRate=60;
--下载内容写入表名 统一为：bidding，测试除外
spider2Collection="bidding";
--下载页面时使用的编码 根据页面编码填写,一般为utf8,gbk(gb2312也填gbk)
spiderPageEncoding="gbk";
--是否使用代理
spiderUserProxy=false;
--是否是安全协议
spiderUserHttps=false;
--下载详细页线程数
spiderThread=1
--存储模式 1 直接存储，2 调用消息总线 ...
spiderStoreMode=2
spiderStoreToMsgEvent=4002 --消息总线event
--消息传送判重字段统一按title判重覆盖
spiderCoverAttr="title"
--延时毫秒 基本延时(spiderSleepBase)+随机延时(spiderSleepRand)
spiderSleepBase=1000
spiderSleepRand=1000
--默认列表页第一页
spiderTargetChannelUrl="http://hgcg.customs.gov.cn/hgcg/cggg/004003/MoreInfo.aspx"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local tim=os.date("%Y-%m-%d %H:%M:%S",os.time())
	
	return tim
end

--下载分析列表页
local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true

local cks =""
local head={}
local param={}
local __VIEWSTATE = ""
local __VIEWSTATEGENERATOR = "97AC72C7"
local __EVENTTARGET = "MoreInfoList1$Pager"
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
		["Origin"]="ttp://hgcg.customs.gov.cn",
		["Upgrade-Insecure-Requests"]="1",
		["Host"]="hgcg.customs.gov.cn",
		["Referer"]="http://hgcg.customs.gov.cn/hgcg/cggg/004003/MoreInfo.aspx",
		["User-Agent"]="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36",
	}
	if pageno == 1 then
		param={
			["CategoryNum"]="004003"
		
		}
		content,cks = downloadAdv(spiderTargetChannelUrl,"get",param,head,cks)
	else
		param={
			["__EVENTTARGET"]=__EVENTTARGET,
			["__EVENTARGUMENT"]=pageno.."",
			["__VIEWSTATE"]=__VIEWSTATE,
			["__VIEWSTATEGENERATOR"]=__VIEWSTATEGENERATOR,
		}
	
		content,cks = downloadAdv(spiderTargetChannelUrl,"post",param,head,cks)
	end
	__VIEWSTATE = encodeURI(findOneText("input#__VIEWSTATE:attr(value)",content))
	__VIEWSTATEGENERATOR = encodeURI(findOneText("input#__VIEWSTATEGENERATOR:attr(value)",content))
	__EVENTVALIDATION = encodeURI(findOneText("input#__EVENTVALIDATION:attr(value)",content))


	local list = findListHtml("#MoreInfoList1_DataGrid1 tbody:eq(0) tr",content)
	
	if table.getn(list)<1 then
		timeSleep(60)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	for k,v in pairs(list) do
		
		local tmpstr = ""
		local item = {}
		tmpstr=tmpstr..v
		tmpstr="<table><tr>"..tmpstr.."</tr></table>"
		item["title"]=findOneText("td:eq(1) a",tmpstr)
		item["title"]=parseTitle(item["title"])
		item["publishtime"]=findOneText("td:eq(2)",tmpstr)
		item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
		item["href"]=findOneText('td:eq(1) a:attr(href)',tmpstr)
		item["href"]="http://hgcg.customs.gov.cn"..item["href"]
		
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
		data["site"]="中国海关政府采购网"
		data["channel"]="中标公告"
		data["toptype"]="结果"
		data["type"]="bid"
		data["area"]="A"
		data["spidercode"]=spiderCode
		data["detail"]=findOneText("#tblInfo",con)
		data["contenthtml"]=findOneHtml("#tblInfo",con)
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
--去除title中的多于字符
function parseTitle(s)
	local title=""
	local isExit=com.split(s,"】")[2]
		if isExit then
			title=string.sub(s,19,string.len(s))
		else
			title=s
		end
	return title
end