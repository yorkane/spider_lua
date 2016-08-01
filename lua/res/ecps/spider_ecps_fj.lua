--河北省公示系统爬虫  
--http://www.hebscztxyxx.gov.cn/notice/home

--引用公用包
local com=require "res.util.comm"
local ecps=require "res.util.ecps"
--名称
spiderName="福建公示爬虫";
--代码
spiderCode="ecps_fj";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载页
spiderMaxPage=1;
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
spiderSleepBase=100
spiderSleepRand=100
--判重字段 空默认不判重，spiderCoverAttr="title" 按title判重覆盖
spiderCoverAttr="title"
--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	return os.date("%Y-%m-%d %H:%M:%S", os.time())
end


--		name: "session.token",
--		code: "8ad65bdc-8b5c-4023-a76a-5f8cedb81bd7",
--		data: {
--			"session.token": "8ad65bdc-8b5c-4023-a76a-5f8cedb81bd7"
--		}
--下载分析列表页
function downloadAndParseListPage(pageno) 
	--print(string.match("global.token = {name: \"session.token\",code:\"89590f0d-7894-4639-830e-110d7c8e00d8\",data: {\"session.token\": \"89590f0d-7894-4639-830e-110d7c8e00d8\"}};","code:\"(.*%-.*%-.*%-.*%-.*)\"%,"))
	--os.exit(0)
	local entMl=getEntNames("ecps_bj")
	--local entMl={}
	print("福建企业名录长度:",tostring(table.getn(entMl)))
	if table.getn(entMl)==0 then
		print("开始下福建异常名录")
		local head={
				["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
				["Accept-Encoding"]="gzip,deflate,sdch",
				["Accept-Language"]="zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
				["Cache-Control"]="no-cache",
				["Host"]="wsgs.fjaic.gov.cn",
				["Pragma"]="no-cache",
				["Upgrade-Insecure-Requests"]="1",
				["User-Agent"]="Mozilla/.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.130 Safari/537.36"	
		}
		local param={}
		param["condition.pageNo"]=tostring(pageno)
		param["condition.insType"]=""
		local con,_=downloadAdv("http://wsgs.fjaic.gov.cn/creditpub/search/ent_except_list","get",param,head,"")	
		if con=="" then 
			print("下载福建异常名录出错")
			return entMl
		end
		local listHtml=findListHtml("table.list-table tr",con)
		for k,v in pairs(listHtml) do
			if k>1 and k<table.getn(listHtml) then
				item={}
				item["title"]="td:eq(0) a:eq(0)"
				item["regno"]="td:eq(1)"
				item=findMap(item,"<table>><tr>"..v.."</tr></table>")
				item["href"]="http://www.hebscztxyxx.gov.cn/notice/captcha?preset=&ra=0.1800365946930833" --验证码
				table.insert(entMl,item)
				--print(item["title"],item["regno"])
			end
		end
	end

--测试代码
--	local entMl={}
--	for i=1,1 do
--				item={}
--				--item["title"]="福州市鼓楼区晟邦网络技术有限公司"
--				item["title"]="福建易联众电子科技有限公司"
--				item["href"]="http://qyxy.baic.gov.cn/CheckCodeCaptcha" --验证码
--				table.insert(entMl,item)
--				print("***********************")
--	end
--	return entMl
--测试代码结束
	return entMl
end

function downloadDetailPage(data)
	timeSleep(10)
	print("开始下载  ",data["title"],"  公示数据")
	for i=1,50 do
		for j=1,1 do
			local content,cookies = downloadAdv("http://wsgs.fjaic.gov.cn/creditpub/home","get",{},{},"")
			local param={}
			--print("cookies:",cookies)
			--local cookies_obj=com.eval(cookies)
			--local cookies_str=cookies_obj[1]["Name"].."="..cookies_obj[1]["Value"]..";"..cookies_obj[2]["Name"].."="..cookies_obj[2]["Value"]
			param["session.token"]=getSessionToken(content)
			--param["cookies_str"]=cookies_str
			param["condition.keyword"]=com.trim(data["title"])
			local entDetailUrl=getEntTmp(param,cookies)-- 获取通过验证码之后的企业名称列表页基本信息
			if entDetailUrl=="" then
				return nil
			elseif entDetailUrl=="error" then
				break
			else 
				local entInfo={}
				local errorMsg=getEntDetail(entDetailUrl,cookies,entInfo)
				if errorMsg=="error" then
					print("下载 ",data["title"]," 详情页面出错")
					break
				end
				if entInfo["Area"]~="FJ" then
					print("下载",data["title"]," 详细信息不完整，丢弃")
					return nil
				else
					--去冗余字段
					entInfo["pripid"]=nil
					entInfo["href"]=nil
					entInfo["publishtime"]=nil
					return entInfo
				end
			end
		end
	end
end


function getEntTmp(param,cookies)
	local listparam={
		["captcha"]="",
		["condition.pageNo"]="1",
		["condition.insType"]="",
		--["session.token"]="a36846a1-807e-494f-b179-481f177f08a8",				
		["session.token"]=param["session.token"],
		["condition.keyword"]=com.encodeURI(param["condition.keyword"])
	}
	--print("cookies_str:"..param["cookies_str"])
	local head={
		["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
		["Accept-Encoding"]="gzip, deflate",
		["Accept-Language"]="zh-CN,zh;q=0.8",
		["Content-Type"]="application/x-www-form-urlencoded",
		["Host"]="wsgs.fjaic.gov.cn",
		["Origin"]="http://wsgs.fjaic.gov.cn",
		--["Cookie"]=com.trim(param["cookies_str"]),
		["Referer"]="http://wsgs.fjaic.gov.cn/creditpub/search/ent_info_list",
		["Upgrade-Insecure-Requests"]="1",
		["User-Agent"]="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36"
	}
	local entListContent,_=downloadAdv("http://wsgs.fjaic.gov.cn/creditpub/search/ent_info_list","post",listparam,head,cookies)
	if entListContent=="" then 
		print("福建根据名称查询企业临时列表出错，返回。。。")
		return "error"
	end
	--print(entListContent)
	local detailUrl = findOneText("div.list-item div.link a:eq(0):attr(href)",entListContent)
	--print(detailUrl)
	if detailUrl~="" then 
		return detailUrl
	end
	return ""
end



function getEntDetail(entDetailUrl,cookies,entInfo)
	local head={
		["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
		["Accept-Encoding"]="gzip, deflate",
		["Accept-Language"]="zh-CN,zh;q=0.8",
		["Content-Type"]="application/x-www-form-urlencoded",
		["Host"]="wsgs.fjaic.gov.cn",
		["Origin"]="http://wsgs.fjaic.gov.cn",
		["Referer"]="http://wsgs.fjaic.gov.cn/creditpub/search/ent_info_list",
		["Upgrade-Insecure-Requests"]="1",
		["User-Agent"]="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36"
	}
	local content,_=downloadAdv(entDetailUrl,"get",{},head,cookies)
	if content=="" then
		print("查询企业基本信息请求出错")
		return "error"
	end
	entInfo["Area"]="FJ"
	--基本信息
	entInfo=getBaseInfo(content,entInfo)
	--股东信息
	local invertors=getInvertor(content)
	entInfo["invertor"]=invertors
	--变更信息
	local alterInfos=getAlterInfo(content,head)
	entInfo["alterInfo"]=alterInfos
	--主要人员
	local staffinfos=getStaffinfo(content)
	entInfo["staffinfo"]=staffinfos
	--分支机构
	local childents=getChildent(content)
	entInfo["childent"]=childents
	--行政处罚
	local punishInfos=getPunishInfo(content)
	entInfo["punishInfo"]=punishInfos
	--经营异常
	local excDirecs=getExcDirec(content)
	entInfo["excDirec"]=excDirecs
	
	--年报
	local nbtab=getNbList(cookies,entDetailUrl)
	if nbtab=="error" then
		print("查询年报列表信息请求出错")
		return "error"
	end
	entInfo["qynb"]=nbtab
	
	
end


function getBaseInfo(content,entInfo)
	local th=findListText("table.info:eq(0) tr th",content)
	local td=findListText("table.info:eq(0) tr td",content)
	local tab={}
	for k,v in pairs(th) do
		if k>1 then
			local tdv=com.trim(td[k-1])
			tab[com.trim(v)]=tdv
			--print(com.trim(v),tab[com.trim(v)])
		end
	end
	local baseinfo=ecps.reversalFormat(tab,ecps.baseFm,ecps.baseMap)
	for k,v in pairs(baseinfo) do
		entInfo[k]=v
		--print(k,v)
	end
	return entInfo
end

function getInvertor(content)
	local investors={}
	local list=findListHtml("table#investorTable  tr",content)
	for k,v in pairs(list) do
		if k>2 then
			local item={}
			item["gdlx"]="td:eq(0)"
			item["gdname"]="td:eq(1)"
			item=findMap(item,"<table>><tr>"..v.."</tr></table>")
			if  item["gdlx"]~=nil then
				--print(item["gdlx"]..item["gdname"])
				local inverstor={}
				inverstor["Inv"]=item["gdname"]
				inverstor["InvTypeName"]=item["gdlx"]
				table.insert(investors,inverstor)
			end
		end
	end
	return investors
end


function getAlterInfo(content)
	local alterInfos={}
	local list=findListHtml("table#alterTable tr",content)
	local len=table.getn(list)
	if len>0 then
		for k,v in pairs(list) do 
			
			if k>2 and k<len then
				--print(v)
				item={}
				item["AltItemName"]="td:eq(0)"
				item["AltBe"]="td:eq(1)"
				item["AltAf"]="td:eq(2)"
				item["AltDate"]="td:eq(3)"
				item=findMap(item,"<table><tr>"..v.."</tr></table>")
				
				if item["AltDate"]~=nil then
					local alterInfo={}
					alterInfo["AltItemName"]=item["AltItemName"]
					alterInfo["AltAf"]=item["AltAf"]
					alterInfo["AltBe"]=item["AltBe"]
					alterInfo["AltDate"]=item["AltDate"]
					--print(alterInfo["AltItemName"],alterInfo["AltBe"],alterInfo["AltAf"])
					table.insert(alterInfos, alterInfo)	
				end
			end
		end
	end
	return alterInfos
end


function getStaffinfo(content)
	local staffinfos={}
	local list=findListHtml("table#memberTable tr",content)
	local len=table.getn(list)
	if len>0 then
		for k,v in pairs(list) do 
			if k>2 and k<len then
				item={}
				item["xm1"]="td:eq(1)"
				item["zw1"]="td:eq(2)"
				item["xm2"]="td:eq(4)"
				item["zw2"]="td:eq(5)"
				item=findMap(item,"<table>><tr>"..v.."</tr></table>")
				--print("第一列:",item["xm1"],item["zw1"])
				local staffinfo={}
				staffinfo["Name"]=item["xm1"]
				staffinfo["Position"]=item["zw1"]
				table.insert(staffinfos,staffinfo)
				if item["xm2"]~=nil  then
					--print("第二列:",item["xm2"],item["zw2"])
					local _staffinfo={}
					_staffinfo["Name"]=item["xm2"]
					_staffinfo["Position"]=item["zw2"]
					table.insert(staffinfos,_staffinfo)
				end
			end
		end
	end
	return staffinfos
end

function getChildent(content)
	local childents={}
	local list=findListHtml("table#branchTable tr",content)
	local len=table.getn(list)
	if len>0 then
		for k,v in pairs(list) do
			if k>2 and k<len then
				local item={}
				item["regNo"]="td:eq(1)"
				item["entName"]="td:eq(2)"
				item["regOrgan"]="td:eq(3)"
				item=findMap(item,"<table>><tr>"..v.."</tr></table>")
				local childent={}
				childent["BrName"]=item["entName"]--分支名称
				childent["RegNO"]=item["regNo"]--注册号
				childent["RegOrgName"]=item["regOrgan"]--分支机构登记机关
				--print(childent["BrName"],childent["RegNO"],childent["RegOrgName"])
				table.insert(childents, childent)
			end
		end
	end
	return childents
end

function getPunishInfo(content)
	local punishInfos={}
	local list=findListHtml("table#punishTable tr",content)
	local len=table.getn(list)
	if len>0 then
		for k,v in pairs(list) do
			if k>2 and k<len then
				local item={}
				item["PenDecNo"]="td:eq(1)"
				item["IllegActTypeName"]="td:eq(2)"
				item["PenResult"]="td:eq(3)"
				item["OrgName"]="td:eq(4)"
				item["PenDecIssDate"]="td:eq(5)"
				item=findMap(item,"<table>><tr>"..v.."</tr></table>")
				local punishInfo={}
				punishInfo["PenDecNo"]=item["PenDecNo"]--行政处罚号
				punishInfo["IllegActTypeName"]=item["IllegActTypeName"]--行政处罚类型名称
				punishInfo["PenResult"]=item["PenResult"]--处罚结果
				punishInfo["OrgName"]=item["OrgName"]--机构
				punishInfo["PenDecIssDate"]=item["PenDecIssDate"]--日期
				--print(punishInfo["PenDecNo"],punishInfo["IllegActTypeName"],punishInfo["PenResult"],punishInfo["OrgName"],punishInfo["PenDecIssDate"])
				table.insert(punishInfos, punishInfo)
			end
		end
	end
	return punishInfos
end

function getExcDirec(content)
	local excDirecs={}
	local list=findListHtml("table#exceptTable tr",content)
	local len=table.getn(list)
	if len>0 then
		for k,v in pairs(list) do
			if k>2 and k<len then
				local excDirec={}
				item={}
				item["DecOrg"]="td:eq(5)"
				item["SpeCause"]="td:eq(1)"
				item["AbnTime"]="td:eq(2)"
				item["OutSpeTim"]="td:eq(4)"
				item["OutSpeCause"]="td:eq(3)"
				
				item=findMap(item,"<table>><tr>"..v.."</tr></table>")
				excDirec["DecOrg"]=com.trim(item["DecOrg"])
				excDirec["SpeCause"]=com.trim(item["SpeCause"])	
				excDirec["AbnTime"]=com.trim(item["AbnTime"])
				excDirec["OutSpeTim"]=com.trim(item["OutSpeTim"])
				excDirec["OutSpeCause"]=com.trim(item["OutSpeCause"])
				--print(excDirec["DecOrg"],excDirec["SpeCause"],excDirec["AbnTime"],excDirec["OutSpeTim"],excDirec["OutSpeCause"])
				table.insert(excDirecs, excDirec)
			end
		end
	end
	return excDirecs
end

function getNbList(cookies,url)
	--print("url:",url)
	local nbListUrl=string.gsub(url,"=01","=02")
	--print("年报url:",nbListUrl)
	local head={
		["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
		["Accept-Encoding"]="gzip, deflate",
		["Accept-Language"]="zh-CN,zh;q=0.8",
		["Content-Type"]="application/x-www-form-urlencoded",
		["Host"]="wsgs.fjaic.gov.cn",
		["Origin"]="http://wsgs.fjaic.gov.cn",
		["Referer"]="http://wsgs.fjaic.gov.cn/creditpub/search/ent_info_list",
		["Upgrade-Insecure-Requests"]="1",
		["User-Agent"]="Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.84 Safari/537.36"
	}
	local content,_=downloadAdv(nbListUrl,"get",{},head,cookies)
	local list=findListHtml("table.info:eq(0) tr",content)
	local nbinfos={}
	for k,v in pairs(list) do
		if k>2 then
			local nbDetailUrl=findOneText("td:eq(1) a:attr(href)","<table><tr>"..v.."</tr></table>")
			local nd=findOneText("td:eq(1) a:eq(0)","<table><tr>"..v.."</tr></table>") --年度
			--print(nbDetailUrl)
			if nbDetailUrl~="" then
				local _content,_=downloadAdv(nbDetailUrl,"get",{},head,cookies)
				local nbinfo=getExYear(_content)
				nbinfo["ancheyear"]=nd
				table.insert(nbinfos, 1, nbinfo)
			end
		end
	end
	return nbinfos
	
end

function getExYear(content)
	local nb={}
	--年报基本信息
	local th=findListText("table.info:eq(0) tr th",content)
	local td=findListText("table.info:eq(0) tr td",content)
	local tab={}
	for k,v in pairs(th) do
		if k>2 then
			local tdv=com.trim(td[k-2])
			tab[com.trim(v)]=tdv
			--print(com.trim(v),tab[com.trim(v)])
		end
	end
	local nbbase=ecps.reversalFormat(tab,ecps.baseNbFm,ecps.baseNbMap)
	nb["base"]=nbbase
	
	
	--股东及出资信息
	local gdList=findListHtml("table.info:eq(2) tr",content)
	local gdLen=table.getn(gdList)
	local gdczs={}
	if gdLen>0 then
		for k,v in pairs(gdList) do
			if k>2 then
				--print(v)
				local item={}
				item["inv"]="td:eq(0)"
				item["acConAm"]="td:eq(4)" 
				item["realConDate"]="td:eq(5)"
				item["realConForm"]="td:eq(6)"
				item["subConAm"]="td:eq(1)"
				item["subConAmForm"]="td:eq(3)"
				item["subConAmDate"]="td:eq(2)"
				item=findMap(item,"<table>><tr>"..v.."</tr></table>")
				local gdcz={}
				gdcz["inv"]=com.trim(item["inv"])--股东
				gdcz["acConAm"]=com.trim(item["acConAm"]) --实缴出资额
				gdcz["realConDate"]=com.trim(item["realConDate"])--实缴出资时间
				gdcz["realConForm"]=com.trim(item["realConForm"])--实缴出资方式
				gdcz["subConAm"]=com.trim(item["subConAm"])--认缴出资额
				gdcz["subConAmForm"]=com.trim(item["subConAmForm"])--认缴出资方式
				gdcz["subConAmDate"]=com.trim(item["subConAmDate"])--认缴出资时间
				table.insert(gdczs,gdcz)
				--print(gdcz["inv"],gdcz["subConAm"],gdcz["subConAmDate"],gdcz["subConAmForm"],gdcz["acConAm"],gdcz["realConDate"],gdcz["realConForm"])
			end
		end
	end
	nb["invs"]=gdczs
	
	
	--对外投资信息
	local tzList=findListHtml("table.info:eq(3) tr",content)
	local tzLen=table.getn(tzList)
	local tzs={}
	if tzLen>0 then
		for k,v in pairs(tzList) do
			if k>2 then
				local item={}
				item["name"]="td:eq(0)"
				item["regno"]="td:eq(4)" 
				item=findMap(item,"<table>><tr>"..v.."</tr></table>")
				local tz={}
				tz["name"]=com.trim(item["name"])--名称
				tz["regno"]=com.trim(item["regno"]) --注册号
				table.insert(tzs,tz)
				--print(tz["name"],tz["regno"])
			end
		end
	end
	nb["investment"]=tzs
	
	--企业资产状况信息
	local qyzc={}
	local th=findListText("table.info:eq(4) tr th",content)
	local td=findListText("table.info:eq(4) tr td",content)
	for k,v in pairs(th) do
		if k>1 then
			--print(v)
			qyzc[com.trim(v)]=com.trim(td[k-1])
			--print(com.trim(v),com.trim(td[k-1]))
		end
	end
	nb["assetstatus"]=qyzc
	--print("******************")
	
	--对外提供保证担保信息
	local dbList=findListHtml("table.info:eq(5)  tr",content)
	local dbLen=table.getn(dbList)
	local dwdbs={}
	for k,v in pairs(dbList) do
		if k>2 and k<dbLen then
			--print(v)
			local dwdb={}
			item={}
			item["more"]="td:eq(0)"--债权人
			item["mortgagor"]="td:eq(1)" --债务人
			item["priclaseckindvalue"]="td:eq(2)"--主债权种类
			item["priclasecam"]="td:eq(3)"--主债权数额
			item["pefperformandto"]="td:eq(4)"--履行债务的期限
			item["guaranperiodvalue"]="td:eq(5)"--保证的期间
			item["gatypevalue"]="td:eq(6)"--保证的方式
			item["ragevalue"]="td:eq(7)"--保证担保的范围
			item=findMap(item,"<table>><tr>"..v.."</tr></table>")
			dwdb["more"]=com.trim(item["more"]) 
			dwdb["mortgagor"]=com.trim(item["mortgagor"])
			dwdb["priclaseckindvalue"]=com.trim(item["priclaseckindvalue"]) 
			dwdb["priclasecam"]=com.trim(item["priclasecam"])
			dwdb["pefperformandto"]=com.trim(item["pefperformandto"]) 
			dwdb["guaranperiodvalue"]=com.trim(item["guaranperiodvalue"])
			dwdb["gatypevalue"]=com.trim(item["gatypevalue"]) 
			dwdb["ragevalue"]=com.trim(item["ragevalue"])  
			table.insert(dwdbs,dwdb)
		end
	end
	nb["guarantees"]=dwdbs
	
	--股权变更信息
	local bgList=findListHtml("table.info:eq(6)  tr",content)
	local bgLen=table.getn(bgList)
	local bgs={}
	if bgLen>0 then
		for k,v in pairs(bgList) do
			if k>2 then
				local bg={}
				item={}
				item["inv"]="td:eq(0)"
				item["transbmpr"]="td:eq(1)" 
				item["transampr"]="td:eq(2)"
				item["altdate"]="td:eq(3)"
				item=findMap(item,"<table>><tr>"..v.."</tr></table>")
				bg["inv"]=item["inv"] --股东
				bg["transbmpr"]=item["transbmpr"] --变更前股权比例
				bg["transampr"]=item["transampr"] --变更后股权比例				
				bg["altdate"]=item["altdate"] --股权变更日期
				--print(bg["inv"],bg["transbmpr"],bg["transampr"],bg["altdate"])
				table.insert(bgs, bg)
			end
		end
	end
	nb["equitychange"]=bgs
	return nb
end

function strDel(str)
	str=string.gsub(str,"\"","")
	return str
end

function getSessionToken(con) 
--	local sessionToken=""
--		local i = string.find(con, "code:")
--		if i~=nil then
--			local tmp=string.sub(con,i)
--			local j=string.find(tmp,",")
--			local tmp2=string.sub(tmp,1,j-1)
--			sessionToken=string.gsub(tmp2,"code:","")
--			return strDel(sessionToken)
--		end
--	return sessionToken
	
	--print("匹配结果:")
	--print(string.match(con,"code: \"(.*%-.*%-.*%-.*%-.*)\"%,"))
	local sessionToken=string.match(con,"code:%s*\"(.*)\"%,%s*data")
	print("获取到sessionToken:"..sessionToken)
	return com.trim(sessionToken)
	--print("匹配结果结束")

end