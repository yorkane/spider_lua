--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="河南省政府采购网_采购信息";
--代码 区域代码_网站代码_栏目代码
spiderCode="hn_hngp_cgxx";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=2;
--上次下载时间 yyyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-05-20 01:10:01";
--执行频率30分钟
spiderRunRate=30;
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
spiderTargetChannelUrl="http://www.hngp.gov.cn/henan/ggcx?appCode=H60&channelCode=0101"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download(spiderTargetChannelUrl,{})
	local tmp = findOneText(".List2 ul:eq(0) li:eq(0) span:eq(0)",content)
	if tmp==nil and string.match(tmp,"(%d)")==nil then
		timeSleep(60)--延时
		return getLastPublishTime()
	else
		--print("publishtime----"..com.parseDate(tmp,"yyyyMMdd"))
		return com.parseDate(tmp,"yyyyMMdd")
	end
end

--下载分析列表页
function downloadAndParseListPage(pageno)
	local page={}		
	local href=""
	if pageno==1 then
		href=spiderTargetChannelUrl
	else
		href= spiderTargetChannelUrl.."&bz=0&pageSize=10&pageNo="..pageno
	end
	
	local content = download(href,{})
	local list = findListHtml(".List2 ul:eq(0) li",content)
	--print(content)
	--根据实际情况：验证下载列表内容是否正确
	if table.getn(list)<1 then
		timeSleep(6)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	for k, v in pairs(list) do
		--分析列表，可加入自己分析列表是，需要的其他字段，最终会存储到新闻上	
		item={}
		
		item["title"]=findOneText("a:eq(0)",v)
		item["href"]=findOneText("a:attr(href)",v)
		item["href"]="http://www.hngp.gov.cn"..item["href"]
		item["publishtime"]=findOneText("span:eq(0)",v)
		item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
		--print(item["title"])
		--print(item["href"])
		--os.exit()

		--如果栏目信息没有时分秒
		local b=findHasExit("huangweidong","{'href':'"..item["href"].."'}")
		if b then
			return page
		else
			table.insert(page, 1, item)
		end
	end
	
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local content = download(data["href"],{})
		local start,index=string.find(content,"webfile")
		local index,ends=string.find(content,"htm\"")
		local contenturl=string.sub(content,start,ends)
			contenturl="http://www.hngp.gov.cn/"..string.sub(contenturl,0,string.len(contenturl)-1)
		--print(contenturl)
		--os.exit()
		local ret={
			["sitename"]="河南省政府采购网",
			["channel"]="采购信息",
			["href"]=data["href"],
			["title"]=data["title"],
			["publishcompany"]=findOneText(".Blue:eq(0)",content),
			["detail"]=findOneText("span",download(contenturl,{})),
			["contenthtml"]=download(contenturl,{}),
			["publishtime"]=findOneText(".Blue:eq(2)",content),
			["l_np_publishtime"]=com.strToTimestamp(data["publishtime"]),
			["_d"]="comeintime"
		}
		--print(ret["href"])
		--print(ret["detail"])
		--print(ret["publishtime"])
		--os.exit()

		local checkAttr={"title","href","publishtime"}
		local b,err=com.checkData(checkAttr,ret)
		if b then
			return ret
		else
			print("第",i,"次下载失败")
			timeSleep(60)--延时60秒再次请求
			if i==5 then
				saveErrLog(spiderCode,spiderName,ret["href"],err)
			end
		end
	end
end
--保存错误日志
--saveErrLog(spiderCode,spiderName,出错url,出错原因)
