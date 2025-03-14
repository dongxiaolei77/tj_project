-- ---------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   dw_base.dwd_cust_coll_key_info
-- 源表     ：dw_nd.ods_coll_v_mid_ods_nyncj_cdlbhzs	农业厅-合作社名录              
           -- dw_nd.ods_coll_v_mid_ods_nyncj_ncxx	农业厅-农场数据      
           -- dw_nd.ods_coll_v_mid_ods_nyncj_sl_table11	农业厅-饲基11表      
           -- dw_nd.ods_coll_v_mid_ods_nyncj_sl_table12	农业厅-饲基12表        
           -- dw_nd.ods_coll_v_mid_ods_nyncj_sl_table13	农业厅-饲基13表        
           -- dw_nd.ods_coll_v_mid_ods_nyncj_sy_sc	农业厅-兽药生产         
           -- dw_nd.ods_coll_v_mid_ods_nyncj_sy_jy	农业厅-兽药销售        
           -- dw_nd.ods_coll_v_mid_cj_snzt_jcxx	农业厅-涉农主体通用     
           -- dw_nd.ods_coll_v_mid_ods_nyncj_yzxx	农业厅-规模化养殖       
           -- dw_nd.ods_coll_v_mid_ods_shengji_xmj	省级数据_畜牧局          
           -- dw_nd.ods_coll_v_ods_jcny_tdlz	农业厅-基层农业土地流转表
           -- dw_nd.ods_coll_v_mid_bxgs_bxmd	涉农保险                   
           -- dw_nd.ods_coll_v_ods_nyncj_qtsnztsj	其他涉农主体数据              
           -- dw_nd.ods_coll_mid_nyncj_ncpccbxxq	农产品仓储保鲜                   
           -- dw_nd.ods_coll_v_dim_ods_cdlbhzs	国家级农民专业合作社             
           -- dw_nd.ods_coll_v_ods_nd_cyds	农担创业大赛
           -- dw_nd.ods_data_access_cattle	黑牛管家--高青黑牛牛只信息
           -- dw_nd.ods_sjcjzl_v_cj_zzy_mylxx_zl   	经营类数据
-- 变更记录 ：  20220117统一修改
--            dw_nd.ods_sjcjzl_v_cj_zzy_zldh_zl 粮食购销 mdy 20220420 wyx
--            20220524 源表新增 dw_nd.ods_sjcjzl_v_cj_zzy_mylxx_zl   	经营类数据  zzy
-- ---------------------------------------

-- 核心信息
  delete from dw_base.dwd_cust_coll_key_info  where data_flag ='1';


insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,DWMC -- 客户姓名
,case when DWMC is null then '' 
      when length(DWMC) >= 12 then '2' 
	  else '1' end  -- 客户类型
,cert_type -- 证件类型
,NSRSBH -- 证件号码
,city_cd -- 地市代码
,SHI -- 地市
,county_cd -- 县区代码
,QX -- 县区
,town_cd -- 乡镇代码
,ZHEN -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,LXDH -- 联系电话
,LBSCJYXHZS -- 经营主业
,case when  (TDRGMS REGEXP '[^0-9.]') = '1' then null else TDRGMS end-- 规模
,HJ -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_ods_nyncj_cdlbhzs' -- 数据来源
,'农业厅-合作社名录' -- 数据来源中文
,'1'
from dw_nd.ods_coll_v_mid_ods_nyncj_cdlbhzs	-- 农业厅-合作社名录
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'

;
commit ;

insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,NCMC -- 客户姓名
,case when NCMC is null then '' 
      when length(NCMC) >= 12 then '2' 
	  else '1' end cust_type -- 客户类型
,cert_type -- 证件类型
,NSRSBH -- 证件号码
,city_cd -- 地市代码
,SHI -- 地市
,county_cd -- 县区代码
,XIAN -- 县区
,town_cd -- 乡镇代码
,XIANG -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,SJH -- 联系电话
,case when JYLX ='1' then '种植业'
      when JYLX ='2' then '林业'
      when JYLX ='3' then '畜牧业'
      when JYLX ='4' then '渔业'
      when JYLX ='5' then '种养结合'
      when JYLX ='6' then '其他'
      end	   -- 经营主业
,GDMJ -- 规模
,NDZSR -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_ods_nyncj_ncxx' -- 数据来源
,'农业厅-农场数据' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_ods_nyncj_ncxx	-- 农业厅-农场数据
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;

