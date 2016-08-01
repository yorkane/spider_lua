--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="搜狐_新闻栏目";
--代码 区域代码_网站代码_栏目代码
spiderCode="a_souhu_gnyw";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=1;
--上次下载时间 yyyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-05-23 01:10:01";
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
spiderTargetChannelUrl="http://www.ccgp.gov.cn/zycg/zycgdt/index.htm"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	
	local content = download("http://news.sohu.com/shehuixinwen.shtml",{})
	local tmp = findOneText(".time:eq(0)",content)
	--print(tmp)
	local lastpushtime=com.parseDate(tmp,"yyyyMMddHHmm")
	--print("lastpushtime:"..lastpushtime);
	--os.exit()
	return lastpushtime
end

--下载分析列表页
function downloadAndParseListPage(pageno)
	local page={}		
	
	local content = download("http://news.sohu.com/shehuixinwen.shtml",{})
	local list = findListHtml(".article-list",content)
	
	
	for k,v in pairs(list) do
		local item={}
		item["title"]="div h3 a:eq(1)"
		item["href"]='div h3 a:eq(1):attr(href)'
		item["pushtime"]='div:eq(2) div[class="time"]:eq(0)'
		
		item=findMap(item,v)
		item["pushtime"]=com.parseDate(item["pushtime"],"yyyyMMddHHmm")
		page[k]=item;
		--print(pushtime)
		
	end
	for k,v in pairs(page) do
		--print(v["title"].." "..v["href"].." "..v["pushtime"])
	end
	--os.exit()
	return page
end
function downloadDetailPage(data)
		--5次下载任务不成功，退出
		local page={}
		local content = download(data["href"],{})
		--print(content)
		
		page["title"]=data["title"]
		page["href"]=data["href"]	
		page["contenthtml"]=findOneText("#contentText div p",content)
		
		
		--print(page["title"].." "..page["contenthtml"])
		
		
		local mes={
					["sitename"]="搜狐",
					["channel"]="搜狐新闻",
					
					["href"]=data["href"],
					["title"]=data["title"],
					["detail"]=findOneText("#contentText div p",content),
					["contenthtml"]=findOneHtml("#contentText div",content),
					["pushtime"]=data["pushtime"]
					
				}
		return mes;
		
		
			--os.exit()
			
			
			
			
			
			
			
	
	
	 
end

