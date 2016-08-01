--引用公用包
local com=require "res.util.comm"
local json=require "res.util.json"
--名称 网站名称_栏目
spiderName="贵州省工商行政管理局_新登记企业";
--代码 区域代码_网站代码_栏目代码
spiderCode="gz_gzsgsxzglj_xdjqy";
--是否下载3级页
spiderDownDetailPage=false;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=1;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-01-22 01:10:01";
--执行频率30分钟
spiderRunRate=1440;
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
spiderTargetChannelUrl="http://online.gzgs.gov.cn/frame/cjwt!searchXdjqy.shtml"
local trylistnum=0 --防止死循环
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	return os.date("%Y-%m-%d %H:%M:%S",os.time()-86400)
end

--下载分析列表页
local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true
--每天跑一次，没有判重
function downloadAndParseListPage(pageno)
	local page={}	
	local href=spiderTargetChannelUrl
	local content = download(href,{})
	while trylistnum<3 and (content=="" or content==nil)do
		trylistnum=trylistnum+1
		timeSleep(30)--30秒后重新获取列表
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	local tab = json.decode(content) --转化json为table
	for k,v in pairs(tab) do
		for i,j in pairs(v) do
			item={}
			item["area"]="GZ"
			item["enterprisename"]=j["qymc"]
			item["publishtime"]=j["clrq"]
			item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
			item["used"]="0"
			item["source"]=spiderCode
			
			table.insert(page,item)
		end
	end
	
	return page
end