commit ;


insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,DWMC -- 客户姓名
,case when DWMC is null then '' 
      when length(DWMC) >= 12 then '2' 
	  else '1' end cust_type -- 客户类型
,cert_type -- 证件类型
,NSRSBH -- 证件号码
,city_cd -- 地市代码
,SHI -- 地市
,county_cd -- 县区代码
,QX -- 县区
,town_cd -- 乡镇代码
,'' -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,TEL -- 联系电话
,'混合饲料'	   -- 经营主业
,YSI_ZCL -- 规模
,YSI_JYSR -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_ods_nyncj_sl_table11'
,'农业厅-饲基11表' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_ods_nyncj_sl_table11	-- 农业厅-饲基11表
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;

commit ;


insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,DWMC -- 客户姓名
,case when DWMC is null then '' 
      when length(DWMC) >= 12 then '2' 
	  else '1' end cust_type -- 客户类型
,cert_type -- 证件类型
,NSRSBH -- 证件号码
,city_cd -- 地市代码
,SQ -- 地市
,county_cd -- 县区代码
,QX -- 县区
,town_cd -- 乡镇代码
,'' -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,LXDH -- 联系电话
,'饲料添加剂'	   -- 经营主业
,S_CPSCQKJZYJJZB_SLTJJZCL_D_ -- 规模
,S_CPSCQKJZYJJZB_SLTJJYYSR_WY_ -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_ods_nyncj_sl_table12'
,'农业厅-饲基12表' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_ods_nyncj_sl_table12	-- 农业厅-饲基12表
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;

commit ;

insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,DWMC -- 客户姓名
,case when DWMC is null then '' 
      when length(DWMC) >= 12 then '2' 
	  else '1' end cust_type -- 客户类型
,cert_type -- 证件类型
,HSRSBH -- 证件号码
,city_cd -- 地市代码
,SQ -- 地市
,county_cd -- 县区代码
,QX -- 县区
,town_cd -- 乡镇代码
,'' -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,LXDH -- 联系电话
,'单一饲料'	   -- 经营主业
,O_OZZCL_D -- 规模
,O_OZYYSR_WY -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_ods_nyncj_sl_table13'
,'农业厅-饲基13表' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_ods_nyncj_sl_table13	-- 农业厅-饲基13表
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ; 


insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,QYQC -- 客户姓名
,case when QYQC is null then '' 
      when length(QYQC) >= 12 then '2' 
	  else '1' end cust_type -- 客户类型
,cert_type -- 证件类型
,NSRSBH -- 证件号码
,city_cd -- 地市代码
,'' -- 地市
,county_cd -- 县区代码
,'' -- 县区
,town_cd -- 乡镇代码
,'' -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,LXDH -- 联系电话
,'兽药生产'	   -- 经营主业
,null -- 规模
,null -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_ods_nyncj_sy_sc' --  
,'农业厅-兽药生产' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_ods_nyncj_sy_sc	-- 农业厅-兽药生产
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ; 

insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,QYMC -- 客户姓名
,case when QYMC is null then '' 
      when length(QYMC) >= 12 then '2' 
	  else '1' end cust_type -- 客户类型
,cert_type -- 证件类型
,NSRSBH -- 证件号码
,city_cd -- 地市代码
,DS -- 地市
,county_cd -- 县区代码
,QX -- 县区
,town_cd -- 乡镇代码
,'' -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,TEL -- 联系电话
,'兽药销售'	   -- 经营主业
,null -- 规模
,null -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_ods_nyncj_sy_jy' -- 数据类型
,'农业厅-兽药销售' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_ods_nyncj_sy_jy	-- 农业厅-兽药销售
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ; 

insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,ZRRXM -- 客户姓名
,case when ZRRXM is null then '' 
      when length(ZRRXM) >= 12 then '2' 
	  else '1' end  -- 客户类型
,'' -- 证件类型
,ZZRSFZH -- 证件号码
,'' -- 地市代码
,SHI -- 地市
,'' -- 县区代码
,QX -- 县区
,'' -- 乡镇代码
,XZ -- 乡镇
,'' -- 国民经济分类代码
,'' -- 国民经济分类
,LXDH -- 联系电话
,case when length(CYFL)>200 then '' else cyfl end	   -- 经营主业
,case when concat(ifnull(ZZPL,''),'',ifnull(ZZGZMJ,'')) =''  
	  then  concat(ifnull(YZPL,''),' ',ifnull(YZGM,'')) 
      else concat(ifnull(ZZPL,''),' ',ifnull(ZZGZMJ,'')) 
      end -- 规模
