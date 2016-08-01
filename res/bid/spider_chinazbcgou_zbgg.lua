--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="中国招投标采购网_招标公告";
--代码 区域代码_网站代码_栏目代码
spiderCode="a_chinazbcgou_zbgg";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=1;
--上次下载时间 yyyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-05-10 01:10:01";
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
spiderTargetChannelUrl="http://www.chinazbcgou.com.cn/article.php?cat_id=11"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	
	local content = download("http://www.chinazbcgou.com.cn/article.php?cat_id=11",{})
	local tmp = findOneText(".xuxian tr:eq(1) td:eq(4)",content)
	
	
	local tmp=com.parseDate(tmp,"yyyyMMddHHmm")
	print("lastpushtime:"..tmp);
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
	local href="http://www.chinazbcgou.com.cn/article.php?cat_id=11"
	
	local content = download(href,{})

	local list = findListHtml(".xuxian tr",content)
	
	
	if table.getn(list)<1 then
		timeSleep(60)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	
	
	i=1
	for k, v in pairs(list) do
		--分析列表，可加入自己分析列表是，需要的其他字段，最终会存储到新闻上	
		if k%2==0 then
			--print(v)

			item={}
			item["href"]="td:eq(2) a:attr(href)"
			item["title"]="td:eq(2) a"
			item["publishtime"]="td:eq(4)"
			item["city"]="td:eq(3)"
			
			item=findMap(item,"<table><tr>"..v.."</tr></table>")
			
			item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMddHHmm")
			item["href"]="http://www.chinazbcgou.com.cn/"..item["href"]
			--如果栏目信息没有时分秒
			--print(item["title"])
			--print(item["href"])
		
		
			local b=findHasExit("huangweidong","{'href':'"..item["href"].."'}")
			--print(b)
			--os.exit()
			if b then
				return page
			else
				page[i]=item
				i=i+1	
			end
		else
			
		end
		
	end
	
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local content = download(data["href"],{})
		
		local ret={
			["sitename"]="中国采购招标网",
			["channel"]="招标公告",
			["href"]=data["href"],
			["title"]=data["title"],
			["city"]=data["city"],
			["detail"]=findOneText("p:eq(0)",content),
			["contenthtml"]=findOneHtml("p:eq(0)",content),
			["publishtime"]=data["publishtime"],
			["l_np_publishtime"]=com.strToTimestamp(data["publishtime"])
			
		}
			
		local checkAttr={"title","href","publishtime","detail","contenthtml"}
		local b,err=com.checkData(checkAttr,ret)
		if b then
			return ret
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
