--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="中国法律法规信息库_宪法相关法";
--代码 区域代码_网站代码_栏目代码
spiderCode="a_zgflfgxxk";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=132;
--上次下载时间 yyyy-MM-dd HH:mm:ss
spiderLastDownloadTime="1980-05-22 01:10:01";
--执行频率30分钟
spiderRunRate=120;
--下载内容写入表名 统一为：bidding，测试除外
spider2Collection="chinalaws2";
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
spiderTargetChannelUrl="http://law.npc.gov.cn/FLFG/getAllList.action?SFYX=%E6%9C%89%E6%95%88&zlsxid=06&bmflid=&zdjg=3&txtid=&resultSearch=false&lastStrWhere=&keyword=&pagesize=20"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download(spiderTargetChannelUrl,{})
	local tmp = findOneText(".table tbody:eq(0) tr:eq(2) td:eq(2)",content)
	--print("******"..tmp)
	--os.exit()
	if  tmp==nil and string.match(tmp,"(%d+)")==nil then
		--未成功获取最新时间
		timeSleep(60)--60秒之后再次下载列表
		return getLastPublishTime()
	else
		return com.parseDate(tmp,"yyyyMMdd")
	end
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
		href=spiderTargetChannelUrl.."&curPage="..tostring(pageno)
	end
	local content = download(href,{})
	local list = findListHtml(".table tbody:eq(0) tr",content)
	--print(table.getn(list))
	--os.exit()
	if table.getn(list)<1 then
		timeSleep(60)--60秒之后再次下载列表
		return downloadAndParseListPage(pageno)
	end
	for k,v in pairs(list) do
		if k==1 or k==2 or k==table.getn(list) then
		else
			local tmpstr = ""
			local item = {}
			local one=0
			local two=0
			tmpstr=tmpstr..v
			tmpstr="<table><tr>"..tmpstr.."</tr></table>"
			item["title"]=findOneText("td:eq(1) a",tmpstr)
			item["title"]=com.trim(item["title"])
			local tmphref=findOneText("td:eq(1) a:attr(href)",tmpstr)
			
			local _,ends=string.find(tmphref,"%('")
			local start,_=string.find(tmphref,"',")
			
			if ends~=nil and start~=nil then
				one=string.sub(tmphref,ends+1,start-1)
				_,ends=string.find(tmphref,"','','")
				start,_=string.find(tmphref,"'%)")
				two=string.sub(tmphref,ends+1,start-1)
			end
			item["href"]="http://law.npc.gov.cn/FLFG/flfgByID.action?flfgID="..tostring(one).."&keyword=&zlsxid="..tostring(two)
			
			item["publishtime"]=findOneText("td:eq(2)",tmpstr)
			item["publishtime"]=com.trim(item["publishtime"])
			item["currenttime"]=os.date("%Y-%m-%d %H:%M:%S",os.time())
			
			if k==3 and pageno==1 then
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
			if item["title"]=="" then
			else
				table.insert(page,item)	
			end
		end
	end
	-- for k,v in pairs(page) do
	-- 	print(v["href"])
	-- end
	-- os.exit()
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local con = download(data["href"],{})
		data["site"]="中国法律法规信息库"
		data["detail"]=findOneText("#content table:eq(0) tbody:eq(0) tr",con)

		data["contenthtml"]=findOneHtml("#content",con)

		data["type"]=findOneText("#content table:eq(1) tr:eq(0) td:eq(1)",con)
		data["type"]=com.trim(data["type"])

		data["publishdept"]=findOneText("#content table:eq(1) tr:eq(1) td:eq(1)",con)
		data["publishdept"]=com.trim(data["publishdept"])

		data["legalcategory"]=findOneText("#content table:eq(1) tr:eq(0) td:eq(3)",con)
		data["legalcategory"]=com.trim(data["legalcategory"])

		data["issuefile"]=findOneText("#content table:eq(1) tr:eq(2) td:eq(1)",con)
		data["issuefile"]=com.trim(data["issuefile"])

		data["execdate"]=findOneText("#content table:eq(1) tr:eq(3) td:eq(3)",con)
		data["execdate"]=com.trim(data["execdate"])

		data["l_np_publishtime"]=com.strToTimestamp(data["publishtime"])
		data["_d"]="comeintime"
		local checkAttr={"title","href","publishtime","detail","contenthtml"}
		local b,err=com.checkData(checkAttr,data)
		if b then
			return data
		else
			print("第",i,"次下载失败",err)
			--timeSleep(60)--延时60秒再次请求
			if i==5 then
				saveErrLog(spiderCode,spiderName,data["href"],err)
				return nil
			end
		end
	end
end
--保存错误日志
--saveErrLog(spiderCode,spiderName,出错url,出错原因)
