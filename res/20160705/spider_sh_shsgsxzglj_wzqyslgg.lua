--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="上海市工商行政管理局_外资企业设立公告";
--代码 区域代码_网站代码_栏目代码
spiderCode="sh_shsgsxzglj_wzqyslgg";
--是否下载3级页
spiderDownDetailPage=false;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=11;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-01-22 01:10:01";
--执行频率30分钟
spiderRunRate=120;
--下载内容写入表名 统一为：bidding，测试除外
spider2Collection="entnames";
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
local trylistnum=0 --防止死循环
spiderTargetChannelUrl="http://www.sgs.gov.cn/shaic/dengjiBulletin!toWzsl.action?regorgan=000000"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download(spiderTargetChannelUrl,{})
	local tmp = findOneText(".tgList tr:eq(1) td:eq(2)",content)
	while trylistnum<5 and tmp==nil and string.match(tmp,"(%d+)")==nil do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return getLastPublishTime()
	end
	trylistnum=0
	--print(com.parseDate(tmp,"yyyyMMdd"))
	return com.parseDate(tmp,"yyyyMMdd")
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
		href="http://www.sgs.gov.cn/shaic/dengjiBulletin!toWzsl.action".."?regorgan=000000&pageno="..tostring(pageno)
	end
	local content = download(href,{})
	local list = findListHtml(".tgList tr",content)

	while trylistnum<5 and table.getn(list)<=1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return downloadAndParseListPage(pageno)
		
	end
	--循环5次还是没有数据就退出
	if trylistnum>=5 then
		trylistnum=0
		return 
	end

	trylistnum=0
	local tmpstr = ""
	for k,v in pairs(list) do
		if k==1 then
		else
			local item = {}
			tmpstr=tmpstr..v
			tmpstr="<table><tr>"..tmpstr.."</tr></table>"
			item["area"]="SH"
			item["enterprisename"]=findOneText("td:eq(0)",tmpstr)
			item["publishtime"]=findOneText("td:eq(2)",tmpstr)
			item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
			item["used"]="0"
			item["source"]=spiderCode
			
			tmpstr=""
			if k==2 and pageno==1 then
				if lastRoundTagId=="" then
					lastRoundTagId=item["enterprisename"]
				else
					firstStart=false
				end	
				currRoundTagId=item["enterprisename"]
			end
			if lastRoundTagId==item["enterprisename"] and not firstStart then
				lastRoundTagId=currRoundTagId	
				item["exit"]="true"
			end

			table.insert(page,item)
		end
	end
	return page
end

