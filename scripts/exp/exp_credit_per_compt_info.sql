
-- exp_credit_per_compt_info 个人贷款信息
-- /**
-- CREATE TABLE ods_imp_compt_repay_info (
--    txn_id varchar(50) comment '流水号id' ,
--    seq_id varchar(50) comment '项目id',
--    txn_dt varchar(20) comment '还款时间',
--    repay_amt decimal(18,2) comment '还款金额',
--    remnant_amt decimal(18,2) coment '剩余偿还金额' ,
--    KEY idx_ods_imp_compt_cust_info_cert (seq_id)
--  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC COMMENT='代偿还款信息';
--  **/


-- 最近还款情况
-- 历史追偿业务报送
drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_repay ; -- 20230706【dw_base改为dw_tmp】
commit;

create  table dw_tmp.tmp_exp_credit_per_compt_info_repay (
seq_id varchar(60) -- 贷款ID
,lat_rpy_amt decimal(18,2) -- 最近一次实际还款金额
,lat_rpy_date varchar(10)  -- 最近一次实际还款日期
,is_close varchar(10)
,sum_rpy_amt decimal(18,2) -- 累计追偿本金
,index idx_tmp_exp_credit_per_compt_info_repay_seq_id(seq_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_compt_info_repay
select 
t1.guar_id
,t1.recovery_amt  -- 最近一次追偿本金
,t1.last_repay_date -- 最近一次偿还日期/结清日期
,t1.is_settle -- 是否结清
,sum_recovery_amt  -- 累计追偿本金
from (
	select 
	guar_id
	,recovery_amt  -- 最近一次追偿本金
	,last_repay_date
	,is_settle
	from (
		select
		guar_id
		,recovery_amt  -- 最近一次追偿本金
		,last_repay_date -- 最近一次偿还日期/结清日期
		,is_settle
		,row_number() over (partition by guar_id order by last_repay_date desc) as rn
		from dw_nd.ods_imp_recovery_detail
		where last_repay_date <= DATE_FORMAT('${v_sdate}','%Y-%m-%d')
	)t
	where rn = 1
)t1
inner join (
	select
	guar_id
	,sum(recovery_amt)sum_recovery_amt  -- 累计追偿本金
	from dw_nd.ods_imp_recovery_detail
	where last_repay_date <= DATE_FORMAT('${v_sdate}','%Y-%m-%d')
	group by guar_id
)t2
on t1.guar_id = t2.guar_id
;
commit ;


-- 

-- 代偿账户信息
 
delete from dw_base.exp_credit_per_compt_info_ready where day_id ='${v_sdate}';

commit;

insert into dw_base.exp_credit_per_compt_info_ready
select
'${v_sdate}' as day_id -- 数据日期
,t1.seq_id -- 贷款ID
,t2.CUST_ID -- 客户号
,'C1' as acct_type -- 账户类型
-- ,concat('X3701010000337',replace(replace(t1.seq_id,'-',''),'贷','D')) as acct_code -- 账户标识码
,replace(replace(t1.seq_id,'-',''),'贷','D') as acct_code -- 账户标识码
,DATE_FORMAT('${v_sdate}','%Y-%m-%d') as rpt_date-- 信息报告日期
-- ,date_add(t1.compt_dt,interval 1 day) -- 信息报告日期
,''as rpt_date_code  -- 报告时点说明代码  账户开立 收回逾期款项 账户关闭
,t1.cust_name -- 借款人姓名
,'10' as id_type -- 借款人证件类型
,t1.cert_no -- 借款人证件号码
-- ,'X3701010000337' as mngmt_org_code -- 业务管理机构代码
,'9999999' as mngmt_org_code -- 业务管理机构代码
,'6' as busi_lines-- 借贷业务大类
,'B1' as busi_dtl_lines -- 借贷业务种类细分
,t4.compt_time -- 开户日期
,'CNY' as cy -- 币种
,NULL as acct_cred_line -- 信用额度
,t1.compt_amt -- 借款金额    mdy 20211117 去掉*10000
,NULL as flag -- 分次放款标志
,NULL as due_date -- 到期日期
,NULL as repay_mode-- 还款方式
,NULL as repay_freqcy-- 还款频率
,NULL as repay_prd-- 还款期数
,NULL as apply_busi_dist-- 业务申请地行政区划代码
,NULL as guar_mode-- 担保方式
,NULL as oth_repy_guar_way-- 其他还款保证方式
,NULL as asset_trand_flag-- 资产转让标志
,NULL as fund_sou-- 业务经营类型
,NULL as loan_form-- 贷款发放形式
,NULL as credit_id-- 卡片标识号
,NULL as loan_con_code-- 贷款合同编号
,NULL as first_hou_loan_flag-- 是否为首套住房贷款
,coalesce(t1.loan_bank,t1.bank_brev)as init_cred_name -- 初始债权人名称
,case when t5.org_code is not null then t5.org_code else '' end as init_cred_org_nm -- 初始债权人机构代码
,'1' as orig_dbt_cate -- 原债务种类
,case when datediff(t4.compt_time,t4.overdue_date)>1 and datediff(t4.compt_time,t4.overdue_date)<=30 then '1'
	  when datediff(t4.compt_time,t4.overdue_date)>30 and datediff(t4.compt_time,t4.overdue_date)<=60 then '2'
	  when datediff(t4.compt_time,t4.overdue_date)>60 then '3'
	  else ''
	  end as init_rpy_sts -- 债务转移时的还款状态
,case when t3.is_close = '是' then '2' else '1' end as acct_status -- 账户状态  mdy 20230629修改结清数据来源，增加追偿业务
,case when t3.seq_id is null then t1.compt_amt else  case when t3.is_close = '否' then t1.compt_amt - coalesce(t3.sum_rpy_amt,0) else 0 end end as acct_bal-- mdy 20230629 如果无追偿回的本金，余额即代偿本金，如果有追偿回的本金，即代偿本金-追偿本金，如果结清，则为0
,NULL as five_cate -- 五级分类
,NULL as five_cate_adj_date-- 五级分类认定日期
,NULL as rem_rep_prd-- 剩余还款期数
,NULL as rpy_status-- 当前还款状态
,NULL as overd_prd-- 当前逾期期数
,NULL as tot_overd-- 当期逾期总额
,case when t3.seq_id is null then 0 else t3.lat_rpy_amt end as lat_rpy_amt -- 最近一次实际还款金额
-- ,date_sub(DATE_FORMAT(compt_dt,'%Y-%m-%d'),interval 60 day)  -- 最近一次实际还款日期
,case when t3.seq_id is null then DATE_FORMAT(t4.compt_time,'%Y-%m-%d') else t3.lat_rpy_date end as lat_rpy_date-- 最近一次实际还款日期
-- ,case when t1.repay_dt is not null  then repay_dt  else '' end -- 账户关闭日期
,case when t3.is_close='是'  then t3.lat_rpy_date  else '' end as close_date-- 账户关闭日期  mdy 20221009 增加结清的数据
from dw_nd.ods_imp_compt_cust_info t1  -- 担保业务系统所有代偿业务

-- from dw_nd.ods_imp_compt_cust_info_rpb t1
-- inner join dw_base.exp_credit_per_cust_info_ready t2  -- 客户授权
inner join dw_base.tmp_exp_credit_per_cust_info_id t2  -- 客户授权
on t1.cert_no = t2.id_num 
left join dw_tmp.tmp_exp_credit_per_compt_info_repay t3
on t1.seq_id = t3.seq_id
left join dw_base.dwd_guar_compt_info t4 
on t1.seq_id=t4.guar_id
left join (
	select bank_id,org_code
	from(
	select bank_id,org_code,row_number() over (partition by bank_id order by update_time) as rn
	from dw_nd.ods_org_manage_bank_info) a
	where rn = 1
) t5 on t1.loan_bank_id=t5.bank_id	-- 从合作机构获取统一社会信用代码
where t1.cust_type = '1' -- 对私
;
commit;



-- 还款责任人信息

-- 相关还款责任人（只在账户开立的时候上报）

-- 每笔业务对应的反担保人信息,共同借款人信息
drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_xz_counter ;
commit;

create table dw_tmp.tmp_exp_credit_per_compt_info_xz_counter (
	duty_type          varchar(60),
	apply_code         varchar(60),
	project_id         varchar(60),
	counter_name       varchar(60),
	id_type            varchar(4),
	id_no              varchar(40),
	index idx_tmp_tmp_exp_credit_per_compt_info_xz_counter_project_id(project_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_compt_info_xz_counter
select distinct 
        '2' as duty_type, -- 1-共同债务人 2-反担保人 9-其他
        t1.apply_code,
		t1.guar_id,
 		t2.counter_name, -- 反担保人名称
		t2.id_type,   -- 反担保人证件类型
		t2.id_no      -- 反担保人证件号
from 
	(
	    select 
	    	guar_id,
	    	apply_code
	    from
	    	(
	    	    select 
	    	    	guar_id,
	    	    	apply_code,
	    	        row_number() over (partition by apply_code order by update_time desc) rn
	    	    from dw_nd.ods_bizhall_guar_apply  -- 客户申请表
	    	    where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
	    	    and guar_id is not null
	    	) t 
	    where rn = 1
	)t1
inner join 
(
    select 
    	apply_code,
    	counter_name,
    	coalesce(id_type,ident_type) id_type,
    	id_no
    from
    	(
    	    select 
    	    	apply_code,
    	    	counter_name,
    	    	id_type,  -- 10 证件号  20 企业信用代码
				case when id_no like '9%' then '20' else '10' end ident_type,
    	    	id_no,
    	        row_number() over (partition by apply_code,id_no,counter_name order by update_time desc) rn
    	    from dw_nd.ods_bizhall_guar_apply_counter -- 反担保关联表  status状态字段不用限制
    	    where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
					-- and apply_code = 'W202212210000010178'
    	) t
    where rn = 1
)t2
on t1.apply_code = t2.apply_code
union all
select distinct 
		'1' as duty_type, -- 1-共同债务人 2-反担保人 9-其他
        t1.apply_code,
		t1.guar_id,
 		coalesce(t1.bank_part_name,t2.part_name), -- 共同借款人名称
		t2.id_type,   -- 共同借款人证件类型
		coalesce(t1.bank_part_id_no,t2.id_no)      -- 共同借款人证件号
from 
	(
	    select 
	    	guar_id,
	    	apply_code,
	    	bank_part_name,
	    	bank_part_id_no
	    from
	    	(
	    	    select 
	    	    	guar_id,
	    	    	apply_code,
	    	    	bank_part_name, -- 共同借款人姓名
	    	    	bank_part_id_no, -- 共同借款人身份证号
	    	        row_number() over (partition by apply_code order by update_time desc) rn
	    	    from dw_nd.ods_bizhall_guar_apply  -- 客户申请表
	    	    where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
	    	    and guar_id is not null
	    	) t 
	    where rn = 1
	)t1
inner join	
(
    select 
    	apply_code,
    	part_name,
    	coalesce(id_type,ident_type)id_type,
    	id_no
    from
    	(
    	    select 
    	    	apply_code,
    	    	part_name,
    	    	id_type,  -- 10 证件号  20 企业信用代码
				case when id_no like '9%' then '20' else '10' end ident_type,
    	    	upper(id_no)id_no,
    	        row_number() over (partition by apply_code,upper(id_no) order by update_time desc) rn
    	    from dw_nd.ods_bizhall_guar_apply_part -- 共同申保人关联表
    	    where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
			and part_name is not null
    	) t
    where rn = 1
)t2
on t1.apply_code = t2.apply_code
inner join (
	select id,code,spouse_co_borrower
	from (
		select id,code,spouse_co_borrower,row_number() over (partition by id order by db_update_time desc,update_time desc) rn
		from dw_nd.ods_t_biz_project_main
	)t
	where rn = 1
) t3 
on t1.guar_id = t3.id and t3.spouse_co_borrower is true
;
commit;


-- 授权的反担保人/共同借款人
drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_sq ;
commit;

create table dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_sq (
	duty_type          varchar(60),
    apply_code         varchar(60),
	project_id         varchar(60),
	counter_name       varchar(60),
	id_type            varchar(4),
	id_no              varchar(40),
	cust_code          varchar(40),
	index credit_per_guar_info_xz_counter_sq_project_id(project_id),
	index credit_per_guar_info_xz_counter_sq_ct_guar_person_id_no(id_no),
	index credit_per_guar_info_xz_counter_sq_cust_code(cust_code)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_sq
select
	   t.duty_type, -- 1-共同债务人 2-反担保人 9-其他
	   t.apply_code,
       t.project_id,   -- 担保业务系统ID
       t.counter_name,  -- 反担保人/共同借款人名称
       t.id_type,  -- 反担保人/共同借款人证件类型
       t.id_no,  -- 反担保人/共同借款人证件号
	   t2.cust_code  -- 反担保人/共同借款人客户号
from dw_tmp.tmp_exp_credit_per_compt_info_xz_counter t -- 每笔申请记录对应的反担保人/共同借款人信息
inner join 
(
  select customer_id
  		,main_name
  		,coalesce(main_id_type,ident_type)main_id_type
  		,main_id_no    
  from
  (
    select customer_id,
		       main_name,
               main_id_type,
               case when main_id_no like '9%' then '20' else '10' end ident_type,
               main_id_no,
               row_number() over (partition by MAIN_ID_NO order by update_time desc) rn
    from dw_nd.ods_wxapp_cust_login_info     -- 用户注册信息
    where status = '10'  -- 已授权   授权的客户证件号都不为空，去掉了 customer_id is not null and main_id_no is null 这个条件
  ) t
  where rn = 1
)t1
on t.id_no = t1.main_id_no   
left join (select cust_code,id_no from (select cust_code,id_no,row_number() over (partition by cust_code order by update_time desc) rn from dw_nd.ods_crm_cust_info)t where rn = 1)t2  -- mdy 20240911，之前是按照id_No取最新，但是会存在一个证件号对应多个客户号的情况，漏掉客户号，导致后面关联不到合同
on t.id_no = t2.id_no
;
commit;

-- 反担保合同
drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_contract ;
commit;

create table dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_contract (
	biz_id                varchar(64),
	contract_id           varchar(128),
	customer_id           varchar(64),
	contract_template_id  varchar(64),
	index idx_tmp_exp_credit_per_compt_info_xz_counter_contract_biz_id(biz_id),
	index idx_tmp_exp_credit_per_compt_info_xz_contract_customer_id(customer_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_contract
select biz_id
       ,contract_id  -- 合同编号
	   ,customer_id  -- 签署人客户号
       ,contract_template_id -- 合同模板id
from (
select biz_id
       ,contract_id  -- 合同编号
	   ,customer_id  -- 签署人客户号
	   -- ,concat('X3701010000337',contract_template_id) as contract_template_id -- 合同模板id
	   ,contract_template_id as contract_template_id -- 合同模板id
       ,status
from 
(
    select biz_id
           ,contract_id  -- 合同编号
    	   ,coalesce(AUTHORIZED_CUSTOMER_ID,customer_id)customer_id  -- 签署人客户号
    	   ,contract_template_id  -- 合同模板id
           ,status
           ,row_number() over (partition by BIZ_ID,CONTRACT_ID order by UPDATE_TIME desc) as rn
    from dw_nd.ods_comm_cont_comm_contract_info
    where contract_name like '%反担保%'
)a
where rn = 1
)t1
where status = '2' -- 已签约
;
commit;


-- 补充反担保合同（线下签约）[合同号带‘线下’字样的属于线下签约]
drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_contract_xx ;
commit;

create table dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_contract_xx (
	project_id                varchar(64),
	ct_guar_person_name       varchar(128),
	ct_guar_person_id_no      varchar(64),
	count_cont_code           varchar(64),
	index idx_tmp_xz_counter_contract_xx_project_id(project_id),
	index idx_tmp_xz_counter_contract_xx_ct_guar_person_id_no(ct_guar_person_id_no)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_contract_xx

select project_id
	  ,ct_guar_person_name  -- 反担保人姓名
	  ,ct_guar_person_id_no -- 反担保人证件号
	  ,replace(count_cont_code,'线下','XX')      -- 反担保合同
from (
	select id  
	       ,project_id
		   ,ct_guar_person_name
		   ,ct_guar_person_id_no
		   ,count_cont_code
	       ,row_number() over (partition by project_id order by db_update_time desc,update_time desc) rn
	from dw_nd.ods_t_ct_guar_person
)t
where rn = 1
;
commit;

-- 担保业务系统id 和项目编号转换
drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_main;
commit;

create table dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_main (
    project_id         varchar(60),
	guar_id            varchar(60),
	index credit_per_guar_info_xz_counter_main_project_id(project_id),
	index credit_per_guar_info_xz_counter_main_ct_guar_person_id_no(guar_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_main
select id,
	   code
from (
select id,
	   code,
       row_number() over (partition by id order by db_update_time desc,update_time desc) rn
from dw_nd.ods_t_biz_project_main
)a
where rn = 1
;
commit;


-- 从风险检查表中拿产业集群信息
drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_check;
commit;

create table dw_tmp.tmp_exp_credit_per_compt_info_check (
    project_id         varchar(60),
	aggregate_scheme   varchar(60),
	index tmp_exp_credit_comp_guar_info_checkproject_id(project_id),
	index tmp_exp_credit_comp_guar_info_check_aggregate_scheme(aggregate_scheme)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_tmp.tmp_exp_credit_per_compt_info_check
select project_id,
	   aggregate_scheme
from (
select project_id,
	   aggregate_scheme,
       row_number() over (partition by project_id order by update_time desc) rn
from dw_nd.ods_t_risk_check_opinion
)a
where rn = 1
;
commit;

-- 核心企业管理中企业分险
drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_risk_comp; commit;
create table if not exists dw_tmp.tmp_exp_credit_per_compt_info_risk_comp(
company_name varchar(200) comment'企业名称',
unified_social_credit_code varchar(50) comment '统一社会信用代码',
counter_guar_contract_number varchar(50) comment '反担保合同',
risk_grade varchar(255) comment'分险比例',
dictionaries_code varchar(50) comment '产业集群'
);
commit;

insert into dw_tmp.tmp_exp_credit_per_compt_info_risk_comp
select t1.company_name,t1.unified_social_credit_code,t2.counter_guar_contract_number,t2.risk_grade,t2.dictionaries_code
from (
	select * from (
		select *,row_number() over (partition by id order by update_time desc) rn from dw_nd.ods_cem_company_base -- 核心企业基本表
	)t
	where rn = 1
)t1
inner join (
	select * from (
		select *,row_number() over (partition by id order by update_time desc) rn from dw_nd.ods_cem_dictionaries  -- 企业产业集群关系
	)t
	where rn = 1
)t2
on t1.id = t2.cem_base_id -- 核心企业id    【经沟通，ods_cem_company_base的分险比例字段废弃，企业的分险比例用关系表中的】
;
commit;

-- 核心企业管理中自然人分险
drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_risk_natural; commit;
create table if not exists dw_tmp.tmp_exp_credit_per_compt_info_risk_natural(
person_name varchar(200) comment'自然人名称',
person_identity varchar(50) comment '证件号',
counter_guar_contract_number varchar(50) comment '反担保合同',
risk_grade varchar(255) comment'分险比例',
dictionaries_code varchar(50) comment '产业集群'
);
commit;

insert into dw_tmp.tmp_exp_credit_per_compt_info_risk_natural
select t1.person_name,t1.person_identity,t1.counter_guar_contract_number,t1.risk_grade,t2.dictionaries_code
	from (
		select id,person_name,person_identity,counter_guar_contract_number,risk_grade,cem_dictionaries_id
		from (
			select id,person_name,person_identity,counter_guar_contract_number,risk_grade,cem_dictionaries_id,row_number() over (partition by id order by update_time desc) rn
			from dw_nd.ods_cem_natural -- 自然人基本表
		)t
		where rn = 1
	)t1
	inner join (
		select * from (
			select *,row_number() over (partition by id order by update_time desc) rn from dw_nd.ods_cem_dictionaries  -- 企业产业集群关系
		)t
		where rn = 1
	)t2
on t1.cem_dictionaries_id = t2.id
;
commit;
-- create  table dw_base.exp_credit_per_repay_duty_info (
-- 	day_id varchar(8)  comment '数据日期',
-- 	guar_id varchar(60)  comment '担保id',
-- 	cust_id varchar(60)  comment '客户号',
-- 	duty_qty int      comment '责任人个数',  -- 之前的建表语句没有这个
-- 	info_id_type varchar(3)  comment '身份类别',
-- 	duty_name varchar(80)  comment '责任人名称',
-- 	duty_cert_type varchar(3)  comment '责任人身份标识类型',
-- 	duty_cert_no varchar(40)  comment '责任人身份标识号码',
-- 	duty_type varchar(3)  comment '还款责任人类型：1-共同债务人2-反担保人9-其他',
-- 	duty_amt int  comment '还款责任金额',
-- 	duty_flag varchar(3)  comment '联保标志：0-单人保证/多人分保（单人保证指该账户对应的担保交易仅有一个反担保人，多人分保指该账户对应的担保交易有多个反担保人，且每个反担保人独立分担一部分担保责任）1-联保（联保指该账户对应的担保交易有多个反担保人且共同承担担保责任）',  
-- 	guar_cont_no varchar(60)  comment '保证合同编号'
-- ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
-- ;
-- commit;

-- 还款责任人信息
DELETE FROM dw_base.exp_credit_per_compt_duty_info where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_per_compt_duty_info
select * from (
select t.day_id
       ,t.ln_id
	 ,t.cust_id
	 ,t.info_id_type
	 ,t.duty_name
	 ,t.duty_cert_type
	 ,t.duty_cert_no
	 ,t.duty_type
	 ,case when t.duty_type='2' and t1.company_name is not null and t1.risk_grade <> '' and t1.risk_grade is not null then t.duty_amt*t1.risk_grade
		   when t.duty_type='2' and t2.person_name is not null and t2.risk_grade <> '' and t2.risk_grade is not null then t.duty_amt*t2.risk_grade
		   when t.duty_type='2' then t.duty_amt
		   else null
		   end as duty_amt
	 ,case when t.duty_type='2' and t1.company_name is not null then concat(t1.counter_guar_contract_number,t.ln_id)
		   when t.duty_type='2' and t2.person_name is not null then concat(t2.counter_guar_contract_number,t.ln_id)
		   when t.duty_type='2' then t.guar_cont_no
		   else null
		   end as guar_cont_no  -- 反担保合同
from (
select '${v_sdate}' as day_id,
       t.ln_id,  -- 担保ID
       t.cust_id,  -- 客户号
	   case when t2.id_type = '10' then '1' when t2.id_type = '20' then '2' else null end as info_id_type,  -- 身份类别  1-自然人  2-组织机构
	   t2.counter_name as duty_name, -- 责任人名称
	   '10' as duty_cert_type,  -- 责任人身份标识类型  10:居民身份证及其他以公民身份证号为标识的证件 20-统一社会信用代码
	   case when t2.id_type = '10' then t2.id_no 
	        when t2.id_type = '20' then coalesce(t10.zhongzheng_code,t9.id_num) 
			else null 
	   end as duty_cert_no,  -- 责任人身份标识号码
	   t2.duty_type, -- 1-共同债务人 2-反担保人 9-其他
	   case when t2.duty_type='2' then coalesce(t.acct_cred_line,t.loan_amt) else null end as duty_amt, -- 还款责任金额(担保金额)
	   -- case when t2.duty_type='2' then coalesce(t5.contract_id,t4.contract_id,t7.contract_id,t8.contract_id,t6.count_cont_code) 
	   -- 	else null 
	   -- 	end as guar_cont_no, -- 反担保合同编号
	   case when t2.duty_type='2' then coalesce(t5.contract_id,t4.contract_id,t6.count_cont_code) 
	        else null 
	        end as guar_cont_no, -- 反担保合同编号
	   t10.ct_guar_person_id_no, -- 企业统一社会编码
	   t11.aggregate_scheme -- 产业集群
from (
select ln_id,cust_id,acct_cred_line,loan_amt
from dw_base.exp_credit_per_compt_info_ready  
where day_id = '${v_sdate}' 
)t -- 与昨日数据对比获取余额变动日期、五级分类变动日期 存放当天变化后的数据以及变化日期
inner join dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_main t1  -- -- 担保业务系统id 和项目编号转换
on t.ln_id = t1.guar_id
inner join dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_sq t2  -- 授权的反担保人/共同借款人信息
on t1.project_id = t2.project_id
left join dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_contract t4
on t2.apply_code = t4.biz_id
and t2.cust_code = t4.customer_id  -- 客户号
and t2.duty_type='2'
left join dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_contract t5
on t2.apply_code = t5.biz_id
and t2.id_no = t5.customer_id  -- 证件号
and t2.duty_type='2'
left join dw_tmp.tmp_exp_credit_per_compt_info_xz_counter_contract_xx t6 -- 线下签约
on t1.project_Id = t6.project_Id
and t2.id_no = t6.ct_guar_person_id_no 
and t6.count_cont_code is not null
and t2.duty_type='2'
-- left join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract t7
-- on t2.apply_code = t7.biz_id
-- and t2.id_no = t7.AUTHORIZED_CUSTOMER_ID  -- 证件号
-- and t2.duty_type='2'
-- left join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract t8
-- on t2.apply_code = t8.biz_id
-- and t2.cust_code = t8.AUTHORIZED_CUSTOMER_ID  -- 证件号
-- and t2.duty_type='2'
left join dw_nd.ods_imp_comp_zzm t9
on t.ln_id = t9.guar_id
and t2.id_no = t9.cert_no
and t9.cust_type = '02' -- 反担保人
and t2.duty_type='2'
left join (
	select project_id,zhongzheng_code,ct_guar_person_id_no
	from (
		select id,project_id,zhongzheng_code,ct_guar_person_id_no,row_number() over (partition by id order by db_update_time desc,update_time desc) rn
		from dw_nd.ods_t_ct_guar_person
                where data_type = '7' -- 出具批复最终定的担保人
	)t
	where rn = 1
)t10
on t1.project_Id = t10.project_Id
and t2.id_no = t10.ct_guar_person_id_no
and t10.zhongzheng_code is not null 
and t2.duty_type='2'
left join dw_tmp.tmp_exp_credit_per_compt_info_check t11
on t1.project_id = t11.project_id
)t
left join dw_tmp.tmp_exp_credit_per_compt_info_risk_comp t1  -- 20231023优化，核心企业的集群方案与担保业务一致时，作为反担保人时，责任金额用合同金额*分险比例，反担保合同用协议合同+业务编号
on t.ct_guar_person_id_no = t1.unified_social_credit_code
and t.aggregate_scheme = t1.dictionaries_code
left join dw_tmp.tmp_exp_credit_per_compt_info_risk_natural t2 
on t.duty_cert_no = t2.person_identity
and t.aggregate_scheme = t2.dictionaries_code
where t.duty_cert_no is not null 
)t
where guar_cont_no is not null 
;
commit;



-- -- 1.获取当天代偿台账
-- create  table dw_base.exp_credit_per_compt_info_open (
--  ln_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,open_date	date	comment '开户日期'
--  ,key(ln_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;


delete from dw_base.exp_credit_per_compt_info_open where day_id = '${v_sdate}' ;
commit; 
insert into dw_base.exp_credit_per_compt_info_open
select 
ln_id     -- 
,day_id     
,open_date 
from dw_base.exp_credit_per_compt_info_ready t1
where t1.day_id = '${v_sdate}'  
and t1.open_date <= DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')     -- 放款日期为当天即新增
and datediff(DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d'),open_date) < 300  -- 检验规则：开户日期和报送日期间隔要小于30天
and t1.close_date = ''
and not exists (         -- 新开客户
select 1
from dw_pbc.exp_credit_per_compt_info t2
where t2.day_id < '${v_sdate}' 
and t2.rpt_date_code = '10'
and t1.ln_id = t2.ln_id
)
;
commit;

-- 2.获取当天解保台账
-- create  table dw_base.exp_credit_per_compt_info_close (
--  ln_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,close_date	date	comment '解保日期'
--  ,key(ln_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

delete from dw_base.exp_credit_per_compt_info_close where day_id = '${v_sdate}' ;
commit; 
insert into dw_base.exp_credit_per_compt_info_close
select 
ln_id     -- 
,day_id     
,close_date 
from (
select 
ln_id     
,day_id     
,close_date  
from dw_base.exp_credit_per_compt_info_ready 
where day_id = '${v_sdate}'  
and  close_date <= DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')    -- mdy 20221009 增加结清的数据
-- and close_date <>''
and close_date is not null
and length(close_date)>0
) t1
where exists (
 select 1 from dw_pbc.exp_credit_per_compt_info t2 --   之前开户
 where t2.day_id < '${v_sdate}'
 and t2.rpt_date_code = '10' -- 开户
 and t1.ln_id = t2.ln_id
 )
and not exists (         -- 新增 关闭账户
select 1
from dw_pbc.exp_credit_per_compt_info t2
where t2.day_id < '${v_sdate}' 
and t2.rpt_date_code = '20'  -- 关户
and t1.ln_id = t2.ln_id
)
;
commit;



-- 3.获取当天收回逾期款项
-- create  table dw_base.exp_credit_per_compt_info_repay_dt (
--  ln_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,lat_rpy_date	date	comment '最近一次实际还款日期'
--  ,key(ln_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;


delete from dw_base.exp_credit_per_compt_info_repay_dt where day_id = '${v_sdate}' ;
commit; 
insert into dw_base.exp_credit_per_compt_info_repay_dt
select 
seq_id
,DATE_FORMAT('${v_sdate}' ,'%Y%m%d')
,lat_rpy_date
from dw_tmp.tmp_exp_credit_per_compt_info_repay t1
where  t1.lat_rpy_date <= DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')   -- 【需要变回 = 】
and is_close = '否' -- 未结清
and not exists (
select 1 from dw_pbc.exp_credit_per_compt_info t2 -- 余额变动 不能同时当天开户
where t2.day_id = '${v_sdate}'
and t2.rpt_date_code = '10' -- 开户
and t1.seq_id = t2.ln_id
)
and not exists (
select 1 from dw_pbc.exp_credit_per_compt_info t2 -- 余额变动 不能关闭
where t2.rpt_date_code = '20' -- 关户
and t1.seq_id = t2.ln_id
)
and exists (  
select 1 from dw_pbc.exp_credit_per_compt_info t2 --   之前开户
where t2.day_id < '${v_sdate}'
and t2.rpt_date_code = '10' -- 开户
and t1.seq_id = t2.ln_id
)
and not exists (-- 【增加：】
 select 1 from dw_pbc.exp_credit_per_compt_info t2 --   之前未报过同一天还款
 where t2.day_id < '${v_sdate}'
 and t2.rpt_date_code = '40' -- 还款
 and t1.seq_id = t2.ln_id
 and t1.lat_rpy_date = t2.lat_rpy_date
 )
;
commit;


-- 插入目标表
delete from dw_base.exp_credit_per_compt_info where day_id ='${v_sdate}';

commit;

-- 账户开立 10
insert into dw_base.exp_credit_per_compt_info
select distinct 
t1.day_id	 --	数据日期
,t1.ln_id	 --	贷款ID
,t1.cust_id	 --	客户号
,t1.acct_type	 --	账户类型
,t1.acct_code	 --	账户标识码
,t1.rpt_date	 --	信息报告日期
,'10'   	 --	报告时点说明代码
,t1.name	 --	借款人姓名
,t1.id_type	 --	借款人证件类型
,t1.id_num	 --	借款人证件号码
,t1.mngmt_org_code	 --	业务管理机构代码
,t1.busi_lines	 --	借贷业务大类
,t1.busi_dtl_lines	 --	借贷业务种类细分
,t1.open_date	 --	开户日期
,t1.cy	 --	币种
,t1.acct_cred_line	 --	信用额度
,t1.loan_amt	 --	借款金额
,t1.flag	 --	分次放款标志
,t1.due_date	 --	到期日期
,t1.repay_mode	 --	还款方式
,t1.repay_freqcy	 --	还款频率
,t1.repay_prd	 --	还款期数
,t1.apply_busi_dist	 --	业务申请地行政区划代码
,t1.guar_mode	 --	担保方式
,t1.oth_repy_guar_way	 --	其他还款保证方式
,t1.asset_trand_flag	 --	资产转让标志
,t1.fund_sou	 --	业务经营类型
,t1.loan_form	 --	贷款发放形式
,t1.credit_id	 --	卡片标识号
,t1.loan_con_code	 --	贷款合同编号
,t1.first_hou_loan_flag	 --	是否为首套住房贷款
,t1.init_cred_name	 --	初始债权人名称
,t1.init_cred_org_nm	 --	初始债权人机构代码
,t1.orig_dbt_cate	 --	原债务种类
,t1.init_rpy_sts	 --	债务转移时的还款状态
,t1.acct_status	 --	账户状态
,t1.acct_bal	 --	余额
,t1.five_cate	 --	五级分类
,t1.five_cate_adj_date	 --	五级分类认定日期
,t1.rem_rep_prd	 --	剩余还款期数
,t1.rpy_status	 --	当前还款状态
,t1.overd_prd	 --	当前逾期期数
,t1.tot_overd	 --	当期逾期总额
,t1.lat_rpy_amt	 --	最近一次实际还款金额
,t1.lat_rpy_date	 --	最近一次实际还款日期
,t1.close_date	 --	账户关闭日期
from dw_base.exp_credit_per_compt_info_ready  t1
inner join dw_base.exp_credit_per_compt_info_open t2
on t1.ln_id = t2.ln_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'

;

commit;

-- 账户关闭 20
insert into dw_base.exp_credit_per_compt_info
select distinct 
 t1.day_id	 --	数据日期
,t1.ln_id	 --	贷款ID
,t1.cust_id	 --	客户号
,t1.acct_type	 --	账户类型
,t1.acct_code	 --	账户标识码
,t1.rpt_date	 --	信息报告日期
,'20'	 --	报告时点说明代码
,t1.name	 --	借款人姓名
,t1.id_type	 --	借款人证件类型
,t1.id_num	 --	借款人证件号码
,t1.mngmt_org_code	 --	业务管理机构代码
,t1.busi_lines	 --	借贷业务大类
,t1.busi_dtl_lines	 --	借贷业务种类细分
,t1.open_date	 --	开户日期
,t1.cy	 --	币种
,t1.acct_cred_line	 --	信用额度
,t1.loan_amt	 --	借款金额
,t1.flag	 --	分次放款标志
,t1.due_date	 --	到期日期
,t1.repay_mode	 --	还款方式
,t1.repay_freqcy	 --	还款频率
,t1.repay_prd	 --	还款期数
,t1.apply_busi_dist	 --	业务申请地行政区划代码
,t1.guar_mode	 --	担保方式
,t1.oth_repy_guar_way	 --	其他还款保证方式
,t1.asset_trand_flag	 --	资产转让标志
,t1.fund_sou	 --	业务经营类型
,t1.loan_form	 --	贷款发放形式
,t1.credit_id	 --	卡片标识号
,t1.loan_con_code	 --	贷款合同编号
,t1.first_hou_loan_flag	 --	是否为首套住房贷款
,t1.init_cred_name	 --	初始债权人名称
,t1.init_cred_org_nm	 --	初始债权人机构代码
,t1.orig_dbt_cate	 --	原债务种类
,t1.init_rpy_sts	 --	债务转移时的还款状态
,t1.acct_status	 --	账户状态
,t1.acct_bal	 --	余额
,t1.five_cate	 --	五级分类
,t1.five_cate_adj_date	 --	五级分类认定日期
,t1.rem_rep_prd	 --	剩余还款期数
,t1.rpy_status	 --	当前还款状态
,t1.overd_prd	 --	当前逾期期数
,t1.tot_overd	 --	当期逾期总额
,t1.lat_rpy_amt	 --	最近一次实际还款金额
,t1.lat_rpy_date	 --	最近一次实际还款日期
,t1.close_date	 --	账户关闭日期
from dw_base.exp_credit_per_compt_info_ready t1
inner join dw_base.exp_credit_per_compt_info_close t2
on t1.ln_id = t2.ln_id
and t2.day_id = '${v_sdate}'
where t1.day_id ='${v_sdate}'
-- and t1.close_date = DATE_FORMAT('${v_sdate}','%Y-%m-%d')   mdy 20221009 可能结清完后又提交的
;

commit;

-- 月结日 没有 30
-- 收回逾期款项 40
insert into dw_base.exp_credit_per_compt_info
select distinct 
 t1.day_id	 --	数据日期
,t1.ln_id	 --	贷款ID
,t1.cust_id	 --	客户号
,t1.acct_type	 --	账户类型
,t1.acct_code	 --	账户标识码
,t1.rpt_date	 --	信息报告日期
,'40'	 --	报告时点说明代码
,t1.name	 --	借款人姓名
,t1.id_type	 --	借款人证件类型
,t1.id_num	 --	借款人证件号码
,t1.mngmt_org_code	 --	业务管理机构代码
,t1.busi_lines	 --	借贷业务大类
,t1.busi_dtl_lines	 --	借贷业务种类细分
,t1.open_date	 --	开户日期
,t1.cy	 --	币种
,t1.acct_cred_line	 --	信用额度
,t1.loan_amt	 --	借款金额
,t1.flag	 --	分次放款标志
,t1.due_date	 --	到期日期
,t1.repay_mode	 --	还款方式
,t1.repay_freqcy	 --	还款频率
,t1.repay_prd	 --	还款期数
,t1.apply_busi_dist	 --	业务申请地行政区划代码
,t1.guar_mode	 --	担保方式
,t1.oth_repy_guar_way	 --	其他还款保证方式
,t1.asset_trand_flag	 --	资产转让标志
,t1.fund_sou	 --	业务经营类型
,t1.loan_form	 --	贷款发放形式
,t1.credit_id	 --	卡片标识号
,t1.loan_con_code	 --	贷款合同编号
,t1.first_hou_loan_flag	 --	是否为首套住房贷款
,t1.init_cred_name	 --	初始债权人名称
,t1.init_cred_org_nm	 --	初始债权人机构代码
,t1.orig_dbt_cate	 --	原债务种类
,t1.init_rpy_sts	 --	债务转移时的还款状态
,t1.acct_status	 --	账户状态
,t1.acct_bal	 --	余额
,t1.five_cate	 --	五级分类
,t1.five_cate_adj_date	 --	五级分类认定日期
,t1.rem_rep_prd	 --	剩余还款期数
,t1.rpy_status	 --	当前还款状态
,t1.overd_prd	 --	当前逾期期数
,t1.tot_overd	 --	当期逾期总额
,t1.lat_rpy_amt	 --	最近一次实际还款金额
,t1.lat_rpy_date	 --	最近一次实际还款日期
,t1.close_date	 --	账户关闭日期
from dw_base.exp_credit_per_compt_info_ready  t1
inner join dw_base.exp_credit_per_compt_info_repay_dt t2
on t1.ln_id = t2.ln_id
and t2.day_id = '${v_sdate}'
where t1.day_id ='${v_sdate}'
;
commit;

-- -- 个人借贷账户标识变更请求记录
-- 
-- insert into dw_base.exp_credit_per_compt_info_del
-- select
-- '${v_sdate}'	 --	数据日期
-- ,ln_id	 --	贷款ID
-- ,cust_id	 --	客户号
-- ,DATE_FORMAT('${v_sdate}','%Y-%m-%d')
-- ,'211'   -- 信息记录类型
-- ,-- 原业务标识码
-- ,-- 新业务标识码
-- ;



-- 按段更正

-- 1.定位客户群 今天上报前已开户，但是未关闭。

drop table if exists dw_tmp.tmp_exp_credit_per_compt_info_sep_cust ;  -- 【dw_base 改为dw_tmp】

commit;

create  table dw_tmp.tmp_exp_credit_per_compt_info_sep_cust (
ln_id varchar(60) 
,key(ln_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;
   
insert into dw_tmp.tmp_exp_credit_per_compt_info_sep_cust
select 
ln_id   
from dw_base.exp_credit_per_compt_info_open t1 
where t1.day_id < '${v_sdate}' 
and not exists( 
select 1 from dw_base.exp_credit_per_compt_info t2 
where t2.day_id <= '${v_sdate}' 
and t2.rpt_date_code = '20' -- 关户
and t1.ln_id = t2.ln_id
)
;

commit ;
-- 2.获取变更数据 B-基础段 C-基本信息段 D-相关还款责任人段 E-抵质押物信息段 F-授信额度信息段 G-初始债权说明段
-- H-月度表现信息段 I-大额专项分期信息段 J-非月度表现信息段 --K-特殊交易说明段

-- B-基础段
delete from dw_base.exp_credit_per_compt_info_change_b where day_id = '${v_sdate}' ;

commit;

insert into dw_base.exp_credit_per_compt_info_change_b
select
'${v_sdate}'
,t2.ln_Id
,t2.cust_Id
,t2.acct_code -- 账户标识码
,t2.name -- 债务人姓名
,t2.id_type -- 债务人证件类型
,t2.id_num -- 债务人证件号码
,t2.mngmt_org_code -- 业务管理机构代码
from dw_tmp.tmp_exp_credit_per_compt_info_sep_cust t1
inner join dw_base.exp_credit_per_compt_info_ready t2
        on t1.ln_Id = t2.ln_Id
       and t2.day_id = '${v_sdate}'
inner join dw_base.exp_credit_per_compt_info_ready t3
        on t1.ln_Id = t3.ln_Id
       and t3.day_id = '${v_yesterday}' 
where t2.name <> t3.name
   or t2.id_type <> t3.id_type
   or t2.id_num <> t3.id_num
   or t2.mngmt_org_code <>  t3.mngmt_org_code
;
commit;

-- C-基本信息段 
delete from dw_base.exp_credit_per_compt_info_change_c where day_id = '${v_sdate}' ;

commit;

insert into dw_base.exp_credit_per_compt_info_change_c
select
'${v_sdate}'
,t2.ln_Id
,t2.cust_Id
,t2.acct_code -- 账户标识码
,t2.busi_lines -- 借贷业务大类：1-贷款；2-信用卡；3-证券类融资；4-融资租赁；5-资产处置；6-垫款
,t2.busi_dtl_lines -- 借贷业务种类细分
,t2.open_date -- 开户日期
,t2.cy -- 币种
,t2.acct_cred_line -- 信用额度
,t2.loan_amt -- 借款金额
,t2.flag -- 分次放款标志
,t2.due_date -- 到期日期
,t2.repay_mode -- 还款方式：
,t2.repay_freqcy -- 还款频率
,t2.repay_prd -- 还款期数
,t2.apply_busi_dist -- 业务申请地行政区划代码
,t2.guar_mode -- 担保方式
,t2.oth_repy_guar_way -- 其他还款保证方式：
,t2.asset_trand_flag -- 资产转让标志
,t2.fund_sou -- 业务经营类型
,t2.loan_form -- 贷款发放形式
,t2.credit_id -- 卡片标识号
,t2.loan_con_code -- 贷款合同编号
,t2.first_hou_loan_flag -- 是否为首套住房贷款
from dw_tmp.tmp_exp_credit_per_compt_info_sep_cust t1
inner join dw_base.exp_credit_per_compt_info_ready t2
        on t1.ln_Id = t2.ln_Id
       and t2.day_id = '${v_sdate}'
inner join dw_base.exp_credit_per_compt_info_ready t3
        on t1.ln_Id = t3.ln_Id
       and t3.day_id = '${v_yesterday}' 
where (t2.loan_amt <> t3.loan_amt
   or t2.due_date <> t2.due_date
   -- or t2.open_date <> t3.open_date
   )
 and not exists
	 (
	 select 1 from dw_base.exp_credit_per_compt_info t4  -- 不能通过 10 20 30 40 50 上报
	 where t4.day_id = '${v_sdate}'
	   and t1.ln_Id = t4.ln_Id
	 )   
;
commit;

-- G-初始债权说明段
delete from dw_base.exp_credit_per_compt_info_change_g where day_id = '${v_sdate}' ;

commit;

insert into dw_base.exp_credit_per_compt_info_change_g
select
'${v_sdate}'
,t2.ln_Id
,t2.cust_Id
,t2.acct_code -- 账户标识码
,t2.init_cred_name -- 初始债权人名称 
,t2.init_cred_org_nm -- 初始债权人机构代码 
,t2.orig_dbt_cate -- 原债务种类
,t2.init_rpy_sts -- 债权转移时的还款状态
from dw_tmp.tmp_exp_credit_per_compt_info_sep_cust t1
inner join dw_base.exp_credit_per_compt_info_ready t2
        on t1.ln_Id = t2.ln_Id
       and t2.day_id = '${v_sdate}'
inner join dw_base.exp_credit_per_compt_info_ready t3
        on t1.ln_Id = t3.ln_Id
       and t3.day_id = '${v_yesterday}' 
where (t2.init_cred_name <> t3.init_cred_name
   -- or t2.init_rpy_sts <> t3.init_rpy_sts
   )
   and not exists
	 (
	 select 1 from dw_base.exp_credit_per_compt_info t4  -- 不能通过 10 20 30 40 50 上报
	 where t4.day_id = '${v_sdate}'
	   and t1.ln_Id = t4.ln_Id
	 ) 
;
commit;
-- J-非月度表现信息段
delete from dw_base.exp_credit_per_compt_info_change_j where day_id = '${v_sdate}' ;

commit;

insert into dw_base.exp_credit_per_compt_info_change_j
select
'${v_sdate}'
,t2.ln_Id
,t2.cust_Id
,t2.acct_code -- 账户标识码
,t2.acct_status -- 账户状态
,t2.acct_bal -- 余额
,t2.five_cate -- 五级分类
,t2.five_cate_adj_date -- 五级分类认定日期
,t2.rem_rep_prd -- 剩余还款期数
,t2.rpy_status -- 当前还款状态
,t2.overd_prd -- 当前逾期期数
,t2.tot_overd -- 当前逾期总额
,t2.lat_rpy_amt -- 最近一次实际还款金额
,t2.lat_rpy_date -- 最近一次实际还款日期
,t2.close_date -- 账户关闭日期
from dw_tmp.tmp_exp_credit_per_compt_info_sep_cust t1
inner join dw_base.exp_credit_per_compt_info_ready t2
        on t1.ln_Id = t2.ln_Id
       and t2.day_id = '${v_sdate}'
inner join dw_base.exp_credit_per_compt_info_ready t3
        on t1.ln_Id = t3.ln_Id
       and t3.day_id = '${v_yesterday}' 
where t2.acct_bal <> t3.acct_bal
and not exists(
select 1 from dw_base.exp_credit_per_compt_info t4 where day_id = '${v_sdate}'
and t1.ln_id = t4.ln_id
)
;
commit;

-- 考虑到推送任务已切换到星环，未避免mysql和星环同步运行期间产生 同时推送，现注释改脚本推送内容 20241012

-- 同步数据

delete from dw_pbc.exp_credit_per_compt_info where day_id = '${v_sdate}' ;

commit;

insert into dw_pbc.exp_credit_per_compt_info
select * 
from dw_base.exp_credit_per_compt_info
where day_id = '${v_sdate}' 
;

commit;

DELETE FROM dw_pbc.exp_credit_per_compt_duty_info where day_id = '${v_sdate}' ;
commit;
insert into dw_pbc.exp_credit_per_compt_duty_info
select
*
from dw_base.exp_credit_per_compt_duty_info 
where day_id = '${v_sdate}' 
;
commit ;


delete from dw_pbc.exp_credit_per_compt_info_change_b where day_id = '${v_sdate}' ;

commit ;

insert into dw_pbc.exp_credit_per_compt_info_change_b 
select * 
from dw_base.exp_credit_per_compt_info_change_b  
where day_id = '${v_sdate}' 
;

commit ;

delete from dw_pbc.exp_credit_per_compt_info_change_c where day_id = '${v_sdate}' ;

commit ;

insert into dw_pbc.exp_credit_per_compt_info_change_c 
select * 
from dw_base.exp_credit_per_compt_info_change_c
where day_id = '${v_sdate}' 
;

commit ;

delete from dw_pbc.exp_credit_per_compt_info_change_g where day_id = '${v_sdate}' ;

commit ;

insert into dw_pbc.exp_credit_per_compt_info_change_g 
select * 
from dw_base.exp_credit_per_compt_info_change_g
where day_id = '${v_sdate}' 
;

commit ;

delete from dw_pbc.exp_credit_per_compt_info_change_j where day_id = '${v_sdate}' ;

commit ;

insert into dw_pbc.exp_credit_per_compt_info_change_j 
select * 
from dw_base.exp_credit_per_compt_info_change_j
where day_id = '${v_sdate}' 
;

commit ;

