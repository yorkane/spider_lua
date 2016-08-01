--引用公用包
local com=require "res.util.comm"
local ecps=require "res.util.ecps"
--名称
spiderName="北京公示爬虫";
--代码
spiderCode="ecps_bj";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载页
spiderMaxPage=1000;
--上次下载时间
spiderLastDownloadTime="2016-01-01 01:01:01";
--执行频率30分钟
spiderRunRate=30;

--下载内容写入表名
spider2Collection="ecps";
--下载页面时使用的编码
spiderPageEncoding="UTF8";
--是否使用代理
spiderUserProxy=false;
--是否是安全协议
spiderUserHttps=false;
--下载详细页线程数
spiderThread=1
--存储模式 1 直接存储，2 调用消息总线 ...
spiderStoreMode=1
spiderStoreToMsgEvent=1 --消息总线event
--延时毫秒 基本延时(spiderSleepBase)+随机延时(spiderSleepRand)
spiderSleepBase=1000
spiderSleepRand=5000
--判重字段 空默认不判重，spiderCoverAttr="title" 按title判重覆盖
spiderCoverAttr="title"
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	return os.date("%Y-%m-%d %H:%M:%S", os.time())
end

--下载分析列表页
function downloadAndParseListPage(pageno) 
	local entMl={}
	for i=0,1 do
				item={}
				item["title"]="北京鹏华经济技术发展公司"
				item["href"]="http://qyxy.baic.gov.cn/CheckCodeCaptcha" --验证码
				table.insert(entMl,item)
	end
	return entMl
	
end


function downloadDetailPage(data)
--	local content="<table cellspacing='0' cellpadding='0' class='detailsList' ><tr><th colspan='4' style='text-align:center;'>基本信息 </th></tr><tr><th width='20%'>注册号</th><td width='30%'>1101081414483</td> <th>名称</th><td width='30%'>北京鹏华经济技术发展公司</td></tr><tr><th>类型</th><td>全民所有制</td><th width='20%'>法定代表人</th><td>高永刚</td></tr><tr><th>住所</th><td colspan='3'>北京市海淀区永定路北口104号</td></tr><tr><th>注册资本</th><td>480 万元</td><th>成立日期</th><td>1990年04月02日</td></tr><tr><th>经营期限自</th><td></td><th>经营期限至</th><td></td></tr><tr><th>经营范围</th><td colspan='3'>销售针纺织品、文化办公用机械、五金、交电、化工产品（不含化学危险品）、土畜产品、民用建材、家俱、计算机及外围设备、金属材料、机械电器设备、木材、建筑材料，零售汽车（除小轿车）；技术开发；技术咨询；技术转让。法律、法规禁止的，不得经营；应经审批的，未获审批前不得经营；法律、法规未规定审批的，企业自主选择经营项目，开展经营活动。</td></tr><tr><th width='20%'>登记机关</th><td>海淀分局</td><th>核准日期</th><td>2003年09月24日</td></tr><tr><th width='20%'>登记状态</th><td>吊销企业</td><th width='20%'>吊销日期</th><td> 2008年10月29日</td></tr></table>"


--	local th=findListText("table.detailsList tr th",content)
--	local td=findListText("table.detailsList tr td",content)
--	local tab={}
--	local entInfo={}
--	for k,v in pairs(th) do
--		if k>1 then
--			local tdv=com.trim(td[k-1])
--			tab[com.trim(v)]=tdv
--			print(com.trim(v),tab[com.trim(v)])
--		end
--	end
	
--	print("************************")
--	local baseinfo=ecps.reversalFormat(tab,ecps.baseFm,ecps.baseMap)
	 
--	for k,v in pairs(baseinfo) do
--		print(k,":",v)
--		entInfo[k]=v
--	end

	for i=0,3 do
	
		for j=0,5 do
			if j==3 then
				return ""
				
			else
				print("i:",i," j:",j)
			end
		end
	end
	print("zuihou ")
end

