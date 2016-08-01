--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="北京招标网_招标公告";
--代码 区域代码_网站代码_栏目代码
spiderCode="BJ_bidchance_zbgg";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=2;
--上次下载时间 yyyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-05-22 01:10:01";
--执行频率30分钟
spiderRunRate=30;
--下载内容写入表名 统一为：bidding，测试除外
spider2Collection="huangweidong";
--下载页面时使用的编码 根据页面编码填写,一般为utf8,gbk(gb2312也填gbk)
spiderPageEncoding="gbk";
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
spiderTargetChannelUrl="http://beijing.bidchance.com/tsp_110000_0_02_0_1.html"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download("http://beijing.bidchance.com/tsp_110000_0_02_0_1.html",{})
		--print(content)
	local tmp = findOneHtml("#lie tbody:eq(0) tr:eq(0) td:eq(3)",content)
	--print(tmp)
	--os.exit()
	
	if  tmp==nil and string.match(tmp,"(%d+)")==nil then
		--未成功获取最新时间
		timeSleep(60)--60秒之后再次下载列表
		return getLastPublishTime()
	else
		return com.parseDate(tmp,"yyyyMMdd")
	end
end

--下载分析列表页
function downloadAndParseListPage(pageno)
	local page={}		
	local href="http://beijing.bidchance.com/tsp_110000_0_02_0_"..pageno..".html"
	--print("href:"..href)
	--os.exit()
	
	
	local str="abcd,aas,csfs,cda,dsaf"
	local strs={}
	strs=com.split(str,",")
	for k,v in pairs(strs) do
		print(v)
	end
	
	
	os.exit()
	
	local content = download(href,{})
	local list = findListHtml("#lie tbody:eq(0) tr",content)

	if table.getn(list)<1 then
		timeSleep(60)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	
	for k,v in pairs(list) do
		item={}
		local temp=""
		temp="<table><br>"..v.."</table><br>"
		--os.exit()
		item["title"]=findOneText("td:eq(1) a",temp)
		item["href"]=findOneText("td:eq(1) a:attr(href)",temp)
		item["publishtime"]=findOneText("td:eq(3)",temp)
		item["city"]=findOneText("td:eq(2) a",temp)
		
		--print(item["title"])
		--print(item["href"])

		--os.exit()
		local b=findHasExit("zhangjinkun","{'href':'"..item["href"].."'}")
		if b then
			return page
		else
			table.insert(page, 1, item)	
		end
		
	end
	--os.exit()
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local con = download(data["href"],{})
			
		data["sitename"]="北京招标网"
		data["channel"]="招标公告"
		data["detail"]=findOneHtml("#infohtmlcon",con)
		data["contenthtml"]=findOneHtml("#infohtmlcon",con)
		--print(data["detail"])
			
		--os.exit()
		
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
