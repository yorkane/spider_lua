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


--	local entMl=getEntNames("ecps_bj")
--	print("北京企业名录长度:",tostring(table.getn(entMl)))
--	if table.getn(entMl)==0 then
--		print("北京企业名录为0","开始下异常名录")
--		local content,cookies = downloadAdv("http://qyxy.baic.gov.cn/beijing","get",{},{},"")
--		local head={
--				["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
--				["Accept-Encoding"]="gzip,deflate,sdch",
--				["Accept-Language"]="zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
--				["Cache-Control"]="no-cache",
--				["Host"]="qyxy.baic.gov.cn",
--				["Pragma"]="no-cache",
--				["Referer"]="http://qyxy.baic.gov.cn/beijing",
--				["Cookie"]=cookies,
--				["User-Agent"]="Mozilla/.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.130 Safari/537.36"	
--		}
--		local param={
--			["querystr"]="请输入企业名称或注册号",
--			["pageNos"]=tostring(pageno),
--			["pageNo"]="1",
--			["pageSize"]="10",
--			["clear"]=""
--		}
	
--		local con,_=downloadAdv("http://qyxy.baic.gov.cn/dito/ditoAction!ycmlFrame.dhtml","post",param,head,cookies)	
		
--		if con=="" then 
--			print("下载北京异常名录出错")
--			return entMl
--		end
--		local listHtml=findListHtml("table.ccjcList tr",con)
	 
		
--		for k,v in pairs(listHtml) do
--			if k>1 and k<table.getn(listHtml) then
--				item={}
--				item["title"]="td:eq(0) a:eq(0)"
--				item["regno"]="td:eq(1)"
--				item=findMap(item,"<table>><tr>"..v.."</tr></table>")
--				item["href"]="http://qyxy.baic.gov.cn/CheckCodeCaptcha" --验证码
--				table.insert(entMl,item)
--				--print(item["title"],item["regno"])
--			end
--		end
--	end
--	return entMl

--测试代码
	local entMl={}
	for i=0,1 do
				item={}
				item["title"]="北京神州泰岳软件股份有限公司"
				item["href"]="http://qyxy.baic.gov.cn/CheckCodeCaptcha" --验证码
				table.insert(entMl,item)
	end
	return entMl
--测试代码结束
end



--下载三级页,分析三级页downloadAdv(href,method,param,head,cookies)
function downloadDetailPage(data)
	data.href="http://qyxy.baic.gov.cn/CheckCodeCaptcha";
	for i=1,100 do
		local downloadId=changeDownloader()
		print("北京切换完下载点:",downloadId)
		for j=0,1 do--死循环
			--获取cookies
			local head={
				["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
				["Accept-Encoding"]="gzip,deflate,sdch",
				["Accept-Language"]="zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
				["Cache-Control"]="no-cache",
				["Host"]="qyxy.baic.gov.cn",
				["Pragma"]="no-cache",
				["Upgrade-Insecure-Requests"]="1",
				["User-Agent"]="Mozilla/.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.130 Safari/537.36"	
			}
			local content,cookies = downloadAdv("http://qyxy.baic.gov.cn/beijing","get",{},head,"")
			if content=="" then
			    print("访问北京首页出错*********************",data["title"])
				timeSleep(8)
				break
			end
			local credit_ticket=findOneText("input#credit_ticket:attr(value)",content)
			local current_timemillis=findOneText("input#currentTimeMillis:attr(value)",content)
			local param={}
			math.randomseed(os.clock()*10000) 
			param["num"]=tostring(math.random(1,10000))
			param["currentTimeMillis"]=current_timemillis
			--print("开始下验证码: "..data["title"])
			local code= getCode(data["href"],"get",param,{},cookies)
			if code=="error" then
				timeSleep(8)
				break
			end
			print("获取到验证码,开始校验"..code,"  ",data["title"])
			--验证码校验
			local isSuccess=codeCheck(cookies,current_timemillis,data["title"],code)
			if isSuccess=="success" then
				param["checkcode"]=code
				param["keyword"]=data["title"]
				param["credit_ticket"]=credit_ticket
				local entTmp=getEntTmp(param,cookies)-- 获取通过验证码之后的企业名称列表页基本信息
				if entTmp~=nil then
--					for k,v in pairs(entTmp) do
--						local detailUrl="http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!openEntInfo.dhtml?entId="..entTmp[k][2].."&credit_ticket="..com.trim(entTmp[k][4]).."&entNo="..entTmp[k][3].."&timeStamp="..tostring(os.time())
--						local param2={}
--						param2["entId"]=entTmp[k][2]
--						param2["credit_ticket"]=com.trim(entTmp[k][4])
--						param2["entNo"]=entTmp[k][3]
--						param2["timeStamp"]=tostring(os.time())
--						local entInfo={}
--						entInfo["entId"]=entTmp[k][2]
--						local errorMsg=getEntDetail(detailUrl,param2,cookies,entInfo)
--							if errorMsg=="error" then
--								print("下载 ",data["title"]," 详情页面出错")
--								break
--							end
--						return entInfo
--					end
					local detailUrl="http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!openEntInfo.dhtml?entId="..entTmp[2].."&credit_ticket="..com.trim(entTmp[4]).."&entNo="..entTmp[3].."&timeStamp="..tostring(os.time())
					local param2={}
					param2["entId"]=entTmp[2]
					param2["credit_ticket"]=com.trim(entTmp[4])
					param2["entNo"]=entTmp[3]
					param2["timeStamp"]=tostring(os.time())
					local entInfo={}
					entInfo["entId"]=entTmp[2]
					local errorMsg=getEntDetail(detailUrl,param2,cookies,entInfo)
						if errorMsg=="error" then
							print("下载 ",data["title"]," 详情页面出错")
							break
						end
					if entInfo["Area"]~="BJ" then
						print("下载",entTmp[2]," 详细信息不完整，丢弃")
						return nil
					else
						return entInfo
					end
					
					
				elseif entTmp=="error" then
					timeSleep(8)
					break
				else
					print("企业不存在return nil")
					return nil
				end
			elseif isSuccess=="error" then
					timeSleep(8)
					break
			else
				print("验证码错误,重新请求.....")
				--timeSleep(8)
				break
			end
		end
	end
end

--获取验证码
function getCode(href,method,param,head,cookies)
	--print("获取验证码url:"..href.."参数:"..param["currentTimeMillis"])
	 local head2={
			["Accept"]="image/webp,image/*,*/*;q=0.8",
			["Accept-Encoding"]="gzip,deflate,sdch",
			["Accept-Language"]="zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
			["Cache-Control"]="no-cache",
			
			["Host"]="qyxy.baic.gov.cn",
			["Pragma"]="no-cache",
			["Referer"]="http://qyxy.baic.gov.cn/beijing",
			["Cookie"]=cookies,
			["User-Agent"]="Mozilla/.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.130 Safari/537.36"	
	}
	local content,_= downloadAdv(href,method,param,head2,cookies)
	if content=="" then
		print("获取验证码图片出错")
		return "error"
	end
	local code= getEcpsCode("bj",content)
	return code
end

function getEntTmp(param,cookies)
	local getEntListUrl="http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!getBjQyList.dhtml"
	local head={
			["Host"]="qyxy.baic.gov.cn",
			["Referer"]="http://qyxy.baic.gov.cn/beijing",
			["Pragma"]="no-cache",
			["Cache-Control"]="no-cache",
			["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
			["Origin"]="http://qyxy.baic.gov.cn",
			["Upgrade-Insecure-Requests"]="1",
			["User-Agent"]="Mozilla/.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.130 Safari/537.36",
			["Content-Type"]="application/x-www-form-urlencoded",
			["Referer"]="http://qyxy.baic.gov.cn/beijing",
			["Accept-Encoding"]="gzip, deflate",
			["Cookie"]=cookies,
			["Accept-Language"]="zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4"
			}
			--print("getEntListUrl:",getEntListUrl)
			--print("param:",param["credit_ticket"],param["keyword"],param["checkcode"])
	local entListContent,_=downloadAdv(getEntListUrl,"post",param,head,cookies);
	if entListContent=="" then
		print("根据名称查询企业临时列表出错，返回。。。")
		return "error"
	end
	
	local list = findListHtml("div.list>ul",entListContent)
	
	--local entTmp={}
	if table.getn(list)>0 then
		for k, v in pairs(list) do
			local item={}
			item["entName"]="a:eq(0)"
			item["onclick"]="a:eq(0):attr(onclick)"
			item=findMap(item,v)
			item["onclick"]=string.gsub(item["onclick"], "openEntInfo%(", "")
			item["onclick"]=string.gsub(item["onclick"], "%);", "")
			local tmp=com.split(item["onclick"],",")
			--tmp是企业信息数组 tmp[1]＝企业名称  tmp[2]=企业id tmp[3]=注册号 tmp[4]=credit_ticket
			for k, v in pairs(tmp) do
				tmp[k]=strDel(v)--除掉前后的单引号
			end
			if tmp[1]==param["keyword"] then
				print("找到名称",tmp[1],"  返回开始查询详情")
				return tmp
			end
			--entTmp[k]=tmp
		end
		--return entTmp
		return nil
	else
		return nil
	end
	
end


function getEntDetail(url,param,cookies,entInfo)
	
 	local head={
			["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
			["Accept-Encoding"]="gzip, deflate",
			["Accept-Language"]="zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4",
			["Host"]="qyxy.baic.gov.cn",
			["Pragma"]="no-cache",
			["Cache-Control"]="no-cache",
			["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
			["Upgrade-Insecure-Requests"]="1",
			["User-Agent"]="Mozilla/.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.130 Safari/537.36",
			["Content-Type"]="application/x-www-form-urlencoded",
			["Referer"]="http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!getBjQyList.dhtml",
			["Cookie"]=cookies
			}
	local content,_=downloadAdv(url,"get",param,head,cookies);
	if content=="" then
		print("查询企业基本信息请求出错")
		return "error"
	end
	entInfo["Area"]="BJ"
	--基本信息
	entInfo=getBaseInfo(content,entInfo)
	
	--投资人(股东信息)
	local query={["ent_id"]=entInfo["entId"],["clear"]="true",["timeStamp"]=tostring(os.time()),["entName"]="",["pageNos"]="1",["pageSize"]="5",["pageNo"]="10",["fqr"]=""}
	local content,_= downloadAdv("http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!tzrFrame.dhtml","post",query,head,cookies)
	if content=="" then
		print("查询企业投资人信息请求出错")
		return "error"
	end
	local invertors=getInvertor(content)--先获取第一页数据
	local tmp=findOneText("input#pagescount:attr(value)",content)
	--print("投资人分页总数:"..tmp)
	local _tmp = tonumber(tmp);
	if _tmp~=nil then
		if _tmp>1 then
			for i=2,_tmp do
				--print("开始下载第"..tostring(i).."页")
				local query={["ent_id"]=entInfo["entId"],["clear"]="true",["timeStamp"]=tostring(os.time()),["entName"]="",["pageNos"]=tostring(i),["pageSize"]="5",["pageNo"]="10",["fqr"]=""}
				local content,_= downloadAdv("http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!tzrFrame.dhtml","post",query,head,cookies)
				local _invertors=getInvertor(content)
				for k,v in pairs(_invertors) do
					table.insert(invertors,v)
				end
			end
		end
	end
--	print(table.getn(invertors))
--	for k,v in pairs(invertors) do
--		print(v["Inv"])
--	end
	entInfo["invertor"]=invertors
	
	--变更信息
	local query={["ent_id"]=entInfo["entId"],["clear"]="true",["timeStamp"]=tostring(os.time())}
	local content,_= downloadAdv("http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!biangengFrame.dhtml","get",query,head,cookies)
	if content=="" then
		print("查询变更信息请求出错")
		return "error"
	end
	local alterInfos=getAlterInfo(content,head)--先获取第一页数据	
	if alterInfos=="error" then
		return "error"
	end
	
	local tmp=findOneText("input#pagescount:attr(value)",content)
	--print("变更信息分页总数:"..tmp)
	local _tmp = tonumber(tmp);
	if _tmp~=nil then
		if _tmp>1 then
			for i=2,_tmp do
				--print("开始下载第"..tostring(i).."页")
				local query={["ent_id"]=entInfo["entId"],["clear"]="",["timeStamp"]=tostring(os.time()),["pageNos"]=tostring(i),["pageSize"]="5",["pageNo"]="10"}
				local content,_= downloadAdv("http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!biangengFrame.dhtml","post",query,head,cookies)
				local _alterInfos=getAlterInfo(content,head)
				for k,v in pairs(_alterInfos) do
					table.insert(alterInfos,v)
				end
			end
		end
	end
			
	entInfo["alterInfo"]=alterInfos
	
	--主要人员
	local query={["ent_id"]=entInfo["entId"],["clear"]="true",["timeStamp"]=tostring(os.time())}
	local content,_= downloadAdv("http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!zyryFrame.dhtml","post",query,head,cookies)
	
	if content=="" then
		print("查询主要人员信息请求出错")
		return "error"
	end
	local staffinfos=getStaffinfo(content)--先获取第一页数据	
	local tmp=findOneText("input#pagescount:attr(value)",content)
	local _tmp = tonumber(tmp);
	if _tmp~=nil then
		if _tmp>1 then
			for i=2,_tmp do
				local query={["ent_id"]=entInfo["entId"],["clear"]="",["timeStamp"]=tostring(os.time()),["pageNos"]=tostring(i),["pageSize"]="5",["pageNo"]="10"}
				local content,_= downloadAdv("http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!zyryFrame.dhtml","post",query,head,cookies)
				local _staffinfos=getStaffinfo(content,head)
				for k,v in pairs(_staffinfos) do
					table.insert(staffinfos,v)
				end
			end
		end
	end
						
	entInfo["staffinfo"]=staffinfos
	
	
	--分支机构
	--行政处罚
	--经营异常
	local query={["entId"]=entInfo["entId"],["clear"]="true",["timeStamp"]=tostring(os.time())}
	local content,_= downloadAdv("http://qyxy.baic.gov.cn/gsgs/gsxzcfAction!list_jyycxx.dhtml","get",query,head,cookies)
	if content=="" then
		print("查询经营异常信息请求出错")
		return "error"
	end
	
	local excDirec=getExcDirec(content)					
	entInfo["excDirec"]=excDirec
--	for k,v in pairs(excDirec) do
--		print(v["SpeCause"],v["AbnTime"],v["DecOrg"],v["OutSpeCause"],v["OutSpeTim"],v["OutDecOrg"])
--	end
	
	
	
	
	
	--年报
	local query={["entid"]=entInfo["entId"],["clear"]="true",["timeStamp"]=tostring(os.time())}
	local content,_= downloadAdv("http://qyxy.baic.gov.cn/qynb/entinfoAction!qyxx.dhtml","get",query,head,cookies)				
	if content=="" then
		print("查询年报列表content信息请求出错")
		return "error"
	end
	
	local nbtab=getNbList(content,head,cookies)
	if nbtab=="error" then
		print("查询年报列表信息请求出错")
		return "error"
	end
	entInfo["qynb"]=nbtab
	
	
end

--获取企业基本信息
function getBaseInfo(content,entInfo)
	local th=findListText("div#jbxx table.detailsList tr th",content)
	local td=findListText("div#jbxx table.detailsList tr td",content)
	local tab={}
	--print("changdu",table.getn(th),table.getn(td))
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

--获取投资人信息
function getInvertor(content)
	local investors={}
	--print(content)
	local list=findListHtml("table#touziren tbody#table2 tr",content)
	
	for k,v in pairs(list) do
		if k>1 then
			--print(v)
			item={}
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

--获取变更信息
function getAlterInfo(content,head)
	local alterInfos={}
	--print(content)
	local list=findListHtml("table#touziren tbody#table2 tr",content)
	local len=table.getn(list)
	--print("长度:"..len)
	for k,v in pairs(list) do
		if k>2 and k<len then
			item={}
			item["AltItemName"]="td:eq(0)"
			item["AltBe"]="td:eq(1)"
			item["AltAf"]="td:eq(2)"
			item["AltDate"]="td:eq(3)"
			item=findMap(item,"<table><tr>"..v.."</tr></table>")
			
			if item["AltDate"]==nil then
				--print(v)
				item={}
				--说明中间两列有合并，即变更数据需要再请求一次	
				item["AltItemName"]="td:eq(0)"
				item["AlterInfoHtml"]="td:eq(1) a:eq(0):attr(onclick)"
				item["AltDate"]="td:eq(2)"
				item=findMap(item,"<table><tr>"..v.."</tr></table>")
				--print(item["AlterInfoHtml"])
				item["AlterInfoHtml"]=string.gsub(item["AlterInfoHtml"], "showDialog%(", "")
				item["AlterInfoHtml"]=string.gsub(item["AlterInfoHtml"], "%);", "")
				item["AltBe"]=""
				item["AltAf"]=""
				local tmp=com.split(item["AlterInfoHtml"],",")
				local detailUrl="http://qyxy.baic.gov.cn"..strDel(tmp[1])
				--print(detailUrl)
				local _content,_=downloadAdv(detailUrl,"post",{},head,cookies)
				if _content=="" then
					print("获取变更信息详情出错")
					return "error"
				end
				--print(_content)
				local list1=findListHtml("table#tableIdStyle:eq(0) tbody tr",_content)
				for k,v in pairs(list1) do
					if k>2 then
						_item={}
						_item["xm"]="td:eq(1)" --姓名
						_item["zw"]="td:eq(2)" --职位
						_item=findMap(_item,"<table><tr>"..v.."</tr></table>")
						--print(_item["xm"]..":".._item["zw"])
						item["AltBe"]=item["AltBe"].._item["xm"].." : ".._item["zw"]..";"
					end
				end
				local list2=findListHtml("table#tableIdStyle:eq(1) tbody tr",_content)
				for k,v in pairs(list2) do
					if k>2 then
						_item={}
						_item["xm"]="td:eq(1)" --职位
						_item["zw"]="td:eq(2)" --姓名
						_item=findMap(_item,"<table><tr>"..v.."</tr></table>")
						item["AltAf"]=item["AltAf"].._item["xm"].." : ".._item["zw"]..";"
					end
				end
				--print("变更前:"..item["AltBe"].."  变更后:"..item["AltAf"])
				local alterInfo={}
				alterInfo["AltItemName"]=item["AltItemName"]
				alterInfo["AltAf"]=item["AltAf"]
				alterInfo["AltBe"]=item["AltBe"]
				alterInfo["AltDate"]=item["AltDate"]
				table.insert(alterInfos, alterInfo)
			else
				local alterInfo={}
				alterInfo["AltItemName"]=item["AltItemName"]
				alterInfo["AltAf"]=item["AltAf"]
				alterInfo["AltBe"]=item["AltBe"]
				alterInfo["AltDate"]=item["AltDate"]
				table.insert(alterInfos, alterInfo)	
				--print(alterInfo["AltItemName"].." "..alterInfo["AltBe"].." "..alterInfo["AltAf"].." "..alterInfo["AltDate"])
			end
		end
	end
	return alterInfos
end


function getStaffinfo(content)
	--print("获取主要人员信息:"..content)
	local staffinfos={}
	local list=findListHtml("table#touziren tbody#table2 tr",content)
	local len=table.getn(list)
	for k,v in pairs(list) do
		if k>2 and k<len then
			--print(v)  一行有两条数据 姓名1：职务1  姓名2：职务2  
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
--	for k,v in pairs(staffinfos)do
--		print(v["Name"]..v["Position"])
--	end
	return staffinfos

end

function getExcDirec(content)
	local excDirecs={}
	local list=findListHtml("table.detailsList tr",content)
	 
	for k,v in pairs(list) do
		if k>2 then
			local excDirec={}
			item={}
			item["DecOrg"]="td:eq(3)"
			item["SpeCause"]="td:eq(1)"
			item["AbnTime"]="td:eq(2)"
			item["OutSpeTim"]="td:eq(5)"
			item["OutSpeCause"]="td:eq(4)"
			item["OutDecOrg"]="td:eq(6)"
			item=findMap(item,"<table>><tr>"..v.."</tr></table>")
			excDirec["DecOrg"]=com.trim(item["DecOrg"])
			excDirec["SpeCause"]=com.trim(item["SpeCause"])	
			excDirec["AbnTime"]=com.trim(item["AbnTime"])
			excDirec["OutSpeTim"]=com.trim(item["OutSpeTim"])
			excDirec["OutSpeCause"]=com.trim(item["OutSpeCause"])
			excDirec["OutDecOrg"]=com.trim(item["OutDecOrg"])
			table.insert(excDirecs, excDirec)
		end
	end
	return excDirecs
end

--年报列表
function getNbList(content,head,cookies)
	--print("获取到年报html:",content)


	local nbinfos={}
	local list=findListHtml("div#qiyenianbao table.detailsList tr",content)
	--local len=table.getn(list)
	for k,v in pairs(list) do
		if k>2 then
			--print(v)
			local item={}
			item["url"]="td:eq(1) a:eq(0):attr(href)"
			item["year"]="td:eq(1) a:eq(0)"
			item=findMap(item,"<table><tr>"..v.."</tr></table>")
			--print(item["url"],item["year"])
			local detailUrl="http://qyxy.baic.gov.cn/"..item["url"]
			local cid=""
			local tmp=com.split(detailUrl,"&")
			for k, v in pairs(tmp) do
				if k==1 then
					local index=string.find(v,"cid=")
					cid=string.sub(v,index+4,string.len(v))
				end
			end
			--print("cid:"..cid)
			--os.exit(0)
			local _content,_=downloadAdv(detailUrl,"get",{},head,cookies)
			if content=="" then
				print("获取年报详情content出错,url:"..detailUrl)
				return "error"
			end
			
			--print("获取到年报信息:",_content)
			local nbinfo=getExYear(_content,item["year"],cid,head,cookies)
			if nbinfo=="error" then
				print("获取年报详情出错")
				return "error"
			end
			
			
			if nbinfo~=nil  then
				nbinfo["ancheyear"]=item["year"]
				table.insert(nbinfos, 1, nbinfo)
			end
		end
	end
	return nbinfos
end


--年报信息
function getExYear(con,year,cid,head,cookies)
	local nb={}
	--年报基本信息
	local th=findListText("div#qufenkuang table.detailsList:eq(0) tr th",con)
	local td=findListText("div#qufenkuang table.detailsList:eq(0) tr td",con)
	--print(table.getn(td),table.getn(th))
	local tab={}
	for k,v in pairs(th) do
		if k>2 then
			--print(v)
			tab[com.trim(v)]=com.trim(td[k-2])
			--print(k,com.trim(v),com.trim(td[k-2]))
		end
	end
	local nbbase=ecps.reversalFormat(tab,ecps.baseNbFm,ecps.baseNbMap)
	nb["base"]=nbbase
	
	
	--网站信息
	local webUrl="http://qyxy.baic.gov.cn/entPub/entPubAction!wz_bj.dhtml?clear=true&cid="..cid
	--print(webUrl,head,cookies)
	local _content,_=downloadAdv(webUrl,"get",{},head,cookies)
	if _content=="" then
		print("获取年报网站信息出错")
		return "error"
	end
	--print("获取到网站信息:",_content)
	local list=findListHtml("table#touziren  tr",_content)
	local len=table.getn(list)
	--print("长度:"..len)
	local wzs={}
	for k,v in pairs(list) do
		if k>2 and k<len then
			local item={}
			item["typeName"]="td:eq(0)"
			item["websitname"]="td:eq(1)"
			item["domain"]="td:eq(2)"
			item=findMap(item,"<table><tr>"..v.."</tr></table>")
			local wz={}
			wz["typeName"]=com.trim(item["typeName"])
			wz["websitname"]=com.trim(item["websitname"])
			wz["domain"]=com.trim(item["domain"])
			--print(wz["typeName"],wz["websitname"],wz["domain"])
			table.insert(wzs, 1, wz)
		end
	end
	nb["website"]=wzs
	
	
	
	--股东及出资信息
	local gdczUrl="http://qyxy.baic.gov.cn/entPub/entPubAction!gdcz_bj.dhtml?clear=true&cid="..cid.."&entnature="
	local _content,_=downloadAdv(gdczUrl,"get",{},head,cookies)--先下载第一页
	if _content=="" then
		print("获取年报股东及出资信息出错")
		return "error"
	end
	local gdczs=getNbGdczInfo(_content)--先获取第一页数据
	local tmp=findOneText("input#pagescount:attr(value)",_content)
	--print("股东及出资信息分页总数:"..tmp)
	local _tmp = tonumber(tmp);
	if _tmp~=nil then
		if _tmp>1 then
			for i=2,_tmp do
				local query={["cid"]=cid,["entid"]="",["clear"]="",["pageNos"]=tostring(i),["pageSize"]="5",["pageNo"]="1"}
				local content,_= downloadAdv("http://qyxy.baic.gov.cn/entPub/entPubAction!gdcz_bj.dhtml","post",query,head,cookies)
				local _gdczs=getNbGdczInfo(content)
				for k,v in pairs(_gdczs) do
					table.insert(gdczs,v)
				end
			end
		end
	end
	
	nb["invs"]=gdczs
--	for k,v in pairs(gdczs) do
--		print(v["inv"],v["acConAm"],v["realConDate"],v["realConForm"],v["subConAm"],v["subConAmForm"],v["subConAmDate"])
--	end
--	os.exit(0)
	
	
	
	--对外投资信息
	local dwtzUrl="http://qyxy.baic.gov.cn/entPub/entPubAction!dwtz_bj.dhtml?clear=true&cid="..cid
	local _content,_=downloadAdv(dwtzUrl,"get",{},head,cookies)--先下载第一页
	if _content=="" then
		print("获取年报对外投资信息出错")
		return "error"
	end
	--print("获取到对外投资html:",_content)
	local tzs=getNbDwtzInfo(_content)--先获取第一页数据
	local tmp=findOneText("input#pagescount:attr(value)",_content)
	--print("对外投资信息分页总数:"..tmp)
	local _tmp = tonumber(tmp);
	
	if _tmp~=nil then
		if _tmp>1 then
			for i=2,_tmp do
				local query={["cid"]=cid,["entid"]="",["clear"]="",["pageNos"]=tostring(i),["pageSize"]="5",["pageNo"]="1"}
				local content,_= downloadAdv("http://qyxy.baic.gov.cn/entPub/entPubAction!dwtz_bj.dhtml","post",query,head,cookies)
				local _dwtzs=getNbDwtzInfo(content)
				for k,v in pairs(_dwtzs) do
					table.insert(tzs,v)
				end
			end
		end
	end
	
--	for k,v in pairs(tzs) do
--		print(v["name"],v["regno"])
--	end
	nb["investment"]=tzs
	
	
	--企业资产状况信息
	local qyzc={}
	local th=findListText("div#qufenkuang table.detailsList:eq(1) tr th",con)
	local td=findListText("div#qufenkuang table.detailsList:eq(1) tr td",con)
	for k,v in pairs(th) do
		if k>1 then
			--print(v)
			qyzc[com.trim(v)]=com.trim(td[k-1])
			--print(com.trim(td[k-1]))
		end
	end
	nb["assetstatus"]=qyzc
--	for k,v in pairs(qyzc) do
--		print(k..":"..v)
--	end


	--对外提供保证担保信息
	local dwdbUrl="http://qyxy.baic.gov.cn/entPub/entPubAction!qydwdb_bj.dhtml?clear=true&cid="..cid
	local _content,_=downloadAdv(dwdbUrl,"get",{},head,cookies)--先下载第一页
	if _content=="" then
		print("获取年报对外提供保证担保信息出错")
		return "error"
	end
	
	local dbs=getNbDwdbInfo(_content)--先获取第一页数据
	local tmp=findOneText("input#pagescount:attr(value)",_content)
	--print("对外提供保证担保信息分页总数:"..tmp)
	local _tmp = tonumber(tmp);
	if _tmp~=nil then
		if _tmp>1 then
			for i=2,_tmp do
				local query={["cid"]=cid,["clear"]="",["pageNos"]=tostring(i),["pageSize"]="5",["pageNo"]="1"}
				local content,_= downloadAdv("http://qyxy.baic.gov.cn/entPub/entPubAction!qydwdb_bj.dhtml","post",query,head,cookies)
				local _dwdbs=getNbDwdbInfo(content)
				for k,v in pairs(_dwdbs) do
					table.insert(dbs,v)
				end
			end
		end
	end
	nb["guarantees"]=dbs
--	for k,v in pairs(dbs) do
--		print(v["more"],v["mortgagor"],v["priclaseckindvalue"],v["priclasecam"],v["pefperformandto"],v["guaranperiodvalue"],v["gatypevalue"],v["ragevalue"])
--	end



	--修改记录
	local _year=string.gsub(year,"年度","")
	local xgjlUrl="http://qyxy.baic.gov.cn/entPub/entPubAction!qybg_bj.dhtml?clear=true&cid="..cid.."&year=".._year
	--print(xgjlUrl)
	local _content,_=downloadAdv(xgjlUrl,"get",{},head,cookies)--先下载第一页
	if _content=="" then
		print("获取年报修改记录出错")
		return "error"
	end
	local xgs=getNbXgjlInfo(_content)--先获取第一页数据
	local tmp=findOneText("input#pagescount:attr(value)",_content)
	--print("修改记录信息分页总数:"..tmp)
	local _tmp = tonumber(tmp);
	if _tmp~=nil then
		if _tmp>1 then
			for i=2,_tmp do
				local query={["cid"]=cid,["clear"]="",["year"]=_year,["pageNos"]=tostring(i),["pageSize"]="5",["pageNo"]="1"}
				local content,_= downloadAdv("http://qyxy.baic.gov.cn/entPub/entPubAction!qybg_bj.dhtml","post",query,head,cookies)
				local _xgs=getNbXgjlInfo(content)
				for k,v in pairs(_xgs) do
					table.insert(xgs,v)
				end
			end
		end
	end
	nb["modifys"]=xgs
--	for k,v in pairs(xgs) do
--		print(v["alt"])
--	end
	return nb



end


--分页获取年报当中的股东出资信息
function getNbGdczInfo(_content)
	local list=findListHtml("table#touziren  tr",_content)
	local len=table.getn(list)
	local gdczs={}
	for k,v in pairs(list) do
		if k>2 and k<len then
			local gdcz={}
			item={}
			item["inv"]="td:eq(0)"
			item["acConAm"]="td:eq(4)" 
			item["realConDate"]="td:eq(5)"
			item["realConForm"]="td:eq(6)"
			item["subConAm"]="td:eq(1)"
			item["subConAmForm"]="td:eq(3)"
			item["subConAmDate"]="td:eq(2)"
			item=findMap(item,"<table>><tr>"..v.."</tr></table>")
			gdcz["inv"]=com.trim(item["inv"])--股东
			gdcz["acConAm"]=com.trim(item["acConAm"]) --实缴出资额
			gdcz["realConDate"]=com.trim(item["realConDate"])--实缴出资时间
			gdcz["realConForm"]=com.trim(item["realConForm"])--实缴出资方式
			gdcz["subConAm"]=com.trim(item["subConAm"])--认缴出资额
			gdcz["subConAmForm"]=com.trim(item["subConAmForm"])--认缴出资方式
			gdcz["subConAmDate"]=com.trim(item["subConAmDate"])--认缴出资时间
			table.insert(gdczs,gdcz)
		end
	end
	return gdczs
end

--分页获取年报当中的对外投资信息
function getNbDwtzInfo(_content)
	local list=findListHtml("table#touziren  tr",_content)
	local len=table.getn(list)
	local dwtzs={}
	for k,v in pairs(list) do
		if k>2 and k<len then
			--print(v)
			local dwtz={}
			item={}
			item["name"]="td:eq(0)"
			item["regno"]="td:eq(1)" 
			item=findMap(item,"<table>><tr>"..v.."</tr></table>")
			dwtz["name"]=com.trim(item["name"])--名称
			dwtz["regno"]=com.trim(item["regno"]) --注册号
			table.insert(dwtzs,dwtz)
		end
	end
	return dwtzs
end



--分页获取年报当中对外担保信息
function getNbDwdbInfo(_content)
	local list=findListHtml("table#touziren  tr",_content)
	local len=table.getn(list)
	local dwdbs={}
	for k,v in pairs(list) do
		if k>2 and k<len then
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
	return dwdbs
end

--分页获取年报当中修改记录信息
function getNbXgjlInfo(_content)
	local list=findListHtml("table#touziren  tr",_content)
	local len=table.getn(list)
	local xgjls={}
	for k,v in pairs(list) do
		if k>2 and k<len then
			--print(v)
			local xgjl={}
			item={}
			item["alt"]="td:eq(1)"
			item["altbe"]="td:eq(2)"
			item["altaf"]="td:eq(3)"
			item["altdate"]="td:eq(4)"
			
			item=findMap(item,"<table>><tr>"..v.."</tr></table>")
			xgjl["alt"]=com.trim(item["alt"]) 
			xgjl["altbe"]=com.trim(item["altbe"])
			xgjl["altaf"]=com.trim(item["altaf"]) 
			xgjl["altdate"]=com.trim(item["altdate"])  
			table.insert(xgjls,xgjl)
		end
	end
	return xgjls
end
function strDel(str)
	str=string.gsub(str,"'","")
	return str
end



function codeCheck(cookies,currentTimeMillis,keyword,checkcode)
local codeCheckUrl="http://qyxy.baic.gov.cn/gjjbj/gjjQueryCreditAction!checkCode.dhtml"
		local head2={
			["Accept"]="*/*",
			["Host"]="qyxy.baic.gov.cn",
			
			["Pragma"]="no-cache",
			["Cache-Control"]="no-cache",
			["Accept"]="text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
			["Origin"]="http://qyxy.baic.gov.cn",
			["X-Requested-With"]="XMLHttpRequest",
			["User-Agent"]="Mozilla/.0 (Windows NT 6.3; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.130 Safari/537.36",
			["Content-Type"]="application/x-www-form-urlencoded; charset=UTF-8",
			["Referer"]="http://qyxy.baic.gov.cn/beijing",
			["Accept-Encoding"]="gzip, deflate",
			["Cookie"]=cookies,
			["Accept-Language"]="zh-CN,zh;q=0.8,en;q=0.6,zh-TW;q=0.4"
	}
	local param={
		["currentTimeMillis"]=currentTimeMillis,
		["checkcode"]=checkcode,
		["keyword"]=keyword
	}
	local isSuccessFul,_=downloadAdv(codeCheckUrl,"post",param,head2,cookies);
	if isSuccessFul=="" then
		print("验证码校验请求失败")
		return "error"
	end
	print("是否成功:"..isSuccessFul)
	return isSuccessFul
	

end