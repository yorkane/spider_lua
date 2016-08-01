--引用公用包
local com=require "res.util.comm"
local ecps=require "res.util.ecps"
--名称
spiderName="辽宁公示爬虫";
--代码
spiderCode="ecps_ln";
--是否下载3级页
spiderDownDetailPage=true;
--开始下载页
spiderStartPage=1;
--最大下载也
spiderMaxPage=5000;
--上次下载时间
spiderLastDownloadTime="2016-01-01 01:01:01";
--执行频率30分钟
spiderRunRate=1;
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
--判重字段 空默认不判重，spiderCoverAttr="title" 按title判重覆盖
spiderCoverAttr="title"
--延时毫秒 基本延时(spiderSleepBase)+随机延时(spiderSleepRand)
spiderSleepBase=100
spiderSleepRand=100
--默认列表页第一页
spiderTargetChannelUrl="http://gsxt.lngs.gov.cn/saicpub/"

--取得对方网站最后发布时间 必须返回yyyy-MM-dd HH:mm:ss 格式
function getLastPublishTime()
	--公示数据直接返回当前时间
	return os.date("%Y-%m-%d %H:%M:%S", os.time())
end

--下载分析列表页
local trylistnum=0
function downloadAndParseListPage(pageno) 
	local list={}
	list=getEntNames("ecps_ln")--从企业名录中获取数据
	print(spiderCode,pageno,"从企业名录获取",table.getn(list),"条数据")
	if table.getn(list)<1 then
		local param={["num"]=tostring(pageno),["code"]="",["condition"]="",["city"]="",["year"]="",["pagesize"]=""}
		local head={
			["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
			["Accept-Encoding"]="gzip, deflate",
			["Accept-Language"]="zh-CN,zh;q=0.8",
			["Content-Type"]="application/x-www-form-urlencoded",
			["Host"]="gsxt.lngs.gov.cn",
			["Origin"]="http://gsxt.lngs.gov.cn",
			["Referer"]="http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getJyycmlxx.action",
			["Upgrade-Insecure-Requests"]="1",
			["User-Agent"]="Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2552.0 Safari/537.36",
		}
		local con=downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getJyycmlxx.action","post",param,head,"")	
		local regnos=findListHtml("div.tb-b li.tb-a2",con)
		local names=findListHtml("div.tb-b li.tb-a1 a",con)
		for k,v in pairs(regnos) do
		    item={}	
			item["href"]="http://gsxt.lngs.gov.cn/saicpub/commonsSC/loginDC/securityCode.action" --验证码
			item["title"]=com.trim(names[k])--"大连实德塑胶工业有限公司"
			item["regno"]=com.trim(v)
			item["publishtime"]=os.date("%Y-%m-%d %H:%M:%S", os.time())
			--print(item["title"])
			table.insert(list,item)
		end
	end
	while trylistnum<5 and table.getn(list)<1 do
 		trylistnum=trylistnum+1
		print(spiderCode,"两分钟后重新获取列表")
		timeSleep(120)--两分钟后重新获取列表
		return downloadAndParseListPage(pageno)
	end
	trylistnum=0
	return list
end


--下载三级页,分析三级页downloadAdv(href,method,param,head,cookies)
function downloadDetailPage(data)
	--验证码地址设置(企业名录无验证码地址)
	data["title"]=com.trim(data["title"])
	data["href"]="http://gsxt.lngs.gov.cn/saicpub/commonsSC/loginDC/securityCode.action"	
	local entInfo,err=nil --企业信息对象
	local b=false     --验证码验证是否成功
	for i=1,50 do--死循50次
		err=nil
		for k=0,1 do 
			print(spiderCode,"开始下载",data["title"])
			--指定下载点，一般不用，部分网站前后请求识别ip需要指定
			--changeDownloader()
			--获取cookies
			local content,cookies = downloadAdv("http://gsxt.lngs.gov.cn/saicpub/","get",{},{},"")
			math.randomseed(os.clock()*10000) 
			local param={
				["tdate"]=tostring(math.random(1,10000)*3),
				["timestamp"]=tostring(os.time)
			}
			--获取验证码
			local code= getCode(data["href"],"get",param,{},cookies)
			--print(param["tdate"],code)
			local head={
				["Host"]="gsxt.lngs.gov.cn",
				["Connection"]="keep-alive",
				["Pragma"]="no-cache",
				["Cache-Control"]="no-cache",
				["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
				["Origin"]="http://gsxt.lngs.gov.cn",
				["Upgrade-Insecure-Requests"]="1",
				["User-Agent"]="Mozilla/.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.130 Safari/537.36",
				["Content-Type"]="application/x-www-form-urlencoded",
				["Referer"]="http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/entPublicity/search/searchmain.jsp",
				["Accept-Encoding"]="gzip, deflate",
				["Accept-Language"]="zh-CN,zh;q=0.8"
			}	
			local param={["authCode"]=code,["solrCondition"]=data["title"]}
			--查询一个企业
			entInfo,err=getEntTmp("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/lngsSearchFpc.action","post",param,head,cookies)	
			if err~=nil then--出错重新下载
				entInfo=nil
				break
			end
			if entInfo==nil then--不存此企业，退出循环
				return nil
			end
			entInfo["Area"]="LN"
			local query={["pripid"]=entInfo.pripid,["type"]=entInfo.EntType}
			--基本信息
			--print("基本信息")
			if entInfo["RegNo"]==nil or entInfo["RegNo"]=="" then
				entInfo,err=getBaseInfo(entInfo,query,cookies)
				if err~=nil then--出错重新下载
					break
				end
			end
			--投资人信息
			--print("投资人信息")
			if entInfo["invertor"]==nil then
				entInfo,err=getInvertor(entInfo,query,cookies)
				if err~=nil then--出错重新下载
					break
				end
			end
			--变更信息
			--print("变更信息")
			if entInfo["alterInfo"]==nil then
				entInfo,err=getAlterInfo(entInfo,query,cookies)
				if err~=nil then--出错重新下载
					break
				end
			end
			--主要人员
			--print("主要人员")
			if entInfo["staffinfo"]==nil then
				entInfo,err=getStaffinfo(entInfo,query,cookies)
				if err~=nil then--出错重新下载
					break
				end
			end
			--分支机构
			--print("分支机构")
			if entInfo["childent"]==nil then
				entInfo,err=getChildent(entInfo,query,cookies)
				if err~=nil then--出错重新下载
					break
				end
			end
			--行政处罚
			--print("行政处罚")	
			if entInfo["punishInfo"]==nil then
				entInfo,err=getPunishInfo(entInfo,query,cookies)
				if err~=nil then--出错重新下载
					break
				end
			end
			--异常名录	
			--print("异常名录")	
			if entInfo["excDirec"]==nil then
				entInfo,err=getExcDirec(entInfo,query,cookies)
				if err~=nil then--出错重新下载
					break
				end
			end
			--年报
			--print("年报")		
			if entInfo["qynb"]==nil then
				entInfo,err=getNbList(entInfo,query,cookies)
				if err~=nil then--出错重新下载
					break
				end
			end
			--去冗余字段
			entInfo["pripid"]=nil
			entInfo["publishtime"]=nil
			--验证数据
			local b=checkInfo(entInfo,data)  
			if b then
				print(spiderCode,"下载完成",data["title"],entInfo["EntName"])
				return entInfo
			else
				return nil
			end
		end
	end
	return nil
end

 
--获取验证码
function getCode(href,method,param,head,cookies)
	local code=""
	for i=1,5 do
		local content,_= downloadAdv(href,method,param,head,cookies)
		if content~=nil then
			code= getEcpsCode("ln",content)	
			break
		end
	end
	return code
end

--获取查询到的企业
function getEntTmp(href,method,param,head,cookies)
	local content,_ = downloadAdv(href,method,param,head,cookies)
	--print("content",content)
	local i=string.find(content,"var codevalidator= \"fail\"")
	if i==nil then
		str="{"..com.regTab(content,"searchList_paging%(%[([^%]]*)%]").."}"
		str=com.eval(str)
		local entTmp={}
		for k,v in pairs(str) do
			entTmp["pripid"]=v.pripid
			entTmp["title"]=v.entname
			entTmp["regno"]=v.regno
			entTmp["EntType"]=v.enttype
			break
		end
		if entTmp.regno~=nil then--查询有结果集
			return entTmp,nil
		else--查询无结果集
			return nil,nil
		end
	else--验证码错误
		print("验证码错误")
		return nil,"err"
	end 	
end

--获取企业基本信息
function getBaseInfo(entInfo,param,cookies)
	local con,_= downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getJbxxAction.action","get",param,{},cookies)
	local th=findListText("div#jibenxinxi table.detailsList tr th",con)
	local td=findListText("div#jibenxinxi table.detailsList tr td",con)
	local tab={}
	for k,v in pairs(th) do
		if k>1 then
			local tdv=com.trim(td[k-1])
			tab[com.trim(v)]=tdv
			--print(com.trim(v),tab[com.trim(v)])
		end
	end
	local baseinfo=ecps.reversalFormat(tab,ecps.baseFm,ecps.baseMap)
 	local keynum=0
	for k,v in pairs(baseinfo) do
		entInfo[k]=v
		--print(k,v)
		keynum=keynum+1
	end
	
	if keynum>5 then
		return entInfo,nil
	else
		return entInfo,"err"
	end
end

--获取投资人信息
function getInvertor(entInfo,param,cookies)
	local con,_= downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getTzrxxAction.action","get",param,{},cookies)
	local investors={}
	local str="{"..com.regTab(con,"tzr_paging%(%[([^%]]*)%]").."}"
	--print("获取投资人信息",str)
	str=com.eval(str)
	for k,v in pairs(str) do
		local inverstor={}
		inverstor["Inv"]=v.inv--股东
		inverstor["InvTypeName"]=v.invtypeName--股东类型名称
		inverstor["BLicNO"]=v.blicno--股东证件号
		inverstor["BLicTypeName"]=v.blictypeName--股东证件号名称
		table.insert(investors, inverstor)
	end
	entInfo["invertor"]=investors
	return entInfo,nil
end

--获取变更信息
function getAlterInfo(entInfo,param,cookies)
	local con,_= downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getBgxxAction.action","get",param,{},cookies)
	local alterInfos={}
	local str="{"..com.regTab(con,"paging%(%[([^%]]*)%]").."}"
	str=com.eval(str)
	for k,v in pairs(str) do
		local alterInfo={}
		alterInfo["AltAf"]=v.altaf--变更内容
		alterInfo["AltBe"]=v.altbe--变更前内容
		alterInfo["AltDate"]=v.altdate--变更日期
		alterInfo["AltItemName"]=v.altitemName--变更事项名
		alterInfo["AltItem"]=v.altitem--变更事项
		table.insert(alterInfos, alterInfo)
	end
	entInfo["alterInfo"]=alterInfos
	return entInfo,nil
end

--主要人员
function getStaffinfo(entInfo,param,cookies)
	local con,_= downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getZyryxxAction.action","get",param,{},cookies)
	local staffinfos={}
	local str="{"..com.regTab(con,"zyry_nz_paging%(%[([^%]]*)%]").."}"
	--print("主要人员",con,str)
	str=com.eval(str)
	for k,v in pairs(str) do
		local staffinfo={}
		staffinfo["Name"]=v.name--名称
		staffinfo["Position"]=v.position--职位
		staffinfo["PositionName"]=v.positionName--职位名称
		table.insert(staffinfos, staffinfo)
	end
	entInfo["staffinfo"]=staffinfos
	return entInfo,nil
end

--分支机构childent
function getChildent(entInfo,param,cookies)
	local con,_= downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getFgsxxAction.action","get",param,{},cookies)
	local childents={}
	local str="{"..com.regTab(con,"fzjgPaging%(%[([^%]]*)%]").."}"
	--print(str)
	str=com.eval(str)
	for k,v in pairs(str) do
		local childent={}
		childent["BrName"]=v.brname--分支名称
		childent["RegNO"]=v.regno--注册号
		childent["RegOrgName"]=v.regorgName--分支所属机构
		table.insert(childents, childent)
	end
	entInfo["childent"]=childents
	return entInfo,nil
end

--清算信息 liquidationo
function getLiquidationo(entInfo,param,cookies)
	local con,_= downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getQsxxAction.action","get",param,{},cookies)
	local liquidationos={}
	local str="{"..com.regTab(con,"_paging%(%[([^%]]*)%]").."}"
	--print(str)
	str=com.eval(str)
	for k,v in pairs(str) do
		local liquidationo={}
		liquidationo["LiqMem"]=v.liqMem--清算组
		liquidationo["LigPrincipal"]=v.ligPrincipal--清算负责
		table.insert(liquidationos, liquidationo)
	end
	entInfo["liquidationo"]=liquidationos
	return entInfo,nil
end

--行政处罚 punishInfo
function getPunishInfo(entInfo,param,cookies)
	local con,_= downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getXzcfxxAction.action","get",param,{},cookies)
	local punishInfos={}
	local str="{"..com.regTab(con,"xzcfPaging%(%[([^%]]*)%]").."}"
	--print(str)
	str=com.eval(str)
	for k,v in pairs(str) do
		local punishInfo={}
		punishInfo["PenDecNo"]=v.penDecNo--行政处罚号
		punishInfo["IllegActType"]=v.illegActType--处罚类型
		punishInfo["IllegActTypeName"]=v.illegActTypeName--类型名
		punishInfo["PenResult"]=v.penResult--处罚结果
		punishInfo["OrgName"]=v.orgName--机构
		punishInfo["PenDecIssDate"]=v.penDecIssDate--日期
		table.insert(punishInfos, punishInfo)
	end
	entInfo["punishInfo"]=punishInfos
	return entInfo,nil
end

--经营异常 excDirec
function getExcDirec(entInfo,param,cookies)
	local con,_= downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getJyycxxAction.action","get",param,{},cookies)
	local excDirecs={}
	local str="{"..com.regTab(con,"jyyc_paging%(%[([^%]]*)%]").."}"
	--print(str)
	str=com.eval(str)
	for k,v in pairs(str) do
		local excDirec={}
		excDirec["DecOrg"]=v.lrregorgName--处罚机构
		excDirec["SpeCause"]=v.specauseName--列入原因		
		excDirec["AbnTime"]=v.abnDate--列入时间
		excDirec["OutSpeTime"]=v.remDate--移除时间
		excDirec["OutSpeCause"]=v.remexcpresName--移除原因
		table.insert(excDirecs, excDirec)
	end
	entInfo["excDirec"]=excDirecs
	return entInfo,nil
end

--年报列表
function getNbList(entInfo,param,cookies)
	local con,_= downloadAdv("http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/getQygsQynbxxAction.action","get",param,{},cookies)
	if  entInfo["EntType"]==nil then
		return nil
	end
	local nbinfos={}
	local str="{"..com.regTab(con,"qynbPaging%(%[([^%]]*)%]").."}"
	str=com.eval(str)
	for k,v in pairs(str) do
		local url="http://gsxt.lngs.gov.cn/saicpub/entPublicitySC/entPublicityDC/nbDeatil.action?artId="..v.artid.."&entType="..tostring(entInfo["EntType"])
		local content,_= downloadAdv(url,"get",{},{},cookies)
		local nbinfo=getExYear(content)
		if nbinfo~=nil  then
			nbinfo["ancheyear"]=v.ancheyear--年度
			--nbinfo["nbstate"]=v.nbstate
			table.insert(nbinfos, nbinfo)
		end
	end
	entInfo["qynb"]=nbinfos
	return entInfo,nil
end


--年报信息
function getExYear(con)
	local nb={}
	--年报基本信息
	local th=findListText("div#qufenkuang table:eq(0) tr th",con)
	local td=findListText("div#qufenkuang table:eq(0) tr td",con)
	--print(table.getn(td),table.getn(th))
	local tab={}
	for k,v in pairs(th) do
		if k>2 then
			tab[com.trim(v)]=com.trim(td[k-2])
			--print(k,com.trim(v),com.trim(td[k-2]))
		end
	end
	local nbbase=ecps.reversalFormat(tab,ecps.baseNbFm,ecps.baseNbMap)
	nb["base"]=nbbase
	
	--网站信息
	local strwz="{"..com.regTab(con,"swPaging%(%[([^%]]*)%]").."}"
	strwz=com.eval(strwz)
	local wzs={}
	for k,v in pairs(strwz) do
		local wz={}
		wz["typeName"]=v.typofwebName--类型
		wz["websitname"]=v.websitname--名称
		wz["domain"]=v.domain--网址
		table.insert(wzs, wz)
	end
	nb["website"]=wzs
	
	
	--股东及出资信息
	local strcz="{"..com.regTab(con,"czPaging%(%[([^%]]*)%]").."}"
	--print("strcz",strcz)
	strcz=com.eval(strcz)
	local gdczs={}
	for k,v in pairs(strcz) do
		local gdcz={}
		gdcz["inv"]=v.inv--股东
		gdcz["acConAm"]=v.liacconam --实缴出资额
		gdcz["realConDate"]=v.accondatelabel--实缴出资时间
		gdcz["realConForm"]=v.acconformvalue--实缴出资方式
		gdcz["subConAm"]=v.lisubconam--认缴出资额
		gdcz["subConAmForm"]=v.subconformvalue--认缴出资方式
		gdcz["subConAmDate"]=v.subcondatelabel--认缴出资时间
		table.insert(gdczs, gdcz)
	end
	nb["invs"]=gdczs
	
	
	--对外投资信息
	local strtz="{"..com.regTab(con,"tzPaging%(%[([^%]]*)%]").."}"
	--print("strtz",strtz)
	strtz=com.eval(strtz)
	local tzs={}
	for k,v in pairs(strtz) do
		local tz={}
		tz["name"]=v.inventname--投资设立企业或购买股权企业名称
		tz["regno"]=v.regno--统一社会信用代码/注册号
		table.insert(tzs, tz)
	end
	nb["investment"]=tzs
	
	
	--企业资产状况信息
	local qyzc={}
	local tab=findListHtml("div#qufenkuang table",con)
	for k,v in pairs(tab) do
		local tname=com.trim(findOneText("th:eq(0)","<table>"..v.."</table>"))
		if tname=="企业资产状况信息" then
			local tmp=findOneHtml("div#qufenkuang table:eq("..tostring(k-1)..")",con)
			--资产总额			
			local assets=com.trim(findOneText("tr:eq(1):td:eq(0)","<table>"..tmp.."</table>"))
			qyzc["assets"]=assets			
			--所有者权益合计		
			local equity=com.trim(findOneText("tr:eq(1):td:eq(1)","<table>"..tmp.."</table>"))
			qyzc["equity"]=equity		
			--营业总收入
			local incometotal=com.trim(findOneText("tr:eq(2):td:eq(0)","<table>"..tmp.."</table>"))
			qyzc["incometotal"]=incometotal				
			--利润总额
			local profitotal=com.trim(findOneText("tr:eq(2):td:eq(1)","<table>"..tmp.."</table>"))
			qyzc["profitotal"]=profitotal				
			--营业总收入中主营业务收入
			local mainincome=com.trim(findOneText("tr:eq(3):td:eq(0)","<table>"..tmp.."</table>"))
			qyzc["mainincome"]=mainincome				
			--净利润
			local netprofit=com.trim(findOneText("tr:eq(3):td:eq(1)","<table>"..tmp.."</table>"))
			qyzc["netprofit"]=netprofit				
			--纳税总额
			local taxtotal=com.trim(findOneText("tr:eq(4):td:eq(0)","<table>"..tmp.."</table>"))
			qyzc["taxtotal"]=taxtotal				
			--负债总额
			local debtstotal=com.trim(findOneText("tr:eq(4):td:eq(1)","<table>"..tmp.."</table>"))										
			qyzc["debtstotal"]=debtstotal	
		end
	end
	nb["assetstatus"]=qyzc
	
	
	--对外提供保证担保信息
	local strdb="{"..com.regTab(con,"dbPaging%(%[([^%]]*)%]").."}"
	--print("strdb",strdb)
	strdb=com.eval(strdb)
	local dbs={}
	for k,v in pairs(strdb) do
		local db={}
		db["more"]=v.more --债权人
		db["mortgagor"]=v.mortgagor --债务人
		db["priclaseckindvalue"]=v.priclaseckindvalue --主债权种类				
		db["priclasecam"]=v.priclasecam --主债权数额
		db["pefperformandto"]=v.pefperformandto --履行债务的期限
		db["guaranperiodvalue"]=v.guaranperiodvalue --保证的期间
		db["gatypevalue"]=v.gatypevalue --保证的方式
		db["ragevalue"]=v.ragevalue --保证担保的范围
		table.insert(dbs, db)
	end
	nb["guarantees"]=dbs
	
	
	
	--股权变更信息
	local strbg="{"..com.regTab(con,"bgPaging%(%[([^%]]*)%]").."}"
	--print("strbg",strbg)
	strbg=com.eval(strbg)
	local bgs={}
	for k,v in pairs(strbg) do
		local bg={}
		bg["inv"]=v.inv --股东
		bg["transbmpr"]=v.transbmpr --变更前股权比例
		bg["transampr"]=v.transampr --变更后股权比例				
		bg["altdate"]=v.altdatelabel --股权变更日期
		table.insert(bgs, bg)
	end
	nb["equitychange"]=bgs
	
	
	--显示修改记录
	local strxg="{"..com.regTab(con,"xgPaging%(%[([^%]]*)%]").."}"
	--print("strxg",strxg)
	strxg=com.eval(strxg)
	local xgs={}
	for k,v in pairs(strxg) do
		local xg={}
		xg["alt"]=v.alt --修改事项			
		xg["altbe"]=v.altbe --修改前
		xg["altaf"]=v.altaf --修改后				
		xg["altdate"]=v.getAltdatevalue --修改日期
		table.insert(xgs, xg)
	end
	nb["modifys"]=xgs
	return nb
end

--验证下载信息
function checkInfo(ent,data)
	if ent["EntName"]==data["title"] then
		return true
	else
		return false
	end
end

