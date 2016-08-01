--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="山东省工商行政管理局_办理业务查询";
--代码 区域代码_网站代码_栏目代码
spiderCode="sd_sdsgsxzglj_blywcx";
--是否下载3级页
spiderDownDetailPage=false;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=100;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-01-22 01:10:01";
--执行频率30分钟
spiderRunRate=1440;
--下载内容写入表名 统一为：bidding，测试除外
spider2Collection="entnames";
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
spiderTargetChannelUrl="http://218.57.139.23:8090/iaicweb/xxcx/doqylccx.jsp"
local trylistnum=0 --防止死循环
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	return os.date("%Y-%m-%d %H:%M:%S",os.time())
	
end
--每天跑一次，没有判重
--下载分析列表页
local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true
local status=""
function downloadAndParseListPage(pageno)
	local page={}	
	local href
	if pageno==1 then
		href=spiderTargetChannelUrl
	else
		href=spiderTargetChannelUrl.."?start="..tostring((pageno-1)*10)
	end
	local content = download(href,{})
	local list = findListHtml("tr[class] ~ tr",content)
	
	while trylistnum<3 and table.getn(list)<=2 do
		trylistnum=trylistnum+1
		timeSleep(30)--30秒后重新获取列表
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	local tmpstr = ""
	local listSize=table.getn(list)
	for k,v in pairs(list) do
		if k==listSize then
		else
			local item = {}
			tmpstr=tmpstr..v
			tmpstr="<table><tr>"..tmpstr.."</tr></table>"
			item["area"]="SD"
			item["enterprisename"]=findOneText("td:eq(1)",tmpstr)
			item["publishtime"]=findOneText("td:eq(2)",tmpstr)
			item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
			status=findOneText("td:eq(3)",tmpstr)
			item["used"]="0"
			item["source"]=spiderCode
			tmpstr=""
			if status=="受理" then
				table.insert(page,item)
			end
		end
	end
	
	return page
end

