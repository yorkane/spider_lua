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
spiderRunRate=20;
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
local count=1
--当前栏目的第几页数据
local i = 1
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
	count=1
	i=1
	return os.date("%Y-%m-%d %H:%M:%S",os.time())
	
end

--下载分析列表页
local lastRoundTagId = {}
local currRoundTagId = {}
local firstStart = {}

function downloadAndParseListPage(pageno)
	local page={}
	--判断所有栏目是否已下载完成
	if count>urlTableSum then
		return page
	end
	--获取栏目最大页
	local maxPage=tonumber(urlTable[count]["spiderMaxPage"])
	local href=urlTable[count]["url"]
	if i~=1 then
		--拼接URL
		href=href.."?pageno="..tostring(i)
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
	local tmpstr = ""
	for k,v in pairs(list) do
		if k==1 then
		else
			local item = copyTab(tab)
			tmpstr=tmpstr..v
			tmpstr="<table><tr>"..tmpstr.."</tr></table>"
			item["area"]="SH"
			item["enterprisename"]=findOneText("td:eq(0)",tmpstr)
			item["publishtime"]=findOneText("td:eq(2)",tmpstr)
			item["publishtime"]=com.parseDate(item["publishtime"],"yyyyMMdd")
			item["used"]="0"
			--去除无关数据url和spiderMaxPage
			item["url"]=nil
			item["spiderMaxPage"]=nil
			tmpstr=""
			print(item["enterprisename"])
			if k==2 and i==1 then
				if lastRoundTagId[count]==nil then
					lastRoundTagId[count]=item["enterprisename"]
				else
					firstStart[count]=false
				end	
				currRoundTagId[count]=item["enterprisename"]
			end
			if lastRoundTagId[count]==item["enterprisename"] and firstStart[count]~=nil then
				lastRoundTagId[count]=currRoundTagId[count]	
				print("######",item["enterprisename"],"重复")
				isExit=true
				break
			end
			table.insert(page,item)
			
		end
	end
	--如果本栏目有重复，不再下载下面的页面，进入下一个栏目
	if isExit then
		isExit=false
		count=count+1
		i=1
	else
		if i>=maxPage then
			count=count+1
			i=1
		else
			i=i+1
		end
	end
	return page
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