,JJSR -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_cj_snzt_jcxx' -- 
,'农业厅-涉农主体通用' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_cj_snzt_jcxx	-- 农业厅-涉农主体通用
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ; 

insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,YZCHMC -- 客户姓名
,case when YZCHMC is null then '' 
      when length(YZCHMC) >= 12 then '2' 
	  else '1' end cust_type -- 客户类型
,cert_type -- 证件类型
,XQYZDM -- 证件号码
,city_cd -- 地市代码
,SHI -- 地市
,county_cd -- 县区代码
,QX -- 县区
,town_cd -- 乡镇代码
,'' -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,TEL -- 联系电话
,concat(YZXZ,'/',ifnull(YZZL,''))	   -- 经营主业
,concat('存栏 ',ifnull(SJCLGM,''),' 出栏 ',ifnull(SJCULGM,'')) -- 规模
,null -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_ods_nyncj_yzxx' -- 
,'农业厅-规模化养殖' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_ods_nyncj_yzxx	-- 农业厅-规模化养殖
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ; 

insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,DWMC -- 客户姓名
,case when DWMC is null then '' 
      when length(DWMC) >= 12 then '2' 
	  else '1' end cust_type -- 客户类型
,cert_type -- 证件类型
,CQYZDM -- 证件号码
,city_cd -- 地市代码
,'' -- 地市
,county_cd -- 县区代码
,'' -- 县区
,town_cd -- 乡镇代码
,'' -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,'' -- 联系电话
,concat(YZCZ,'/',ifnull(YZZL,''))	   -- 经营主业
,concat('存栏 ',ifnull(SNNMCL,''),' 出栏 ',ifnull(SNQNCL,'')) -- 规模
,null -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_ods_shengji_xmj' -- 数据类型
,'省级数据_畜牧局' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_ods_shengji_xmj	-- 省级数据_畜牧局
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ;


insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,dw -- 客户姓名
,case when dw is null then '' 
      when length(dw) >= 12 then '2' 
	  else '1' end -- 客户类型
,'' -- 证件类型
,sfzh_tyshxydm -- 证件号码
,'' -- 地市代码
,SHI -- 地市
,'' -- 县区代码
,QX -- 县区
,'' -- 乡镇代码
,ZHEN -- 乡镇
,'' -- 国民经济分类代码
,'' -- 国民经济分类
,TEL -- 联系电话
,'种植'	   -- 经营主业
,concat('经营权颁证面积（亩） ',ifnull(jyqbzmj,''),' 出让方农户数量 ',ifnull(crnhsl,'')) -- 规模
,null -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_ods_jcny_tdlz' -- 数据类型
,'农业厅-基层农业土地流转表' -- 数据来源
,'1'
from dw_nd.ods_coll_v_ods_jcny_tdlz	-- 农业厅-基层农业土地流转表
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ;


insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,sbmc -- 客户姓名
,case when sbmc is null then '' 
      when length(sbmc) >= 12 then '2' 
	  else '1' end -- 客户类型
,'' -- 证件类型
,SFZ_JGDM -- 证件号码
,city_cd -- 地市代码
,SHI -- 地市
,county_cd -- 县区代码
,XIAN -- 县区
,town_cd -- 乡镇代码
,XIANG -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,TEL -- 联系电话
,concat('投保种植种类：',ifnull(tbpz,''),'，投保年度：',ifnull(tbnd,''))	   -- 经营主业
,concat('投保面积 ',ifnull(TBMJ,''),' 投保金额 ',ifnull(ZJ_TBJE,'')) -- 规模
,null -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_mid_bxgs_bxmd' -- 数据类型
,'涉农保险投保信息' -- 数据来源
,'1'
from dw_nd.ods_coll_v_mid_bxgs_bxmd	-- 涉农保险
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ;

insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,QYMC -- 客户姓名
,case when QYMC is null then '' 
      when length(trim(QYMC)) >= 12 then '2' 
	  else '1' end -- 客户类型
