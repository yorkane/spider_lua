--[[
企明星爬虫系统，公共文件
Author:zjk
Date:2016/4/19
]]

ecps={}
--键值反转table
function ecps.reversalFormat(tab,frtab,totab)
	local tmpfrtab={}
	for k,v in pairs(frtab) do
		for k2,v2 in pairs(tab) do
			if string.match(k,k2)~=nil and string.match(k,k2)~="" then
				tmpfrtab[k]=tab[k2]
				break
			end	
		end
	end
	local tmptotab={}
	for k,v in pairs(totab) do
		tmptotab[k]=tmpfrtab[v]
		if k==tmpfrtab[v] then
			tmptotab[k]=""
		end
	end
	return tmptotab
end

--企业基本信息表单 
ecps.baseFm={
	["统一社会信用代码/注册号/统一社会信用代码"]="RegNo",["名称"]="EntName",["类型"]="EntTypeName",
	["注册资本/成员出资总额"]="RegCap",
	["法定代表人/负责人/经营者/投资人/执行事务合伙人/执行事务合伙人(委派代表)"]="LeRep", 
	["成立日期/注册日期"]="EstDate",
	["核准日期/发照日期/吊销日期"]="IssBLicDate",
	["营业期限自/经营期限自/合伙期限自"]="OpFrom",
	["营业期限至/经营期限至/合伙期限至"]="OpTo",
	["住所"]="Dom",["经营场所/主要经营场所/营业场所"]="OpLoc",
	["经营范围/业务范围"]="OpScope",
	["登记机关"]="RegOrg",["登记状态"]="OpState",
} 
ecps.baseMap={
	["RegNo"]="统一社会信用代码/注册号/统一社会信用代码",["EntName"]="名称",["EntTypeName"]="类型",
	["RegCap"]="注册资本/成员出资总额",
	["LeRep"]="法定代表人/负责人/经营者/投资人/执行事务合伙人/执行事务合伙人(委派代表)",
	["EstDate"]="成立日期/注册日期",
	["IssBLicDate"]="核准日期/发照日期/吊销日期",
	["OpFrom"]="营业期限自/经营期限自/合伙期限自",
	["OpTo"]="营业期限至/经营期限至/合伙期限至",
	["Dom"]="住所",["OpLoc"]="经营场所/主要经营场所/营业场所",
	["OpScope"]="经营范围/业务范围",
	["RegOrg"]="登记机关",["OpState"]="登记状态",
}
ecps.baseNbFm={
	["统一社会信用代码/注册号"]="RegNo",
	["企业名称"]="EntName",["企业联系电话"]="Tel",["邮政编码"]="postcode",
	["企业通信地址"]="address",["电子邮箱"]="email",
	["有限责任公司本年度是否发生股东股权转让"]="equityTransfer",
	["企业经营状态"]="state", 
	["是否有网站或网店"]="hasWebsite",
	["企业是否有投资信息或购买其他公司股权"]="hasInv",
	["是否有对外担保信息"]="hasGuarantee",
	["从业人数"]="numPeople",
} 
ecps.baseNbMap={
	["RegNo"]="统一社会信用代码/注册号",
	["EntName"]="企业名称",["Tel"]="企业联系电话",["postcode"]="邮政编码",
	["address"]="企业通信地址",["email"]="电子邮箱",
	["equityTransfer"]="有限责任公司本年度是否发生股东股权转让",
	["state"]="企业经营状态",
	["hasWebsite"]="是否有网站或网店",
	["hasInv"]="企业是否有投资信息或购买其他公司股权",
	["hasGuarantee"]="是否有对外担保信息",
	["numPeople"]="从业人数",
} 
--通用方法结束
return ecps;


