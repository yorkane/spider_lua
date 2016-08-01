--引用公用包
local com=require "res.util.comm"
local json=require "res.util.json"
--名称 网站名称_栏目
spiderName="上海市工商行政管理局";
--代码 区域代码_网站代码_栏目代码
spiderCode="sh_shsgsxzglj";
--是否下载3级页
spiderDownDetailPage=false;
--开始下载页
spiderStartPage=1;
--最大下载页
spiderMaxPage=8;
--上次下载时间 yya_zghgzfcgw_zhbggyy-MM-dd HH:mm:ss
spiderLastDownloadTime="2016-01-22 01:10:01";
--执行频率30分钟
spiderRunRate=30;
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
spiderTargetChannelUrl="http://www.sgs.gov.cn/shaic/dengjiBulletin!toNzbg.action"

--防止死循环
local trylistnum=0 
--记录栏目数目
local channelCount=1
--当前栏目的第几页数据
local channelPage = 1
--栏目总数
local urlTableSum
--判断重复之后退出
local isExit=false
--存放URL
local urlTable={
	{
		url= "http://www.sgs.gov.cn/shaic/dengjiBulletin!toNzbg.action",
		spiderMaxPage="2",
		channel="采购公告",
		toptype="招标",
		type="tender"
	},
	{
		url= "http://www.sgs.gov.cn/shaic/dengjiBulletin!toNzsl.action",
		spiderMaxPage="2",
		channel="中标成交公告",
		toptype="结果",
		subtype="成交",
		type="bid"
	}
}
--获取有多少个栏目
local urlTableSum=table.getn(urlTable)
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	channelCount=1
	channelPage=1
	return os.date("%Y-%m-%d %H:%M:%S",os.time())
	
end

--下载分析列表页
local lastRoundTagId = {}
local currRoundTagId = {}
local firstStart = {}

function downloadAndParseListPage(pageno)
	
	local page={}
	--判断所有栏目是否已下载完成
	if channelCount>urlTableSum then
		return page
	end
	--获取栏目最大页
	local maxPage=tonumber(urlTable[channelCount]["spiderMaxPage"])
	local href=urlTable[channelCount]["url"]
	if channelPage~=1 then
		--拼接URL
		href=href.."?pageno="..tostring(channelPage)
	end
	
	local content = download(href,{})
	local list = findListHtml(".tgList tr",content)
	while trylistnum<5 and table.getn(list)<1 do
		trylistnum=trylistnum+1
		timeSleep(120)--两分钟后重新获取列表
		saveErrLog(spiderCode,spiderName,spiderTargetChannelUrl,"list==nil")
		content = download(href,{})
		list = findListHtml("#spcontent ul",content)
	end
	trylistnum=0
	for k,v in pairs(list) do
		if k==1 then
		else
			local item=getItem(v)
			--判重
			if isComplete(k-1,item["enterprisename"]) then
				break
			end
			-- print(item["enterprisename"])
			table.insert(page,item)	
		end
	end
	channelIsExit(maxPage)
	return page
end


--获取数据项
function getItem(con)
	local item = copyTab(urlTable[channelCount])
	local tmpstr="<table><tr>"..con.."</tr></table>"
	item["area"]="SH"
	item["enterprisename"]=findOneText("td:eq(0)",tmpstr)
	item["publishtime"]=findOneText("td:eq(2)",tmpstr)
	item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
	item["used"]="0"
	--去除无关数据url和spiderMaxPage
	item["url"]=nil
	item["spiderMaxPage"]=nil
	return item
end

--当前本栏目完成
function isComplete(k,contrast)
	if k==1 and channelPage==1 then
		if lastRoundTagId[channelCount]==nil then
			lastRoundTagId[channelCount]=contrast
		else
			firstStart[channelCount]=false
		end	
		currRoundTagId[channelCount]=contrast
	end
	if lastRoundTagId[channelCount]==contrast and firstStart[channelCount]~=nil then
		lastRoundTagId[channelCount]=currRoundTagId[channelCount]	
		-- print("&&&&:",contrast,"重复")
		isExit=true
	end
	return isExit
end
--下一个栏目
function channelIsExit(maxPage)
	if isExit then
		isExit=false
		channelCount=channelCount+1
		channelPage=1
	else
		if channelPage>=maxPage then
			channelCount=channelCount+1
			channelPage=1
		else
			channelPage=channelPage+1
		end
	end
end

--copy表
function copyTab(st)
    local tab = {}
    for k, v in pairs(st or {}) do
        if type(v) ~= "table" then
            tab[k] = v
        else
            tab[k] = copyTab(v)
        end
    end
    return tab
end