-- 改 20251014
-- 客户信息（id,base,addr）
-- 企业信息表
-- 主要组成人员表
-- 同步数据



-- 客户信息
drop table if exists dw_tmp.tmp_exp_credit_comp_cust_info_id ;
commit ;

-- delete from dw_tmp.tmp_exp_credit_comp_cust_info_id where day_id = '${v_sdate}'; commit;

create table dw_tmp.tmp_exp_credit_comp_cust_info_id (
	cust_id        varchar(60)  -- 客户编号
	,ent_name      varchar(30)  -- 客户名称
	,ent_cert_type varchar(2)   -- 证件类型
	,ent_cert_num  varchar(20)  -- 中征码
	,org_type      varchar(2)   -- 组织机构类型
	,ecoindus_cate varchar(20)  -- 国民经济行业分类父类代码
	,day_id        varchar(8)   -- 企业担保客户报送时点
	,rpt_code      varchar(2)   -- 上报时点代码
	,key(cust_id)
) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;
commit ;

insert into dw_tmp.tmp_exp_credit_comp_cust_info_id
select
	cust_id
	,name
	,id_type
	,id_num
	,org_type
	,coalesce(CONCAT(T2.parent_code3, t2.code),'A0190')  --   国民经济行业分类父类代码
	,t1.day_id
	,t1.rpt_date_code
from
	(
	select
		t1.cust_id
		,t1.name
		,t1.id_type
		,t1.id_num
		,'1' org_type -- 20250701 修改默认组织机构类型 合作社也算企业
		,substring_index(replace(replace((replace(t2.econ_class_cd,'\"','')),'[',''), ']',''),',',-1) code
		,t1.day_id
		,t1.rpt_date_code
    from (
       select cust_id,name,id_type,id_num,day_id,rpt_date_code
       from dw_base.exp_credit_comp_guar_info  -- 企业担保客户
            union all
       select cust_id,name,id_type,id_num,day_id,rpt_date_code
       from dw_base.exp_credit_comp_compt_info  -- 企业借贷客户
	   where rpt_date_code is not null          -- [排除掉已代偿追偿的业务，增量更新没有报告时点代码]              20251014
    )t1
    inner join dw_base.dwd_agmt_guar_proj_info t2   -- 20211216  dwd_agmt_guar_proj_info担保项目信息
    on t1.cust_id = t2.cust_id
    where t2.proj_stt in ('50','90','93')  -- 50-已放款 90-已解保 93-已代偿
	  and t2.proj_no not like 'TJ%'              -- [在保转进件业务的个人基本信息不报送]                           20251014	  
    group by t1.id_num
)t1
left join dw_base.dim_ecoindus_code t2   -- 国民经济行业分类维表
on T1.code = t2.code
;

commit ;



-- -- 补充数据,历史原因未能入表的数据,建表这段不要再放开,补数时只放开delete insert部分
-- drop table if exists dw_tmp.tmp_imp_cust_info_id;
-- create table dw_tmp.tmp_imp_cust_info_id as 
-- select t1.*
-- ,case when t3.cust_id is null then '登记地址为空'
-- -- 如果担保或者借贷10类型的day_id,没有在对应的那天入表,就不会有窗口再进来
--       when t4.cust_id is not null and t5.cust_id is null then 'ready中存在,day_id不同'
--       when t5.cust_id is not null then 'ready中存在'
--  else '其他' end as unmatch_reason
-- from dw_tmp.tmp_exp_credit_comp_cust_info_id t1 -- 担保和借贷全量数据
-- left join dw_base.exp_credit_comp_cust_info t2 on t1.cust_id=t2.cust_id -- 目标表
-- left join dw_tmp.tmp_exp_credit_comp_cust_info_addr t3 on t1.cust_id=t3.cust_id -- inner筛选条件 公司地址
-- left join (
-- select *
-- from (
--         select *
--         from dw_base.exp_credit_comp_cust_info_ready
--         order by day_id asc) a
-- group by cust_id
-- ) t4 on t1.cust_id=t4.cust_id -- ready按客户号分组,取最早记录
-- left join dw_base.exp_credit_comp_cust_info_ready t5 on t1.cust_id=t5.cust_id and t1.day_id=t5.day_dt and t1.day_id=t5.day_id -- ready中日期和和客户号都能匹配到的
-- where t2.cust_id is null
-- union all 
-- select t1.*
-- ,'首条20,需要补10' as unmatch_reason
-- from dw_tmp.tmp_exp_credit_comp_cust_info_id t1 -- 担保和借贷全量数据
-- left join (
-- 	select 
-- 	cust_id
-- 	from
-- 	(
-- 	select 
-- 	day_id
-- 	,cust_id
-- 	,rpt_date_code
-- 	,@row_number := case when @cust_id=cust_id then @row_number+1 else 1 end as rn
-- 	,@cust_id := cust_id
-- 	from dw_base.exp_credit_comp_cust_info
-- 	,(select @cust_id :='',@row_number := 0) t
-- 	order by cust_id,day_id asc
-- 	) a
-- 	where rn=1 and rpt_date_code='20'
-- ) t2 on t1.cust_id=t2.cust_id
-- where t2.cust_id is not null;
-- 
-- 
-- delete from dw_tmp.tmp_exp_credit_comp_cust_info_id 
-- where cust_id in (
-- 	select cust_id
-- 	from dw_tmp.tmp_imp_cust_info_id
-- );
-- commit;
-- 
-- insert into dw_tmp.tmp_exp_credit_comp_cust_info_id
-- select
-- distinct
--  cust_id
-- ,ent_name
-- ,ent_cert_type
-- ,ent_cert_num
-- ,org_type
-- ,ecoindus_cate
-- ,'${v_sdate}' as day_id
-- ,'10' as rpt_code
-- from dw_tmp.tmp_imp_cust_info_id
-- where unmatch_reason in ('ready中存在','ready中存在,day_id不同');
-- commit ;


