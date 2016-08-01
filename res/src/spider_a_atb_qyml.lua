--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="阿土伯_企业名录";
--代码 区域代码_网站代码_栏目代码
spiderCode="a_atb_qyml";
--是否下载3级页
spiderDownDetailPage=false;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=1;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2015-01-01 01:10:01";
--执行频率30分钟
spiderRunRate=0;
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
spiderStoreMode=1
spiderStoreToMsgEvent=4002 --消息总线event
--消息传送判重字段统一按title判重覆盖
spiderCoverAttr="title"
--延时毫秒 基本延时(spiderSleepBase)+随机延时(spiderSleepRand)
spiderSleepBase=1000
spiderSleepRand=1000
--默认列表页第一页
spiderTargetChannelUrl="http://www.atobo.com.cn/Companys/s-p3-s872"
local area="天津";
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
local f=io.open("urlAreaR.txt","r")
fw=io.open("天津.txt","a")
 --用于记录下载到哪了
function getLastPublishTime()
	spiderTargetChannelUrl=f:read() --读取URL
	area=f:read() --读取area
	spiderMaxPage=tonumber(f:read()) --读取最大下载页
	if spiderTargetChannelUrl~=nil and area~=nil then
		fw=io.open(area..".txt","a")
		print(spiderTargetChannelUrl,area,spiderMaxPage) --输出"!"
		return os.date("%Y-%m-%d %H:%M:%S",os.time())
	else
		--fw:close()
		f:close()
		os.exit()
	end
end

--下载分析列表页
function downloadAndParseListPage(pageno)
	local page={}	
	local href
	if pageno==1 then
		href=spiderTargetChannelUrl
	else
		href=spiderTargetChannelUrl.."-y"..tostring(pageno)
	end
	local content = download(href,{})
	
	local list = findListHtml(".product_box",content)
	--print("list:"..table.getn(list))
	--os.exit()
	if table.getn(list)<1 then
		timeSleep(60)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	--print("pageno:",pageno)
	for k,v in pairs(list) do
			item={}
			item["title"]=findOneText(".pp_name",v)
			print(item["title"])
			fw:write(item["title"].."\n")
	end
	if pageno==spiderMaxPage then
		fw:close()
	end
	return page
end
