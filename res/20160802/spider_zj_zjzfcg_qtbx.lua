--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="浙江政府采购_其他标讯";
--代码 区域代码_网站代码_栏目代码
spiderCode="zj_zjzfcg_qtbx";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=4;
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
spiderTargetChannelUrl="http://www.zjzfcg.gov.cn/qtbx"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	return os.date("%Y-%m-%d %H:%M:%S",os.time())
end

--下载分析列表页
local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true
local cks = ""
local param = {}
local head = {}
function downloadAndParseListPage(pageno)
	local page={}
	local content=""	
	head={
		["Accept"]="*/*",
		["Accept-Encoding"]="deflate",
		["Accept-Language"]="zh-CN,zh;q=0.8",
		["Connection"]="keep-alive",
		["Content-Type"]="application/x-www-form-urlencoded; charset=UTF-8",
		["Origin"]="http://www.zjzfcg.gov.cn",
		["Upgrade-Insecure-Requests"]="1",
		["Host"]="hgcg.customs.gov.cn",
		["Referer"]="http://www.zjzfcg.gov.cn/qtbx",
		["User-Agent"]="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.75 Safari/537.36",
		["X-Requested-With"]="XMLHttpRequest"
	}
	local href
	if pageno==1 then
		href=spiderTargetChannelUrl
		content,cks = downloadAdv(href,"get",{},{},"")
	else
		param={
			["frontMobanType"]="1",
			["pageNum"]=tostring(pageno),
			["pageCount"]="30"
		}
		content,cks = downloadAdv("http://www.zjzfcg.gov.cn/qtbxPagination","post",param,head,cks)
	end
	local list = findListHtml("#content_zhengcefagui li",content)
	print(table.getn(list))
	while trylistnum<5 and table.getn(list)<1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	--print("pageno:",pageno)
	
	local hrefStar,hrefEnd
	for k,v in pairs(list) do
		local item = {}
		item["title"]=findOneText("a:attr(title)",v)
		item["href"]=findOneText("a:attr(onclick)",v)
		--拼接href
		_,hrefStar=string.find(item["href"],"%('")
		hrefEnd,_=string.find(item["href"],"'%)")
		item["href"]="http://www.zjzfcg.gov.cn/"..string.sub(item["href"],hrefStar+1,hrefEnd-1)

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
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local con = download(data["href"],{})
		data["site"]="浙江政府采购"
		data["channel"]="其他标讯"
		
		data["type"]="other"
		data["spidercode"]=spiderCode
		data["detail"]=findOneText("#news_content",con)
		data["contenthtml"]=findOneHtml("#news_content",con)
		data["publishtime"]=findOneText("#news_msg span:eq(0)",con)
		data["publishtime"]=com.parseDate(data["publishtime"],"yyyyMMdd")
		data["l_np_publishtime"]=com.strToTimestamp(data["publishtime"])
		data["_d"]="comeintime"
		data["area"]="浙江"
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