-- 企业注册资本
drop table if exists dw_tmp.tmp_exp_credit_comp_cust_info_base ;
commit ;

create table dw_tmp.tmp_exp_credit_comp_cust_info_base (
	cust_id         varchar(60)  -- 客户编号
	,establish_date	varchar(10)  -- 机构成立日期
	,reg_cap	    int          -- 注册资本
) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;
commit ;

insert into dw_tmp.tmp_exp_credit_comp_cust_info_base
select
	customer_id
	,found_date -- 成立日期
	,reg_capital -- 注册资本
from
	(
	select
		cust_code as customer_id
        ,case when register_time regexp 'Z' then str_to_date(replace(substring_index(register_time, 'T', 1),'Z',''),'%Y-%m-%d')
              else date_format(register_time,'%Y-%m-%d') end as found_date -- 成立日期
		,register_capital as reg_capital-- 注册资本
	    ,row_number() over (partition by cust_code order by update_time desc) as rn
	from dw_nd.ods_crm_cust_comp_info  -- 企业详细信息表 -- 切源为新的表 mdy 20240528 之前用的dw_nd.ods_gcredit_customer_company_detail
	) t
where rn = 1
;
commit ;

-- 企业登记住址
drop table if exists dw_tmp.tmp_exp_credit_comp_cust_info_addr ;
commit ;

create table dw_tmp.tmp_exp_credit_comp_cust_info_addr (
	cust_id     varchar(60)     -- 客户编号
	,reg_add	varchar(100)	-- 登记地址
) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;
commit ;

insert into dw_tmp.tmp_exp_credit_comp_cust_info_addr
select
	customer_id
	,company_address
from
	(
	select
	customer_id
	,company_address
	,row_number() over (partition by customer_id order by update_time desc) as rn
	from dw_nd.ods_wxapp_cust_login_info  -- 登录账号信息表  -- 切源为新的表 mdy 20240528 之前用的dw_nd.ods_gcredit_customer_login_info
	where login_type= '2' -- 2企业
	and customer_id is not null
	and company_address is not null
	) t
where rn = 1
;
commit ;


--  删除数据
delete from dw_base.exp_credit_comp_cust_info_ready where day_id= '${v_sdate}';
commit ;

