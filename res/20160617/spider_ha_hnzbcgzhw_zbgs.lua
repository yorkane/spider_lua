--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="河南招标采购综合网_中标公示";
--代码 区域代码_网站代码_栏目代码
spiderCode="ha_hnzbcgzhw_abgs";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=5;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-06-23 17:35:01";
--执行频率30分钟
spiderRunRate=30;
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
spiderStoreMode=2
spiderStoreToMsgEvent=4002 --消息总线event
--消息传送判重字段统一按title判重覆盖
spiderCoverAttr="title"
--延时毫秒 基本延时(spiderSleepBase)+随机延时(spiderSleepRand)
spiderSleepBase=1000
spiderSleepRand=1000
--默认列表页第一页
local trylistnum=0 --防止死循环
spiderTargetChannelUrl="http://www.hnzbcg.cn/pb/Index.asp"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download(spiderTargetChannelUrl,{})
	local tmp = findOneText(".listbg:eq(3) font",content)
	-- print(tmp)
	-- os.exit()
	while trylistnum<5 and tmp==nil and string.match(tmp,"(%d+)")==nil do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return getLastPublishTime()
	end
	trylistnum=0
	return com.parseDate(tmp,"yyyyMMddHHmmss")
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
		href=spiderTargetChannelUrl.."?page="..tostring(pageno)
	end
	local content = download(href,{})
	local list = findListHtml("body > table:eq(1) tbody:eq(0) tr:eq(0) td:eq(2) table:eq(4) tbody:eq(0) tr",content)
	
	while trylistnum<5 and table.getn(list)<1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	for k,v in pairs(list) do
		if k%2==0 then
		else	
			local item = {}
			local tmpstr = ""
			tmpstr=tmpstr..v
			tmpstr="<table><tr>"..tmpstr.."</tr></table>"
			item["href"]=findOneText("td:eq(1) a:attr(href)",tmpstr)
			item["href"]="http://www.hnzbcg.cn"..item["href"]
			item["publishtime"]=findOneText("td:eq(3) font",tmpstr)
			item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
			
			if k==1 and pageno==1 then
				if lastRoundTagId=="" then
					lastRoundTagId=item["href"]
				else
					firstStart=false
				end	
				currRoundTagId=item["href"]
			end
			if lastRoundTagId==item["href"] and not firstStart then
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
		data["site"]="河南招标采购综合网"
		data["channel"]="中标公示"
		data["toptype"]="结果"
		data["type"]="bid"
		data["spidercode"]=spiderCode
		data["title"]=findOneText(".main_ArticleTitle",con)
		data["detail"]=findOneText("#fontzoom",con)
		data["contenthtml"]=findOneHtml("#fontzoom",con)
		data["l_np_publishtime"]=com.strToTimestamp(data["publishtime"])
		data["_d"]="comeintime"
		data["area"]="河南"
		-- print(data["title"],data["publishtime"],data["detail"])
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
