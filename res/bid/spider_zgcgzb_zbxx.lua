--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="中国采购招标网_招标信息";
--代码 区域代码_网站代码_栏目代码
spiderCode="a_zgcgzb_zbxx";
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
	
	local content = download("http://www.chinabidding.cc/info.php?cat_id=11",{})
	local tmp = findOneText('table[class="xuxian"] td:eq(4)',content)
	--print(tmp)
	--os.exit()
	local lastpushtime=com.parseDate(tmp,"yyyyMMddHHmm")
	--print("lastpushtime:"..lastpushtime);
	--os.exit()
	return lastpushtime
	
end

--下载分析列表页
function downloadAndParseListPage(pageno)
	local page={}		
	
	local content = download("http://www.chinabidding.cc/info.php?cat_id=11",{})
	local list = findListHtml('table[class="xuxian"]',content)
	for k,v in pairs(list) do
		
		v="<table>"..v.."</table>"
		--print(v)
		local item={}
		item["title"]='a[class="ljhui"]'
		item["href"]='a[class="ljhui"]:attr(href)'
		item["publishtime"]='td:eq(4)'
		
			
		item=findMap(item,v)
		item["href"]="http://www.chinabidding.cc/"..item["href"]	
		--print("123..."..item["href"])
		--os.exit()
		
		page[k]=item;
	end
	for k,v in pairs(page) do
			--print(v["title"].." "..v["href"].." "..v["pushtime"])
		end
		--os.exit()
	
	return page
end

function downloadDetailPage(data)
		local page={}
		local content = download(data["href"],{})
		--[[
		--print(content)
		
		page["title"]=data["title"]
		page["href"]=data["href"]	
		
		page["contenthtml"]=findOneText("body > table:eq(2) tbody:eq(0) tr:eq(1) td:eq(14) table:eq(0) tbody:eq(0) tr:eq(0) td:eq(0)",content)
		--print("----------------------")
		--print(page["contenthtml"])
		--os.exit()
		
		print(page["title"].." "..page["contenthtml"])
		os.exit()
		]]
		--print(data["publishtime"])
		--os.exit()
		local mes={
					
					["sitename"]="中国采购招标网",
					["channel"]="招标公告",
					["href"]=data["href"],
					["title"]=data["title"],
					["detail"]=findOneText("body > table:eq(2) tbody:eq(0) tr:eq(1) td:eq(14) table:eq(0) tbody:eq(0) tr:eq(0) td:eq(0)",content),
					["contenthtml"]=findOneHtml("body > table:eq(2) tbody:eq(0) tr:eq(1) td:eq(14) table:eq(0) tbody:eq(0) tr:eq(0) td:eq(0)",content),
					["pushtime"]=data["pushtime"],
					["l_np_publishtime"]=com.strToTimestamp(data["publishtime"]),
					
				}
				
		return mes;
		
		
			--os.exit()
		
	 
end

