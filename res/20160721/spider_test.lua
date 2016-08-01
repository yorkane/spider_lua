--引用公用包
local com=require "res.util.comm"
local json=require "res.util.json"
--名称 网站名称_栏目
spiderName="浙江政务服务网_办件公告";
--代码 区域代码_网站代码_栏目代码
spiderCode="zj_zjzffww_bjgg";
--是否下载3级页
spiderDownDetailPage=false;
--开始下载页
spiderStartPage=1;
--最大下载页(有多少个栏目最大页就设置成多少)
spiderMaxPage=2;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-01-22 01:10:01";
--执行频率30分钟
spiderRunRate=1;
--下载内容写入表名 统一为：bidding，测试除外
spider2Collection="huangweidong";
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
spiderTargetChannelUrl="http://www.zjzwfw.gov.cn/zjzw/see/notice/list.do?webId=2"
--防止死循环
local trylistnum=0 
--存放URL
local urlTable={}
--记录栏目数目
local count=1
--栏目总数
local urlTableSum
--判重
local isExit=false
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	count=1
	urlTable=geturlTable("zjzffww.json","r")
	urlTableSum=table.getn(urlTable)
	return os.date("%Y-%m-%d %H:%M:%S",os.time()-604800)
	
end

--下载分析列表页

function downloadAndParseListPage(pageno)

	if urlTableSum<pageno then
		saveErrLog(spiderCode,spiderName,spiderTargetChannelUrlurl,"栏目数目设置错误！")
	else
		local page={}

		local maxPage=tonumber(urlTable[count]["spiderMaxPage"])
		for i=1,maxPage do
			if isExit==false then
				getListPage(i,urlTable[count],page)
			else
				break
			end
		end
		isExit=false
		count=count+1
		return page
	end
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local con = download(data["href"],{})
		data["site"]="浙江政务服务网"
		data["channel"]="办件公告"
		data["spidercode"]=spiderCode
		data["detail"]=findOneText(".hf_content",con)
		data["contenthtml"]=findOneHtml(".hf_content",con)
		data["l_np_publishtime"]=com.strToTimestamp(data["publishtime"])
		data["_d"]="comeintime"
		data["area"]="ZJ"
		local checkAttr={"title","href","publishtime","detail","contenthtml","spidercode","site","channel"}
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
--读取配置文件
function geturlTable(filename)
	local f=io.open(filename,"r")
	local data=f:read("*a") 
	local tab = json.decode(data) --转化json为table
	return tab
end

local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true

function getListPage(i,tab,page)
	local href
	if i==1 then
		href=tab["url"]
	else
		--拼接URL
		href="拼接URL"
	end
	local content = download(href,{})
	local list = findListHtml("#spcontent ul",content)
	while trylistnum<5 and table.getn(list)<1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		saveErrLog(spiderCode,spiderName,spiderTargetChannelUrl,"list==nil")
		content = download(href,{})
		list = findListHtml("#spcontent ul",content)
	end
	trylistnum=0
	for k,v in pairs(list) do
		local item = tab
		item["url"]=nil
		item["spiderMaxPage"]=nil
		item["title"]=findOneText("li:eq(1) a",v)
		item["href"]="http://www.zjzwfw.gov.cn/zjzw/see/notice/"..findOneText("li:eq(1) a:attr(href)",v)
		item["publishtime"]=findOneText("li:eq(3) div",v)
		item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
	

		if k==1 and i==1 then
			if lastRoundTagId=="" then
				lastRoundTagId=item["href"]
			else
				firstStart=false
			end	
			currRoundTagId=item["href"]

		end
		if lastRoundTagId==item["href"] and not firstStart then
			lastRoundTagId=currRoundTagId	
			isExit=true
			break
		end

		table.insert(page,item)
	end
end
