--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="广东省政府采购网_更正公告";
--代码 区域代码_网站代码_栏目代码
spiderCode="gd_gdszfcgw_gzgg";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=10;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-01-22 01:10:01";
--执行频率30分钟
spiderRunRate=30;
--下载内容写入表名 统一为：bidding，测试除外
spider2Collection="bidding";
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
spiderTargetChannelUrl="http://www.gdgpo.gov.cn/queryMoreInfoList.do?channelCode=0006&sitewebId=-1"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download(spiderTargetChannelUrl,{})
	local tmp = findOneText(".m_m_c_list li:eq(2) em:eq(0)",content)
	while trylistnum<5 and tmp==nil and string.match(tmp,"(%d+)")==nil do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return getLastPublishTime()
	end
	trylistnum=0
	return com.parseDate(tmp,"yyyyMMddHHmm")
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
		href="http://www.gdgpo.gov.cn/queryMoreInfoList.do?channelCode=0006&pageSize15&pointPageIndexId=9&sitewebId=-1&pageIndex="..tostring(pageno)
	end
	local content = download(href,{})
	local list = findListHtml(".m_m_c_list li",content)
	while trylistnum<5 and table.getn(list)<1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	for k,v in pairs(list) do
		if (k==1 or k==2) and pageno==1 then
		else
			local item = {}
			item["title"]=findOneText("a:eq(1):attr(title)",v)
			item["city"]=findOneText("a:eq(0)",v)
			item["href"]=findOneText("a:eq(1):attr(href)",v)
			item["href"]="http://www.gdgpo.gov.cn"..item["href"]
			item["publishtime"]=findOneText("em",v)
			item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMddHHmm")
			
			if k==3 and pageno==1 then
				if lastRoundTagId=="" then
					lastRoundTagId=item["href"]
				else
					firstStart=false
				end	
				currRoundTagId=item["href"]
			end
			if lastRoundTagId==item["href"] and not firstStart 
				then
				lastRoundTagId=currRoundTagId	
				item["exit"]="true"
			end
			table.insert(page,item)
		end
		
	end
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local con = download(data["href"],{})
		data["site"]="广东省政府采购网"
		data["channel"]="更正公告"
		data["toptype"]="招标"
		data["subtype"]="变更"
		data["type"]="tender"
		data["spidercode"]=spiderCode
		data["detail"]=findOneText(".zw_c_c_cont",con)
		data["contenthtml"]=findOneHtml(".zw_c_c_cont",con)
		data["l_np_publishtime"]=com.strToTimestamp(data["publishtime"])
		data["_d"]="comeintime"
		data["area"]="广东"
		local checkAttr={"title","href","publishtime","detail","contenthtml","spidercode","site","channel","type"}
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