-- 企业信息表
insert into dw_base.exp_credit_comp_cust_info_ready
select
	'${v_sdate}' as day_id  -- 数据日期
	,t1.day_id as day_dt    -- 企业担保客户的报送时间
	,t1.rpt_code  -- 企业担保客户的上报时点代码
	,t1.cust_id -- 客户号
	,t1.ent_name -- 企业名称
	,t1.ent_cert_type -- 之前是 t1.ent_cert_type 20220816修改为10 中征码 -- 企业身份标识类型
	,t1.ent_cert_num -- 企业身份标识号码RPAD(t1.ent_cert_num,16,'0')
	-- ,'X3701010000337' as inf_surc_code -- 信息来源编码
	,'9999999' as inf_surc_code -- 信息来源编码
	,'10' as rpt_date_code -- 报告时点说明代码
	-- ,'X3701010000337' as cimoc -- 客户资料维护机构代码
	,'9999999' as cimoc -- 客户资料维护机构代码
	,'2' as customer_type  -- 客户资料类型  2 授信业务客户资料
	,'1' as etp_sts -- 存续状态      X 未知
	,t1.org_type -- 组织机构类型
	,'CHN' as nationality -- 国别代码
	,t3.reg_add -- 登记地址
	,'' as adm_div_of_reg  -- 登记地行政区划代码
	,coalesce(t2.establish_date,'') as establish_date -- 成立日期
	,'2099-12-31' as biz_end_date -- 营业许可证到期日
	,'' as biz_range -- 业务范围
	,ecoindus_cate -- 行业分类代码
	,case when t1.ent_name like '%合作社%' then '142'  -- 集体联营
		when t1.ent_name like '%有限责任公司%' then '173' -- 私营有限责任(公司)
		when t1.ent_name like '%股份有限公司%' then '174' -- 私营股份有限(公司)
		else '170' end   -- 私有 -- 经济类型代码
	,'X' as ent_scale -- 企业规模  X 未知
	,'CNY' as reg_cap_currency -- 注册资本币种
	,t2.reg_cap -- 注册资本
	,'1' as sup_org_type -- 上级机构类型  1 集团母公司
	,t1.ent_name -- 上级机构名称
	,t1.ent_cert_type -- 之前是t1.ent_cert_type，20220816修改为 10-中征码 -- 上级机构身份标识类型
	,t1.ent_cert_num  -- 上级机构身份标识码 RPAD(t1.ent_cert_num,16,'0')
	,'' as con_add_district_code -- 联系地址行政区划代码
	,'' as con_add -- 联系地址
	,'' as con_phone -- 联系电话
	,'' as fin_con_phone -- 财务部门联系电话
from dw_tmp.tmp_exp_credit_comp_cust_info_id t1
left join dw_tmp.tmp_exp_credit_comp_cust_info_base t2
on t1.cust_id = t2.cust_id
inner join dw_tmp.tmp_exp_credit_comp_cust_info_addr t3  -- 只提报登记地址不为空的（上报要求规定国别代码为CHN时，地址不能为空）
on t1.cust_id = t3.cust_id
;
commit ;



delete from dw_base.exp_credit_comp_cust_info where day_id= '${v_sdate}';
commit ;

-- 企业信息表 新增/全量
insert into dw_base.exp_credit_comp_cust_info
select
	t1.day_id
	,t1.cust_id
	,t1.ent_name
	,t1.ent_cert_type
	,t1.ent_cert_num
	,t1.inf_surc_code
	,'10' as rpt_date_code
	,t1.cimoc
	,t1.customer_type
	,t1.etp_sts
	,t1.org_type
	,t1.nationality
	,t1.reg_add
	,t1.adm_div_of_reg
	,t1.establish_date
	,t1.biz_end_date
	,t1.biz_range
	,t1.eco_indus_cate
	,t1.eco_type
	,t1.ent_scale
	,t1.reg_cap_currency
	,t1.reg_cap
	,t1.sup_org_type
	,t1.sup_org_name
	,t1.sup_org_cert_type
	,t1.sup_org_cert_num
	,t1.con_add_district_code
	,t1.con_add
	,t1.con_phone
	,t1.fin_con_phone
	,'add' as data_type
from dw_base.exp_credit_comp_cust_info_ready t1
where t1.day_id = '${v_sdate}'
and t1.day_dt = '${v_sdate}'      -- 测试的首次上报日是20220817
and t1.rpt_code = '10'              -- 首次上报\新增
and not exists (    -- 历史未上报过
		select 1
		from dw_base.exp_credit_comp_cust_info t2
		where t2.day_id <= '${v_sdate}'
		and t1.cust_id = t2.cust_id
		)
;
commit ;

