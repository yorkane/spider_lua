--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="辽宁省工商行政管理局_企业登记变更注销";
--代码 区域代码_网站代码_栏目代码
spiderCode="ln_lnsgsxzglj_qydjbgzx";
--是否下载3级页
spiderDownDetailPage=false;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=1;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-01-22 01:10:01";
--执行频率30分钟
spiderRunRate=180;
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
spiderTargetChannelUrl="http://www.lngs.gov.cn/ecdomain/framework/lngs/anlfaiemapdbbbofiohcpgjmokfngfef.jsp"
local trylistnum=0 --防止死循环
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	local content = download(spiderTargetChannelUrl,{})
	local tmp = findOneText("#marqueebox0 ul:eq(0) li:eq(0) a:attr(title)",content)
	while trylistnum<5 and tmp==nil and string.match(tmp,"(%d+)")==nil do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		saveErrLog(spiderCode,spiderName,href,"tmp=nil")
		return getLastPublishTime()
	end
	trylistnum=0
	--print("time:",com.parseDate(tmp,"yyyyMMdd"))
	return com.parseDate(tmp,"yyyyMMdd")
	

end

--下载分析列表页
local lastRoundTagId = ""
local currRoundTagId = ""
local firstStart = true

function downloadAndParseListPage(pageno)
	
	local page={}	
	local tmppage={}
	local href=spiderTargetChannelUrl
	local content = download(href,{})
	--print(content)
	local list = findListHtml("#marqueebox0 li",content)
	
	while trylistnum<5 and table.getn(list)<1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		saveErrLog(spiderCode,spiderName,href,"list=nil")
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	for k, v in pairs(list) do
	
		item={}
		item["href"]="http://www.lngs.gov.cn"..findOneText("a:attr(href)",v)
		item["title"]=findOneText("a:attr(title)",v)
	
		if k==1 and pageno==1 then
			if lastRoundTagId=="" then
				lastRoundTagId=item["title"]
				
			else
				firstStart=false
			end	
			currRoundTagId=item["title"]
		end
		if lastRoundTagId==item["title"] and not firstStart then
			lastRoundTagId=currRoundTagId	
			break
		end
		table.insert(tmppage,item)
	end
	
	local tempcontent=""--临时存放内容
	local onecontent=""--分析页面中的内容
	--[[
		
	]]


	for k,v in pairs(tmppage) do
		local count=0
		--print("fenxiyemian!")
		tempcontent=download(v["href"],{})
		--print(tempcontent)
		while tempcontent==nil and count<5 do
			timeSleep(120)--两分钟后重新获取列表
			saveErrLog(spiderCode,spiderName,href,"tempcontent=nil")
			tempcontent=download(v["href"],{})
			count=count+1
		end

		onecontent=findOneHtml("div","#newscontent",tempcontent)
		--把<br/>换成,
		onecontent=string.gsub(onecontent,"<br/>",",");
		--分割字符串
		onecontent=com.split(onecontent,",")
		local size=table.getn(onecontent)
		for k,v in pairs(onecontent) do
			names={}
			if k==1 or k==size then
			else
				names["enterprisename"] = com.split(v,"%s")[3]
				names["area"]="LN"
				names["publishtime"]=com.split(v,"%s")[1]
				names["publishtime"]=com.parseDate(names["publishtime"],"yyyyMMdd")
				names["used"]="0"
				names["source"]=spiderCode
				if names["enterprisename"]=="" or names["enterprisename"]==nil then
					saveErrLog(spiderCode,spiderName,href,"enterprisename=nil") 
				end
				--print(names["enterprisename"])
				table.insert(page,names)
			end
		end
		
	end
	
	return page
end