,'' -- 证件类型
,NSRSBH -- 证件号码
,city_cd -- 地市代码
,SHI -- 地市
,county_cd -- 县区代码
,XIAN -- 县区
,town_cd -- 乡镇代码
,XIANG -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,TEL -- 联系电话
,substr(JYZTLX,1,200)	   -- 经营主业
,substr(JYGM,1,50)  -- 规模
,null -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_ods_nyncj_qtsnztsj' -- 数据类型
,'其他涉农主体数据' -- 数据来源
,'1'
from dw_nd.ods_coll_v_ods_nyncj_qtsnztsj	-- 其他涉农主体数据
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ;


	

insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,JSZTGZMC -- 客户姓名
,case when JSZTGZMC is null then '' 
      when length(trim(JSZTGZMC)) >= 12 then '2' 
	  else '1' end -- 客户类型
,'' -- 证件类型
,cert_no -- 证件号码
,city_cd -- 地市代码
,SHI -- 地市
,county_cd -- 县区代码
,XIAN -- 县区
,town_cd -- 乡镇代码
,XIANG -- 乡镇
,econ_type -- 国民经济分类代码
,econ_name -- 国民经济分类
,TEL -- 联系电话
,'仓储'	   -- 经营主业
,concat('冷库容量（吨） ',ifnull(LKRL,''))  -- 规模
,null -- 年收入
,update_time -- 数据获取时间
,'ods_coll_mid_nyncj_ncpccbxxq' -- 数据类型
,'其他涉农主体数据' -- 数据来源
,'1'
from dw_nd.ods_coll_mid_nyncj_ncpccbxxq	-- 农产品仓储保鲜
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ;


insert into dw_base.dwd_cust_coll_key_info
select
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,entname -- 客户姓名
,'2'   -- 客户类型
,'' -- 证件类型
,nsrsbh -- 证件号码
,'' -- 地市代码
,'' -- 地市
,'' -- 县区代码
,'' -- 县区
,'' -- 乡镇代码
,'' -- 乡镇
,'' -- 国民经济分类代码
,'' -- 国民经济分类
,TEL -- 联系电话
,substr(jyfw,1,200)	   -- 经营主业
,concat('注册资本 ',ifnull(zczb,''))  -- 规模
,null -- 年收入
,update_time -- 数据获取时间
,'ods_coll_v_dim_ods_cdlbhzs' -- 数据类型
,'国家级省级农民专业合作社名单' -- 数据来源
,'1'
from dw_nd.ods_coll_v_dim_ods_cdlbhzs	-- 农产品仓储保鲜
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}'
;
commit ;



insert into dw_base.dwd_cust_coll_key_info
select 
distinct
'${v_sdate}'  -- 数据日期
,id
,'' -- 客户号
,csrmc -- 客戶姓名
,cust_type -- 客户类型
,'' -- 证件类型
,'' -- 证件号码
,'' -- 地市代码
,'' -- 地市
,'' -- 县区代码
,'' -- 县区
,'' -- 乡镇代码
,'' -- 乡镇
,'' -- 国民经济分类代码
,'' -- 国民经济分类
,TEL -- 联系电话
,BSLB -- 经营主业
,''  -- 规模
,''  -- 年收入
,update_time
,'ods_coll_v_ods_nd_cyds' -- 数据类型
,'农担创业大赛' 
,'1'
from dw_nd.ods_coll_v_ods_nd_cyds   -- 农担创业大赛
where  date_format(update_time,'%Y%m%d') <= '${v_sdate}';
commit;
 

 
-- 黑牛数据汇总

insert into dw_base.dwd_cust_coll_key_info
( 
day_id
,id
,cust_name
,cust_type
,cert_no
,town_name
,tel_no
,busi_main
,busi_scal
,imp_dt
,data_source
,data_source_desc
,data_flag)
select * from (
	select
	'${v_sdate}' as day_id ,
	id,
	contract_person as cust_name ,
	'1' as cust_type ,
	legalld_card as cert_no ,
	town_name as town_name ,
	contract_mobile as tel_no ,
	'牛的饲养' as busi_main ,
	count(distinct ear_no) as buzi_scal , -- 规模
	date_format(update_time,'%Y-%m-%d') as imp_dt ,-- 收集时间
	'ods_data_access_cattle' as data_source ,
	'黑牛管家--高青黑牛牛只信息' as data_source_desc ,
	'1' as data_flag -- 搜集平台
	,row_number() over(partition by town_name,contract_person order by update_time desc) as rk
	from(
		select id
		,contract_person
		,legalld_card
		,town_name
		,contract_mobile
		,ear_no
		,update_time
		from(
			select id
			,contract_person
			,legalld_card
			,town_name
			,contract_mobile
			,ear_no
			,update_time
			,row_number() over(partition by id order by update_time desc) as rk
			from dw_nd.ods_data_access_cattle 
			where date_format(update_time,'%Y%m%d') <= '${v_sdate}'
		) t 
		where rk = 1
	) t1
) t2
;
commit;