-- 企业信息表 修改
insert into dw_base.exp_credit_comp_cust_info
	select
	t1.day_id
	,t1.cust_id
	,t1.ent_name
	,t1.ent_cert_type
	,t1.ent_cert_num
	,t1.inf_surc_code
	,'20' as rpt_date_code
	,t1.cimoc
	,t1.customer_type
	,t1.etp_sts
	,t1.org_type
	,t1.nationality
	,t1.reg_add
	,t1.adm_div_of_reg
	,t1.establish_date
	,t1.biz_end_date
	,t1.biz_range
	,t1.eco_indus_cate
	,t1.eco_type
	,t1.ent_scale
	,t1.reg_cap_currency
	,t1.reg_cap
	,t1.sup_org_type
	,t1.sup_org_name
	,t1.sup_org_cert_type
	,t1.sup_org_cert_num
	,t1.con_add_district_code
	,t1.con_add
	,t1.con_phone
	,t1.fin_con_phone
	,'modify'   as data_type -- 修改
from dw_base.exp_credit_comp_cust_info_ready t1
where day_id = '${v_sdate}' -- 当天最新的数据
and not exists (select 1 from dw_base.exp_credit_comp_cust_info t2
                where t2.day_id = '${v_sdate}'
				and rpt_date_code = '10'
				and t1.cust_id = t2.cust_id)  -- 非当天新增
and exists (select 1 from dw_base.exp_credit_comp_cust_info t2
                where t2.day_id < '${v_sdate}'
				and rpt_date_code = '10'
				and t1.cust_id = t2.cust_id)  -- 历史有过新增
and exists ( -- 与最新的数据相比,有以下变化的才更新
		select 1
		from (
			select day_id,ent_name,reg_add,establish_date,eco_indus_cate,reg_cap,cust_id
			from(
				select day_id,ent_name,reg_add,establish_date,eco_indus_cate,reg_cap,cust_id,row_number() over (partition by cust_id order by day_id desc) rn
				from dw_base.exp_credit_comp_cust_info
				)a
		    where rn = 1
		) t2
		where t2.day_id <= '${v_yesterday}'
		and t1.cust_id = t2.cust_id
		and (
		t1.ent_name <> t2.ent_name  -- 企业名称
		or t1.reg_add <> t2.reg_add
		or t1.establish_date <> t2.establish_date  -- 成立日期
		or t1.eco_indus_cate <> t2.eco_indus_cate  -- 行业分类代码
		or t1.reg_cap <> coalesce(t2.reg_cap,0)  -- 注册资本
			)
		)
;
commit ;

-- 主要组成人员表

delete from  dw_base.exp_credit_comp_sen_info where day_id = '${v_sdate}';
commit ;

insert into dw_base.exp_credit_comp_sen_info
select
	'${v_sdate}'
	,t1.cust_id
	,t1.MMB_ALIAS
	,t1.mmb_id_type
	,t1.mmb_id_num
	,t1.mmb_pstn
from dw_tmp.tmp_exp_credit_comp_sen_info t1  -- 逻辑在企业担保信息脚本中
inner join dw_tmp.tmp_exp_credit_comp_cust_info_id t2
on t1.cust_id = t2.cust_id
;
commit ;


