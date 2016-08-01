--引用公用包
local com=require "res.util.comm"
--名称
spiderName="中央采购网-测试脚本";
--代码
spiderCode="cn_cgw_test";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=2;
--上次下载时间
spiderLastDownloadTime="2015-01-01 01:10:01";
--执行频率30分钟
spiderRunRate=10;
--下载内容写入表名
spider2Collection="mytest";
--下载页面时使用的编码
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
--判重字段 空默认不判重，spiderCoverAttr="title" 按title判重覆盖
spiderCoverAttr="title"
--延时毫秒 基本延时(spiderSleepBase)+随机延时(spiderSleepRand)
spiderSleepBase=1000
spiderSleepRand=1000
--默认列表页第一页
spiderTargetChannelUrl="http://www.ccgp.gov.cn/zycg/zycgdt/index.htm"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	--transCode("unicode","内容")--转码，支持unicode,urlcode,decode64
	--timeSleep(5)--延时 
	--changeDownloader()--指定下载点
	local content = download("http://www.ccgp.gov.cn/zycg/zycgdt/",{})
	local tmp = findOneText("ul li em:eq(0)",content)
	local lastpushtime=com.parseDate(tmp,"yyyyMMddHHmm")
	--print("lastpushtime:"..lastpushtime);
	return lastpushtime
end

--下载分析列表页
function downloadAndParseListPage(pageno)
	local page={}		
	local href=""
	if pageno==1 then
	href="http://www.ccgp.gov.cn/zycg/zycgdt/index.htm"
	else
	href="http://www.ccgp.gov.cn/zycg/zycgdt/index_"..tostring(pageno-1)..".htm"
	end
	--print("href:"..href)
	local content = download(href,{})
	local list = findListHtml("ul#main_list_lt_list>li",content)
	--print(content)
	--根据实际情况：验证下载列表内容是否正确
	if table.getn(list)<1 then
		timeSleep(6)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	for k, v in pairs(list) do
		--分析列表，可加入自己分析列表是，需要的其他字段，最终会存储到新闻上	
		item={}
		item["href"]="a:eq(1):attr(href)"
		item["title"]="a:eq(1):attr(title)"
		item["publishtime"]="em:eq(0)"
		item["department"]="a:eq(0):attr(title)"
		item=findMap(item,v)
		item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMddHHmm")
		item["href"]="http://www.ccgp.gov.cn/zycg/zycgdt/"..item["href"]
		--如果栏目信息没有时分秒
		local b=findHasExit("mytest","{'href':'"..item["href"].."'}")
		if b then
			item["exit"]="true"
			--print(item["href"]);
			table.insert(page,item)	
			return page
		else
			table.insert(page,item)	
		end
	end
	print(pageno,"len",table.getn(page))
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local content = download(data["href"],{})
		--print(content)
		local ret={
			["sitename"]="标网",
			["channel"]="招标公告",
			["href"]=data["href"],
			["title"]=data["title"],
			["detail"]=findOneText("div.TRS_Editor",content),
			["contenthtml"]=findOneHtml("div.TRS_Editor",content),
			["publishtime"]=data["publishtime"],
			["l_np_publishtime"]=com.strToTimestamp(data["publishtime"]),
			["_d"]="comeintime"
		}
		local checkAttr={"title","href","publishtime","detail","contenthtml"}
		local b,err=com.checkData(checkAttr,ret)
		print(b,err)
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