-- 粮食购销
insert into dw_base.dwd_cust_coll_key_info -- mdy 20220420 wyx
select
'${v_sdate}' as day_id
,id
,'' as cust_id
,xm as cust_name
,'1' as cust_type
,'' -- 证件类型
,sfzh as cert_no
,'' as city_cd
,shi as city_name
,'' as county_cd
,xian as county_name
,'' as town_cd
,xiang as town_name
,'' as econ_type
,'' as econ_name
,tel as tel_no
,jjpz as busi_main
,concat('从业经验: ',CONVERT(cyjy,UNSIGNED),'年') as busi_scal
,xzsr as income_y
,date_format(create_time,'%Y-%m-%d') as imp_dt
,'ods_sjcjzl_v_cj_zzy_zldh_zl' as data_source
,'粮食购销' as data_source_desc
,'1' as data_flag
from
(
select * from 
(select 
      id
		 ,xm
		 ,sfzh
		 ,shi
		 ,xian
		 ,xiang
		 ,tel
		 ,jjpz
		 ,cyjy
		 ,xzsr
		 ,create_time
		 ,row_number() over(partition by id order by update_time desc) as rk
	from dw_nd.ods_sjcjzl_v_cj_zzy_zldh_zl) t1
where rk = 1
) t2
;
commit;


-- 经营类数据                       --    20220524   zzy 
insert into dw_base.dwd_cust_coll_key_info
select '${v_sdate}' as day_id,      -- 数据日期 
       b.id,                        -- 序号
	   null as cust_id,             -- 客户id
	   xm   as cust_name,           -- 客户姓名 
	   '1'  as cust_type,           -- 客户类型 
	   null as cert_type,           -- 证件类型 
	   b.sfzh as cert_no,           -- 证件号码
	   substr(b.xzqhdm,1,4) as city_cd, -- 地市代码 
	   b.shi as city_name,   -- 地市 
	   substr(b.xzqhdm,4,2) as county_cd, -- 区县代码
	   b.xian as county_name,   -- 区县 
	   substr(b.xzqhdm,7,3) as town_cd,   -- 乡镇代码 
	   b.xiang as town_name,   -- 乡镇 
	   null as econ_type,  -- 国民经济分类 
	   null as econ_name,  -- 国民经济分类 
	   b.tel as tel_no,      -- 联系电话 
	   b.mypl as busi_main,  -- 经营主业 
	   concat('从业年限：',round(b.cynx),'年') as busi_scal,  -- 规模
	   b.snxssr as income_y, -- 年收入 
	   convert(b.create_time,date) as imp_dt,  -- 收集时间 
	   'ods_sjcjzl_v_cj_zzy_mylxx_zl' as data_source,  -- 数据来源 
	   '经营类数据' as data_source_desc,  -- 数据来源中文
	   '1' as data_flag  -- 1收集平台2手工导入
from (select a.id,     -- 
             a.xm,     -- 
             a.sfzh,   -- 
             a.shi,    -- 
             a.xian,   -- 
             a.xiang,  -- 
             a.xzqhdm, -- 
             a.tel,    -- 
             a.mypl,   -- 
             a.cynx,   -- 
             a.snxssr, -- 
             a.create_time	      
       from (select id,     -- 主键
                    xm,     -- 姓名
                  	sfzh,   -- 身份证号
                  	shi,    -- 市
                  	xian,   -- 区县 
                  	xiang,  -- 乡镇 
                  	xzqhdm, -- 行政区划代码 
                  	tel,    -- 联系电话 
                  	mypl,   -- 贸易品类
                  	cynx,   -- 从业年限_年
                  	snxssr, -- 上年销售收入
                  	create_time  -- 创建时间
					,row_number() over(partition by id order by update_time desc) as rk
              from dw_nd.ods_sjcjzl_v_cj_zzy_mylxx_zl  -- 贸易类数据
              ) a
         where rk = 1) b;
commit;
			 
