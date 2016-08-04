--引用公用包
local com=require "res.util.comm"
--名称 网站名称_栏目
spiderName="浙江政府采购_采购合同公告";
--代码 区域代码_网站代码_栏目代码
spiderCode="zj_zjzfcg_cghtgg";
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
spiderTargetChannelUrl="http://www.zjzfcg.gov.cn/cggg?pageNum=1&pageCount=30&chnlIds=401AND411&bidType=0&bidWay=0&region=0"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	return os.date("%Y-%m-%d %H:%M:%S",os.time())
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
		href="http://www.zjzfcg.gov.cn/cggg?pageNum="..tostring(pageno).."&pageCount=30&chnlIds=401AND411&bidType=0&bidWay=0&region=0"
	end
	local content = download(href,{})
	local list = findListHtml("#content_zhengcefagui .cus_h3",content)
	while trylistnum<5 and table.getn(list)<1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	--print("pageno:",pageno)
	local hrefStar,hrefEnd
	for k,v in pairs(list) do
		if k%2==0 then
		else
			if k==1 and pageno==1 then --第一条数据没有变化，从第二条数据开始抓取
			else
				local item = {}
				item["title"]=findOneText("a:attr(title)",v)
				item["href"]=findOneText("a:attr(onclick)",v)
				--拼接href
				_,hrefStar=string.find(item["href"],"%('")
				hrefEnd,_=string.find(item["href"],"'%)")
				item["href"]="http://www.zjzfcg.gov.cn/"..string.sub(item["href"],hrefStar+1,hrefEnd-1)

				
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
				table.insert(page,item)
			end
		end
		
	end
	return page
end

--下载三级页,分析三级页
function downloadDetailPage(data)
	for i=1,5 do 	--5次下载任务不成功，退出
		local con = download(data["href"],{})
		data["site"]="浙江政府采购"
		data["channel"]="采购合同公告"
		data["toptype"]="信用"
		data["subtype"]="合同"
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