-- -- 主要出资人表
-- drop table if exists dw_base.tmp_exp_credit_comp_cust_info_hsj ;
-- commit ;
-- 
-- create  table dw_base.tmp_exp_credit_comp_cust_info_hsj(
-- seqnum  varchar(50)
-- ,cust_id varchar(50)
-- ,cust_name varchar(200)
-- )engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;
-- ;
-- commit ;
-- 
-- insert into dw_base.tmp_exp_credit_comp_cust_info_hsj
-- select 
-- t1.seqnum
-- ,coalesce(t2.cust_id,t1.custid)
-- ,coalesce(t2.cust_name,t1.companyname)
-- from (select distinct seqnum,creditcode,custid,companyname   from dw_nd.ods_de_t_param_nd_de_baseinfo where custtype ='02') t1
-- left join (select cust_id,cust_name,cert_type,cert_no from dw_base.dwd_cust_info) t2
-- on  t1.creditcode = t2.cert_no
-- ;
-- commit ;
-- 
-- 
-- -- 主要出资人表
-- delete from dw_base.exp_credit_comp_sponsor_info where day_id = '${v_sdate}';
-- commit ;
-- 
-- insert into dw_base.exp_credit_comp_sponsor_info
-- select
-- '${v_sdate}' -- 数据日期
-- ,t1.cust_id -- 客户号
-- ,t3.reg_cap	 -- 总注册资本
-- ,t1.shar_hod_type -- 出资人类型
-- ,t1.shareholdertype -- 出资人身份类别
-- ,t1.shareholdername -- 出资人名称
-- ,t1.blictype -- 出资人身份标识类型
-- ,t1.blicno -- 出资人身份标识号码
-- ,t1.fundedratio -- 出资比例 
-- from
-- (
-- select
-- *
-- from
-- (
-- select
-- t2.cust_id -- 企业客户编号
-- ,t2.cust_name -- 企业客户姓名
-- ,'10' shar_hod_type -- 出资人类型
-- ,case when shareholdertype='自然人' then '1' 
--       else '2' 
-- 	  end shareholdertype -- 出资人身份类别
-- , shareholdername -- 出资人名称
-- ,case when blictype ='营业执照' then '20' end blictype -- 出资人身份标识类型
-- ,blicno -- 出资人身份标识号码
-- ,replace(fundedratio,'%','') fundedratio -- 出资比例
-- from dw_nd.ods_extdata_ys_a001_shareholderlist t1
-- inner join dw_base.tmp_exp_credit_comp_cust_info_hsj t2
-- on t1.seqnum = t2.seqnum
-- where replace(fundedratio,'%','') > 5
-- order by  t1.createdate desc 
-- ) t
-- group by cust_id
-- ) t1
-- inner join dw_tmp.tmp_exp_credit_comp_cust_info_id t2
-- on t1.cust_id = t2.cust_id
-- left join dw_tmp.tmp_exp_credit_comp_cust_info_base t3
-- on t1.cust_id = t3.cust_id
--  ;
-- commit ;
-- 
-- 
-- -- 关联关系信息记录表
-- delete from dw_base.exp_credit_comp_ref_info where day_id = '${v_sdate}';
-- commit ;
-- 
-- insert into dw_base.exp_credit_comp_ref_info
-- select
-- '${v_sdate}' -- 数据日期
-- ,t1.cust_id -- 客户号
-- ,t2.ent_name -- a企业名称
-- ,t2.ent_cert_type -- a企业身份标识类型
-- ,t2.ent_cert_num -- a企业身份标识号码
-- ,t1.ent_name -- b企业名称
-- ,'20' -- b企业身份标识类型
-- ,t1.credit_code -- b企业身份标识号码
-- ,'22' -- 关联关系类型
-- ,case when ent_stt like '%销%' then '0' else '1' end  -- 关联标志
-- from dw_base.dwd_sf_hsj_comp_invest t1
-- inner join dw_tmp.tmp_exp_credit_comp_cust_info_id t2
-- on t1.cust_id = t2.cust_id
-- where t1.credit_code is not null
-- group by t1.cust_id,t1.credit_code
-- ;
-- commit ;




-- 同步数据
delete from dw_pbc.exp_credit_comp_cust_info where day_id= '${v_sdate}';
commit ;
insert into dw_pbc.exp_credit_comp_cust_info 
select 
	t1.day_id
	,t1.cust_id
	,t1.ent_name
	,t1.ent_cert_type
	,t1.ent_cert_num
	,t1.inf_surc_code
	,t1.rpt_date_code
	,t1.cimoc
	,t1.customer_type
	,t1.etp_sts
	,t1.org_type
	,t1.nationality
	,t1.reg_add
	,t1.adm_div_of_reg
	,t1.establish_date
	,t1.biz_end_date
	,t1.biz_range
	,t1.eco_indus_cate
	,t1.eco_type
	,t1.ent_scale
	,t1.reg_cap_currency
	,t1.reg_cap
	,t1.sup_org_type
	,t1.sup_org_name
	,t1.sup_org_cert_type
	,t1.sup_org_cert_num
	,t1.con_add_district_code
	,t1.con_add
	,t1.con_phone
	,t1.fin_con_phone
	,t1.data_type
from dw_base.exp_credit_comp_cust_info t1
inner join dw_base.exp_credit_comp_sen_info  t2  -- 有主要责任人信息的才上报
on t1.cust_id = t2.cust_id
where t1.day_id= '${v_sdate}'
and t2.day_id= '${v_sdate}'
;
commit ;


delete from  dw_pbc.exp_credit_comp_sen_info where day_id = '${v_sdate}';
commit ;
insert into dw_pbc.exp_credit_comp_sen_info 
select 
	t1.day_id
	,t1.cust_id
	,t1.MMB_ALIAS
	,t1.MMB_ID_TYPE
	,t1.MMB_ID_NUM
	,t1.MMB_PSTN
from dw_base.exp_credit_comp_sen_info t1
inner join dw_base.exp_credit_comp_cust_info t2
on t1.cust_id = t2.cust_id
where t1.day_id = '${v_sdate}'
and t2.day_id = '${v_sdate}'
;
commit ;





