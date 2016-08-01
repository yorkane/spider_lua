--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="甘肃企业登记网_公示数据查询";
--代码 区域代码_网站代码_栏目代码
spiderCode="gs_gsqydjw_gssjcx";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=800;
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
spiderTargetChannelUrl="http://qydj.gsaic.gov.cn/busquery/search.do?sid=1191239017781"
local trylistnum=0 --防止死循环
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
local contain={} --容器，判断重复的数据
local count=1
function getLastPublishTime()
	if count%5==0 then
		contain={} --每循环5次清空一下容器
	end
	count=count+1 
	return os.date("%Y-%m-%d %H:%M:%S",os.time()-604800)
	
end

--下载分析列表页
local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true

--每天跑一次，没有判重
function downloadAndParseListPage(pageno)
	local page={}	
	local href
	if pageno==1 then
		href=spiderTargetChannelUrl
	else
		href=spiderTargetChannelUrl.."&page="..tostring(pageno)
	end
	local content = download(href,{})
	local list = findListHtml(".result_Font",content)
	
	while trylistnum<5 and table.getn(list)<1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	local tmpstr --格式化enterprisename
	for k,v in pairs(list) do
		item={}
		item["href"]=findOneText("a:attr(href)",v)
		table.insert(page,item)	
	end
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
		local con = download(data["href"],{})
		
		data["area"]="GS"
		data["enterprisename"]=findOneText(".gsContentTDRight:eq(6)",con)
		data["publishtime"]=findOneText(".gsContentTDRight:eq(1)",con)
		data["publishtime"]=com.parseDate(data["publishtime"],"yyyyMMdd")
		data["used"]="0"
		data["source"]=spiderCode

		while trylistnum<5 and data["enterprisename"]==nil do
			trylistnum=trylistnum+1
			timeSleep(120)--两分钟后重新获取列表
			saveErrLog(spiderCode,spiderName,data["href"],"enterprisename is nil")
			return downloadDetailPage(data)
		end
		trylistnum=0
		--是否是个体户
		local isPersonal=findOneText(".gsContentTDRight:eq(9)",con)
		--去除数字
		local number=string.match(data["enterprisename"],"%d+")
		if number==nil and isPersonal~="个体户" then
			if isHave(contain,data["enterprisename"],"enterprisename") then
			else
				table.insert(contain,data)
				return data
			end
		else

		end
		
end


function isHave(contain,page,str)
	for k,v in pairs(contain) do
		if v[str]==page then
			return true
		end
	end
	return false
end