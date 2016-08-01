--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="中国政府采购网_违法失信行为";
--代码 区域代码_网站代码_栏目代码
spiderCode="a_zgzfcgw_wfsxxw";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=1;
--上次下载时间 yyyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-05-22 01:10:01";
--执行频率30分钟
spiderRunRate=120;
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
spiderStoreMode=2
spiderStoreToMsgEvent=4002 --消息总线event
--消息传送判重字段统一按title判重覆盖
spiderCoverAttr="title"
--延时毫秒 基本延时(spiderSleepBase)+随机延时(spiderSleepRand)
spiderSleepBase=1000
spiderSleepRand=1000
--默认列表页第一页
spiderTargetChannelUrl="http://www.ccgp.gov.cn/cr/list"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download(spiderTargetChannelUrl,{})
	local tmp = findOneText("#tableInfo tbody:eq(0) tr:eq(1) td:eq(6)",content)
	
	if  tmp==nil and string.match(tmp,"(%d+)")==nil then
		--未成功获取最新时间
		timeSleep(60)--60秒之后再次下载列表
		return getLastPublishTime()
	else
		
	
		return com.parseDate(tmp,"yyyyMMdd")
	end
end

--下载分析列表页
local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true
function downloadAndParseListPage(pageno)
	local page={}		
	local href
	if pageno==1 then
		href=spiderTargetChannelUrl
	else
		href="http://www.ccgp.gov.cn/cr/list?gp="..tostring(pageno)
	end
	local content = download(href,{})
	local list = findListHtml("#tableInfo tbody:eq(0).trShow",content)
	
	if table.getn(list)<1 then
		timeSleep(60)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	local tmpstr = ""
	for k,v in pairs(list) do
		
		local item = {}
		tmpstr=tmpstr..v
		tmpstr="<table><tr>"..tmpstr.."</tr></table>"
		item["title"]=findOneText("td:eq(1) font",tmpstr)
		item["publishdept"]=findOneText("td:eq(7)",tmpstr)
		--截取href
		starthref,_=string.find(tmpstr,"2c")
		endhref,_=string.find(tmpstr,"&#",starthref)

		item["href"]=string.sub(tmpstr,starthref,endhref-1)
		item["href"]="http://www.ccgp.gov.cn/cr/list/detail?id="..item["href"]
		--print(item["href"])
		--os.exit()
		local href=findOneText("td:eq(0)",tmpstr)
		item["publishtime"]=findOneText("td:eq(6)",tmpstr)
		item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
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
		data["site"]="中国政府采购网"
		data["channel"]="违法失信行为"
		data["toptype"]="信用"
		data["subtype"]="违规"
		data["type"]="other"
		data["area"]="A"
		data["spidercode"]=spiderCode
		data["detail"]=findOneText(".table td",con)
		
		--去除空格
		data["detail"]=com.trim(data["detail"])
		data["contenthtml"]=findOneHtml(".table",con)
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
