--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="中国税务政府采购网_其它公告";
--代码 区域代码_网站代码_栏目代码
spiderCode="a_zgswzfcgw_qtgg";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=2;
--上次下载时间 yyyy-MM-dd HH:mm:ss
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
spiderTargetChannelUrl="http://www.ctaxccgp.com.cn/swcg/qtgg/"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download(spiderTargetChannelUrl,{})
	local tmp = findOneText("table:eq(4) tbody:eq(0) tr:eq(0) td:eq(1) a",content)
	--截取时间
	startIndex,_=string.find(tmp,"%[")
	endIndex,_=string.find(tmp,"%]")
	tmp=string.sub(tmp,startIndex+1,endIndex-1)

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
		href="http://www.ctaxccgp.com.cn/swcg/qtgg/index_"..tostring(pageno-1)..".htm"
	end	

	local content = download(href,{})
	local list = findListHtml("table:eq(4) tbody:eq(0) tr",content)
		
	if table.getn(list)<1 then
		timeSleep(60)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	local tmpstr = ""
	for k,v in pairs(list) do
		
		local item = {}
		tmpstr=tmpstr..v
		tmpstr="<table><tr>"..tmpstr.."</tr></table>"
		item["title"]=findOneText("td:eq(1) a",tmpstr)
		--截取时间
		startIndex,_=string.find(item["title"],"%[")
		endIndex,_=string.find(item["title"],"%]")
		tmp=string.sub(item["title"],startIndex+1,endIndex-1)
		item["publishtime"]=tmp
		item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
		--格式化标题
		local index,_=string.find(item["title"],"%[")
		item["title"]=string.sub(item["title"],1,index-1)
		
		item["href"]=findOneText('td:eq(1) a:attr(href)',tmpstr)
		--去除连接中的.
		item["href"]=string.sub(item["href"],2,string.len(item["href"]))
		item["href"]="http://www.ctaxccgp.com.cn/swcg/qtgg"..item["href"]
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
		data["site"]="中国税务政府采购网"
		data["channel"]="其它公告"
		data["toptype"]="结果"
		data["type"]="other"
		data["area"]="A"
		data["spidercode"]=spiderCode
		data["detail"]=findOneText("style",".dhfour:eq(1)",con)
		data["contenthtml"]=findOneHtml(".dhfour:eq(1)",con)
		
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
