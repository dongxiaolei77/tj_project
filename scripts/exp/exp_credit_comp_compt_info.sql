-- 改 20251014
-- 相关还款责任人
-- 最近还款情况
-- 新增exp_credit_comp_compt_info_ready
-- 存放各数据
 -- 1.获取当天代偿台账
 -- 2.获取当天解保台账
 -- 33 实际还款（在非约定还款日还款）
 -- 41 五级分类调整
 -- 49 其他报送日
-- 汇总插入
-- 账户开立 10
-- 账户关闭 20
-- 实际还款 33
-- 41 五级分类调整
-- 49 其他报送日
-- 同步数据

-- 最近还款情况
drop table if exists dw_tmp.tmp_exp_credit_comp_compt_info_repay ;
commit;

create table dw_tmp.tmp_exp_credit_comp_compt_info_repay (
	guar_id varchar(60) -- 贷款ID
  ,lat_rpy_amt decimal(18,2) -- 最近一次实际还款金额
  ,lat_rpy_date varchar(10)  -- 最近一次实际还款日期
  ,is_close varchar(10)
  ,sum_rpy_amt decimal(18,2) -- 累计追偿本金
  ,index idx_tmp_exp_credit_comp_compt_info_repay_guar_id(guar_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_compt_info_repay
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


delete from dw_base.exp_credit_comp_compt_info_ready where day_id = '${v_sdate}';
commit ;

insert into dw_base.exp_credit_comp_compt_info_ready
select day_id
	   ,ln_id
	   ,cust_id
	   ,acct_type
	   ,acct_code
	   ,rpt_date
	   ,rpt_date_code
	   ,name
	   ,id_type
	   ,id_num
	   ,mngmt_org_code
	   ,busi_lines
	   ,busi_dtl_lines
	   ,open_date
	   ,cy
	   ,acct_cred_line
	   ,loan_amt
	   ,flag
	   ,due_date
	   ,repay_mode
	   ,repay_freqcy
	   ,apply_busi_dist
	   ,guar_mode
	   ,oth_repy_guar_way
	   ,loan_time_lim_cat
	   ,loan_form
	   ,act_invest
	   ,fund_sou
	   ,asset_trand_flag
	   ,init_cred_name
	   ,init_cred_org_nm
	   ,orig_dbt_cate
	   ,init_rpy_sts
	   ,acct_status
	   ,acct_bal
	   ,repay_prd
	   ,five_cate
	   ,five_cate_adj_date
	   ,rem_rep_prd
	   ,tot_overd
	   ,overd_princ
	   ,overd_dy
	   ,lat_rpy_date
	   ,lat_rpy_amt
	   ,lat_rpy_princ_amt
	   ,rpmt_type
	   ,lat_agrr_rpy_date
	   ,lat_agrr_rpy_amt
	   ,nxt_agrr_rpy_date
	   ,close_date
from (
select distinct
	 '${v_sdate}' day_id
	   ,t1.guar_id as ln_id       -- 贷款ID
	   ,t4.CUST_ID        -- 客户号
	   ,'C1'as acct_type  -- 账户类型  C1-催收账户
	   -- ,concat('X3701010000337',replace(t1.guar_id,'-','')) as acct_code   -- 账户标识码
	   ,replace(t1.guar_id,'-','') as acct_code   -- 账户标识码
	   ,DATE_FORMAT('${v_sdate}','%Y-%m-%d')as rpt_date                    -- 信息报告日期
	   ,case when t3.is_close = '是' then '20' else '10' end as rpt_date_code  -- 报告时点说明代码
	   ,t1.cust_name as name      -- 借款人名称
	   ,coalesce(t4.id_type,'10')id_type   -- 借款人身份标识类型
	   ,coalesce(t5.id_num,t6.zhongzheng_code) id_num   -- 中征码
	   -- ,'X3701010000337' as mngmt_org_code -- 业务管理机构代码
	   ,'9999999' as mngmt_org_code -- 业务管理机构代码
	   ,'41' as busi_lines                 -- 借贷业务大类  41-垫款
	   ,'50' as busi_dtl_lines             -- 借贷业务种类细分  50-担保代偿
	   ,t7.compt_time as open_date      -- 开户日期
	   ,'CNY' as cy      -- 币种
	   ,null as acct_cred_line     -- 信用额度
	   ,t1.compt_amt as loan_amt              -- 借款金额
	   ,null as flag               -- 分次放款标志
	   ,null as due_date           -- 到期日期
	   ,null as repay_mode         -- 还款方式
	   ,null as repay_freqcy       -- 还款频率
	   ,null as apply_busi_dist    -- 业务申请地行政区划代码
	   ,null as guar_mode          -- 担保方式
	   ,null as oth_repy_guar_way  -- 其他还款保证方式
	   ,null as loan_time_lim_cat  -- 借款期限分类
	   ,null as loan_form          -- 贷款发放形式
	   ,null as act_invest         -- 贷款实际投向
	   ,null as fund_sou           -- 业务经营类型
	   ,null as asset_trand_flag   -- 资产转让标志
	   ,coalesce(t1.loan_bank,t1.bank_brev) as init_cred_name -- 初始债权人名称
	   ,'' as init_cred_org_nm      -- 初始债权人机构代码
	   ,'41' as orig_dbt_cate       -- 原债务种类  41-垫款
--	   ,coalesce(t1.repay_stt,'2')as init_rpy_sts      -- 债权转移时的还款状态 1-逾期 1-30 天 2-逾期 31-60 天 3-逾期 61-90 天 4-逾期 91-120 天 5-逾期 121-150 天 6-逾期 151-180 天 7-逾期 180 天以上
       ,'3' as init_rpy_sts -- 债务转移时的还款状态            [这里全部默认为3]                            20251014
	   ,case when t3.is_close = '是' then '21' else '10' end as acct_status      -- 账户状态 10 正常活动 21-关闭 客户是否已偿还结清1：是0否
	   ,case when t3.is_close = '是' then 0 else t1.compt_amt - coalesce(t3.sum_rpy_amt,0) end as acct_bal -- 余额，代偿后余额变成0
--	   ,case when t3.guar_id is null then DATE_FORMAT(t1.compt_dt,'%Y-%m-%d')
       ,case when t3.guar_id is null then DATE_FORMAT(t7.compt_time,'%Y-%m-%d')                       -- 20251202 原来的代偿申请日期 --> 代偿拨付日期
			 else t3.lat_rpy_date end as repay_prd-- 余额变化日期（有还款取还款日）
	   ,'1' as five_cate        -- 五级分类
	   ,t7.compt_time  as five_cate_adj_date   -- 五级分类认定日期
	   ,null as rem_rep_prd   -- 剩余还款月数
	   ,null as tot_overd     -- 当前逾期总额
	   ,null as overd_princ   -- 当前逾期本金
	   ,null as overd_dy      -- 当前逾期天数
	   ,case when t3.guar_id is null then DATE_FORMAT(t7.compt_time,'%Y-%m-%d') else t3.lat_rpy_date end as lat_rpy_date -- 最近一次实际还款日期
	   ,case when t3.guar_id is null then 0 else t3.lat_rpy_amt end as lat_rpy_amt         -- 最近一次实际还款金额
	   ,case when t3.guar_id is null then 0 else t3.lat_rpy_amt end  as lat_rpy_princ_amt     -- 最近一次实际归还本金
	   ,'10' as rpmt_type -- 还款形式
	   ,null as lat_agrr_rpy_date   -- 最近一次约定还款日
	   ,null as lat_agrr_rpy_amt    -- 最近一次约定还款金额
	   ,null as nxt_agrr_rpy_date   -- 下一次约定还款日期
	   ,case when t3.is_close = '是' then t3.lat_rpy_date else '' end as close_date -- 账户关闭日期(归还日期)
from dw_tmp.tmp_imp_comp_compt_cust_info_compt t1    -- 企业代偿客户信息（加工脚本在exp_credit_comp_guar_info中,全删全插）
inner join dw_tmp.tmp_exp_credit_comp_cust_info_id_sq t4  -- 授权客户（加工脚本在exp_credit_comp_guar_info中,全删全插）
on t1.cert_no = t4.id_num
left join dw_tmp.tmp_exp_credit_comp_compt_info_repay t3  -- -- 最近还款情况
on t1.guar_id = t3.guar_id
left join dw_nd.ods_imp_comp_zzm t5 -- 手动录入中征码
on t1.guar_id = t5.guar_id
left join (
	select code,cust_identity_no,zhongzheng_code
	from (
		select id,code,cust_identity_no,zhongzheng_code,row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
		from dw_nd.ods_t_biz_project_main
	)t
	where rn = 1
) t6  -- 市管中心录入中征码
on t1.guar_id = t6.code
left join dw_base.dwd_guar_compt_info t7 on t7.guar_id= t1.guar_id
)t
where id_num is not null
;
commit;





-- -- 1.获取当天代偿台账
-- create  table dw_base.exp_credit_comp_compt_info_open (
--  ln_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,open_date	date	comment '开户日期'
--  ,key(ln_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;


delete from dw_base.exp_credit_comp_compt_info_open where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_compt_info_open
select ln_id
	   ,day_id
	   ,open_date
from dw_base.exp_credit_comp_compt_info_ready t1
where t1.day_id = '${v_sdate}'
and t1.open_date <= DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')     -- 放款日期为当天即新增，开户日期小于等于当天是保证首次报送的时候，包含所有历史数据
and not exists (         -- 首次开户客户
	select 1
	from dw_base.exp_credit_comp_compt_info_open t2    -- 开户
	where t2.day_id < '${v_sdate}'
	and t1.ln_id = t2.ln_id
)
;
commit;

-- 2.获取当天解保台账
-- create  table dw_base.exp_credit_comp_compt_info_close (
--  ln_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,close_date	date	comment '解保日期'
--  ,key(ln_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

delete from dw_base.exp_credit_comp_compt_info_close where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_compt_info_close

select ln_id
	   ,day_id
	   ,close_date
from dw_base.exp_credit_comp_compt_info_ready  t1
where day_id = '${v_sdate}'
and close_date is not null
and length(close_date)>0
and close_date <= DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
-- and close_date <> ''
and not exists (         -- 新增 关闭账户
	select 1
	from dw_base.exp_credit_comp_compt_info_close t2
	where t2.day_id < '${v_sdate}'
	and t1.ln_id = t2.ln_id
)
and  exists (
	select 1 from dw_base.exp_credit_comp_compt_info_open t2   -- 之前开户
	where t2.day_id < '${v_sdate}'  -- 当天开户的放在开户时点里了
	and t1.ln_id = t2.ln_id
)
and not exists (
	select 1 from dw_base.exp_credit_comp_compt_info_open t2   -- 当天未开户
	where t2.day_id = '${v_sdate}'
	and t1.ln_id = t2.ln_id
)
;
commit;

-- 33 实际还款（在非约定还款日还款）  41 五级分类调整 49 其他报送日

-- 3.获取当天收回逾期款项
-- create  table dw_base.exp_credit_comp_compt_info_repay_dt (
--  ln_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,lat_rpy_date	date	comment '最近一次实际还款日期'
--  ,key(ln_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;


delete from dw_base.exp_credit_comp_compt_info_repay_dt where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_compt_info_repay_dt
select guar_id
	   ,'${v_sdate}'
	   ,lat_rpy_date  -- 最近一次实际还款日期
from dw_tmp.tmp_exp_credit_comp_compt_info_repay t1
where  is_close = '否' -- 未结清
and t1.lat_rpy_date <= DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
and not exists (
	select 1 from dw_base.exp_credit_comp_compt_info_open t2 -- 余额变动 不能同时当天开户
	where t2.day_id = '${v_sdate}'
	and t1.guar_id = t2.ln_id
)
and not exists (  -- 非历史关户
	select 1 from dw_pbc.exp_credit_comp_compt_info t2
	where t2.day_id <= '${v_sdate}'
	and t2.rpt_date_code = '20' -- 关户
	and t1.guar_id = t2.ln_id
)
and  exists (
	select 1 from dw_base.exp_credit_comp_compt_info_open t2 --   之前开户
	where t2.day_id < '${v_sdate}'
	and t1.guar_id = t2.ln_id
)
and not exists (
	select 1 from dw_pbc.exp_credit_comp_compt_info t2
	where t2.day_id < '${v_sdate}'
	and t2.rpt_date_code = '33' -- 还款
	and t1.guar_id = t2.ln_id
	and t1.lat_rpy_date = t2.lat_rpy_date
)
;
commit;


-- 41 五级分类调整

-- create  table dw_base.exp_credit_comp_compt_info_risk_dt (
--  ln_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,risk_date	date	comment '最近一次实际还款日期'
--  ,key(ln_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;


delete from dw_base.exp_credit_comp_compt_info_risk_dt where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_compt_info_risk_dt
select ln_id
	   ,'${v_sdate}'
	   ,five_cate_adj_date
from dw_base.exp_credit_comp_compt_info_ready t1
where  t1.day_id = '${v_sdate}'
and t1.five_cate_adj_date = DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')
and not exists (
	select 1 from dw_base.exp_credit_comp_compt_info_open t2 -- 五级分类调整 不能同时当天开户
	where t2.day_id = '${v_sdate}'
	and t1.ln_id = t2.ln_id
)
and not exists (  -- 五级分类调整不能是历史关户客户
	select 1 from dw_pbc.exp_credit_comp_compt_info t2
	where t2.day_id <= '${v_sdate}'
	and t2.rpt_date_code = '20' -- 关户
	and t1.ln_id = t2.ln_id
)
and not exists (
	select 1 from dw_base.exp_credit_comp_compt_info_repay_dt t2 -- 五级分类调整 不能实际还款
	where t1.ln_id = t2.ln_id
	and t2.day_id = '${v_sdate}'
)
and exists (
	select 1 from dw_base.exp_credit_comp_compt_info_open t2 --   之前开户
	where t2.day_id < '${v_sdate}'
	and t1.ln_id = t2.ln_id
)
;
commit;

-- 49 其他信息变化
-- create  table dw_base.exp_credit_comp_compt_info_oth_dt (
--  ln_id	varchar(60)	comment '账号'
--  ,day_id 	varchar(8)	comment '日期'
--  ,change_date	date	comment '最近一次实际还款日期'
--  ,key(ln_id)
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

delete from dw_base.exp_credit_comp_compt_info_oth_dt where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_compt_info_oth_dt
select
	t1.ln_id
	,'${v_sdate}'
	,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')  -- 变动日期
from dw_base.exp_credit_comp_compt_info_ready t1
inner join dw_base.exp_credit_comp_compt_info_ready t2
on t1.ln_id = t2.ln_id
and t2.day_id = '${v_yesterday}'
and t2.ln_id is not null
and t1.loan_amt <> t2.loan_amt
where   t1.day_id = '${v_sdate}'
and not exists (
		select 1 from dw_base.exp_credit_comp_compt_info_open t2 -- 其他信息调整 不能同时当天开户
		where t2.day_id = '${v_sdate}'
		and t1.ln_id = t2.ln_id
		)
and not exists ( -- 非历史关户
		select 1 from dw_pbc.exp_credit_comp_compt_info t2
		where t2.day_id <= '${v_sdate}'
		and t2.rpt_date_code = '20' -- 关户
		and t1.ln_id = t2.ln_id
		)
and not exists (
		select 1 from dw_base.exp_credit_comp_compt_info_repay_dt t2 -- 其他信息调整 不能实际还款
		where t1.ln_id = t2.ln_id
		and t2.day_id = '${v_sdate}'
		)
and not exists (
		select 1 from dw_base.exp_credit_comp_compt_info_risk_dt t2 -- 其他信息调整 不能五级调整
		where t1.ln_id = t2.ln_id
		and t2.day_id = '${v_sdate}'
		)
and  exists (
		select 1 from dw_base.exp_credit_comp_compt_info_open t2 --   之前开户
		where t2.day_id < '${v_sdate}'
		and t1.ln_id = t2.ln_id
		)
;
commit;



delete from dw_base.exp_credit_comp_compt_info where day_id = '${v_sdate}';
commit;

-- 账户开立 10
insert into dw_base.exp_credit_comp_compt_info
select
	t1.day_id	             --	数据日期
	,t1.ln_id	             --	贷款ID
	,t1.cust_id	             --	客户号
	,t1.acct_type	         --	账户类型
	,t1.acct_code	         --	账户标识码
	,t1.rpt_date	         --	信息报告日期
	,'10'	                 --	报告时点说明代码
	,t1.name	             --	借款人名称
	,t1.id_type	             --	借款人身份标识类型
	,t1.id_num	             --	借款人身份标识号码
	,t1.mngmt_org_code	     --	业务管理机构代码
	,t1.busi_lines	         --	借贷业务大类
	,t1.busi_dtl_lines	     --	借贷业务种类细分
	,t1.open_date	         --	开户日期
	,t1.cy	                 --	币种
	,t1.acct_cred_line	     --	信用额度
	,t1.loan_amt	         --	借款金额
	,t1.flag	             --	分次放款标志
	,t1.due_date	         --	到期日期
	,t1.repay_mode	         --	还款方式
	,t1.repay_freqcy	     --	还款频率
	,t1.apply_busi_dist	     --	业务申请地行政区划代码
	,t1.guar_mode	         --	担保方式
	,t1.oth_repy_guar_way	 --	其他还款保证方式
	,t1.loan_time_lim_cat	 --	借款期限分类
	,t1.loan_form	         --	贷款发放形式
	,t1.act_invest	         --	贷款实际投向
	,t1.fund_sou	         --	业务经营类型
	,t1.asset_trand_flag	 --	资产转让标志
	,t1.init_cred_name	     --	初始债权人名称
	,t1.init_cred_org_nm	 --	初始债权人机构代码
	,t1.orig_dbt_cate	     --	原债务种类
	,t1.init_rpy_sts	     --	债权转移时的还款状态
	,t1.acct_status	         --	账户状态
	,t1.acct_bal	         --	余额
	,t1.repay_prd	         --	余额变化日期
	,t1.five_cate	         --	五级分类
	,t1.five_cate_adj_date	 --	五级分类认定日期
	,t1.rem_rep_prd	         --	剩余还款月数
	,t1.tot_overd	         --	当前逾期总额
	,t1.overd_princ	         --	当前逾期本金
	,t1.overd_dy	         --	当前逾期天数
	,t1.lat_rpy_date	     --	最近一次实际还款日期
	,t1.lat_rpy_amt	         --	最近一次实际还款金额
	,t1.lat_rpy_princ_amt	 --	最近一次实际归还本金
	,t1.rpmt_type	         --	还款形式
	,t1.lat_agrr_rpy_date	 --	最近一次约定还款日
	,t1.lat_agrr_rpy_amt	 --	最近一次约定还款金额
	,t1.nxt_agrr_rpy_date	 --	下一次约定还款日期
	,t1.close_date	         --	账户关闭日期
from  dw_base.exp_credit_comp_compt_info_ready  t1
inner join dw_base.exp_credit_comp_compt_info_open t2
on t1.ln_id = t2.ln_id
and t2.day_id = '${v_sdate}'
where t1.day_id = '${v_sdate}'
;
commit;

-- 账户关闭 20
insert into dw_base.exp_credit_comp_compt_info
select
	t1.day_id	             --	数据日期
	,t1.ln_id	             --	贷款ID
	,t1.cust_id	             --	客户号
	,t1.acct_type	         --	账户类型
	,t1.acct_code	         --	账户标识码
	,t1.rpt_date	         --	信息报告日期
	,'20'    	             --	报告时点说明代码
	,t1.name	             --	借款人名称
	,t1.id_type	             --	借款人身份标识类型
	,t1.id_num	             --	借款人身份标识号码
	,t1.mngmt_org_code	     --	业务管理机构代码
	,t1.busi_lines	         --	借贷业务大类
	,t1.busi_dtl_lines	     --	借贷业务种类细分
	,t1.open_date	         --	开户日期
	,t1.cy	                 --	币种
	,t1.acct_cred_line	     --	信用额度
	,t1.loan_amt	         --	借款金额
	,t1.flag	             --	分次放款标志
	,t1.due_date	         --	到期日期
	,t1.repay_mode	         --	还款方式
	,t1.repay_freqcy	     --	还款频率
	,t1.apply_busi_dist	     --	业务申请地行政区划代码
	,t1.guar_mode	         --	担保方式
	,t1.oth_repy_guar_way	 --	其他还款保证方式
	,t1.loan_time_lim_cat	 --	借款期限分类
	,t1.loan_form	         --	贷款发放形式
	,t1.act_invest	         --	贷款实际投向
	,t1.fund_sou	         --	业务经营类型
	,t1.asset_trand_flag	 --	资产转让标志
	,t1.init_cred_name	     --	初始债权人名称
	,t1.init_cred_org_nm	 --	初始债权人机构代码
	,t1.orig_dbt_cate	     --	原债务种类
	,t1.init_rpy_sts	     --	债权转移时的还款状态
	,t1.acct_status	         --	账户状态
	,t1.acct_bal	         --	余额
	,t1.repay_prd	         --	余额变化日期
	,t1.five_cate	         --	五级分类
	,t1.five_cate_adj_date	 --	五级分类认定日期
	,t1.rem_rep_prd	         --	剩余还款月数
	,t1.tot_overd	         --	当前逾期总额
	,t1.overd_princ	         --	当前逾期本金
	,t1.overd_dy	         --	当前逾期天数
	,t1.lat_rpy_date	     --	最近一次实际还款日期
	,t1.lat_rpy_amt	         --	最近一次实际还款金额
	,t1.lat_rpy_princ_amt	 --	最近一次实际归还本金
	,t1.rpmt_type	         --	还款形式
	,t1.lat_agrr_rpy_date	 --	最近一次约定还款日
	,t1.lat_agrr_rpy_amt	 --	最近一次约定还款金额
	,t1.nxt_agrr_rpy_date	 --	下一次约定还款日期
	,t1.close_date	         --	账户关闭日期
from  dw_base.exp_credit_comp_compt_info_ready  t1
inner join dw_base.exp_credit_comp_compt_info_close t2
on t1.ln_id = t2.ln_id
and t2.day_id = '${v_sdate}'
where t1.day_id ='${v_sdate}'
and t1.close_date = DATE_FORMAT('${v_sdate}','%Y-%m-%d')
;
commit ;

-- 实际还款 33
insert into dw_base.exp_credit_comp_compt_info
select
	t1.day_id	               --	数据日期
	,t1.ln_id	               --	贷款ID
	,t1.cust_id	               --	客户号
	,t1.acct_type              --	账户类型
	,t1.acct_code              --	账户标识码
	,t1.rpt_date               --	信息报告日期
	,'33'	                   --	报告时点说明代码
	,t1.name	               --	借款人名称
	,t1.id_type	               --	借款人身份标识类型
	,t1.id_num	               --	借款人身份标识号码
	,t1.mngmt_org_code	       --	业务管理机构代码
	,t1.busi_lines	           --	借贷业务大类
	,t1.busi_dtl_lines	       --	借贷业务种类细分
	,t1.open_date	           --	开户日期
	,t1.cy	                   --	币种
	,t1.acct_cred_line	       --	信用额度
	,t1.loan_amt               --	借款金额
	,t1.flag	               --	分次放款标志
	,t1.due_date               --	到期日期
	,t1.repay_mode	           --	还款方式
	,t1.repay_freqcy           --	还款频率
	,t1.apply_busi_dist	       --	业务申请地行政区划代码
	,t1.guar_mode	           --	担保方式
	,t1.oth_repy_guar_way	   --	其他还款保证方式
	,t1.loan_time_lim_cat	   --	借款期限分类
	,t1.loan_form	           --	贷款发放形式
	,t1.act_invest	           --	贷款实际投向
	,t1.fund_sou	           --	业务经营类型
	,t1.asset_trand_flag	   --	资产转让标志
	,t1.init_cred_name	       --	初始债权人名称
	,t1.init_cred_org_nm	   --	初始债权人机构代码
	,t1.orig_dbt_cate          --	原债务种类
	,t1.init_rpy_sts           --	债权转移时的还款状态
	,t1.acct_status	           --	账户状态
	,t1.acct_bal	           --	余额
	,t1.repay_prd	           --	余额变化日期
	,t1.five_cate	           --	五级分类
	,t1.five_cate_adj_date	   --	五级分类认定日期
	,t1.rem_rep_prd	           --	剩余还款月数
	,t1.tot_overd	           --	当前逾期总额
	,t1.overd_princ	           --	当前逾期本金
	,t1.overd_dy	           --	当前逾期天数
	,t1.lat_rpy_date           --	最近一次实际还款日期
	,t1.lat_rpy_amt	           --	最近一次实际还款金额
	,t1.lat_rpy_princ_amt	   --	最近一次实际归还本金
	,t1.rpmt_type	           --	还款形式
	,t1.lat_agrr_rpy_date	   --	最近一次约定还款日
	,t1.lat_agrr_rpy_amt	   --	最近一次约定还款金额
	,t1.nxt_agrr_rpy_date	   --	下一次约定还款日期
	,t1.close_date	           --	账户关闭日期
from  dw_base.exp_credit_comp_compt_info_ready  t1
inner join dw_base.exp_credit_comp_compt_info_repay_dt t2
on t1.ln_id = t2.ln_id
and t2.day_id = '${v_sdate}'
where t1.day_id ='${v_sdate}'
;
commit;



-- 41 五级分类调整
insert into dw_base.exp_credit_comp_compt_info
select
	t1.day_id	                    --	数据日期
	,t1.ln_id	                    --	贷款ID
	,t1.cust_id	                    --	客户号
	,t1.acct_type                   --	账户类型
	,t1.acct_code                   --	账户标识码
	,t1.rpt_date                    --	信息报告日期
	,'41'	                        --	报告时点说明代码
	,t1.name	                    --	借款人名称
	,t1.id_type	                    --	借款人身份标识类型
	,t1.id_num	                    --	借款人身份标识号码
	,t1.mngmt_org_code	            --	业务管理机构代码
	,t1.busi_lines	                --	借贷业务大类
	,t1.busi_dtl_lines	            --	借贷业务种类细分
	,t1.open_date	                --	开户日期
	,t1.cy	                        --	币种
	,t1.acct_cred_line	            --	信用额度
	,t1.loan_amt                    --	借款金额
	,t1.flag	                    --	分次放款标志
	,t1.due_date                    --	到期日期
	,t1.repay_mode	                --	还款方式
	,t1.repay_freqcy	            --	还款频率
	,t1.apply_busi_dist	            --	业务申请地行政区划代码
	,t1.guar_mode	                --	担保方式
	,t1.oth_repy_guar_way	        --	其他还款保证方式
	,t1.loan_time_lim_cat	        --	借款期限分类
	,t1.loan_form	                --	贷款发放形式
	,t1.act_invest	                --	贷款实际投向
	,t1.fund_sou	                --	业务经营类型
	,t1.asset_trand_flag	        --	资产转让标志
	,t1.init_cred_name	            --	初始债权人名称
	,t1.init_cred_org_nm	        --	初始债权人机构代码
	,t1.orig_dbt_cate               --	原债务种类
	,t1.init_rpy_sts                --	债权转移时的还款状态
	,t1.acct_status	                --	账户状态
	,t1.acct_bal	                --	余额
	,t1.repay_prd	                --	余额变化日期
	,t1.five_cate	                --	五级分类
	,t1.five_cate_adj_date	        --	五级分类认定日期
	,t1.rem_rep_prd	                --	剩余还款月数
	,t1.tot_overd	                --	当前逾期总额
	,t1.overd_princ	                --	当前逾期本金
	,t1.overd_dy	                --	当前逾期天数
	,t1.lat_rpy_date                --	最近一次实际还款日期
	,t1.lat_rpy_amt	                --	最近一次实际还款金额
	,t1.lat_rpy_princ_amt	        --	最近一次实际归还本金
	,t1.rpmt_type	                --	还款形式
	,t1.lat_agrr_rpy_date	        --	最近一次约定还款日
	,t1.lat_agrr_rpy_amt	        --	最近一次约定还款金额
	,t1.nxt_agrr_rpy_date	        --	下一次约定还款日期
	,t1.close_date	                --	账户关闭日期
from  dw_base.exp_credit_comp_compt_info_ready  t1
inner join dw_base.exp_credit_comp_compt_info_risk_dt t2
on t1.ln_id = t2.ln_id
and t2.day_id = '${v_sdate}'
where t1.day_id ='${v_sdate}'
;
commit;



-- 49 其他报送日
insert into dw_base.exp_credit_comp_compt_info
select
	t1.day_id	                     --	数据日期
	,t1.ln_id	                     --	贷款ID
	,t1.cust_id	                     --	客户号
	,t1.acct_type                    --	账户类型
	,t1.acct_code                    --	账户标识码
	,t1.rpt_date	                 --	信息报告日期
	,'49'	                         --	报告时点说明代码
	,t1.name	                     --	借款人名称
	,t1.id_type	                     --	借款人身份标识类型
	,t1.id_num	                     --	借款人身份标识号码
	,t1.mngmt_org_code	             --	业务管理机构代码
	,t1.busi_lines	                 --	借贷业务大类
	,t1.busi_dtl_lines	             --	借贷业务种类细分
	,t1.open_date	                 --	开户日期
	,t1.cy	                         --	币种
	,t1.acct_cred_line	             --	信用额度
	,t1.loan_amt                     --	借款金额
	,t1.flag	                     --	分次放款标志
	,t1.due_date	                 --	到期日期
	,t1.repay_mode	                 --	还款方式
	,t1.repay_freqcy	             --	还款频率
	,t1.apply_busi_dist              --	业务申请地行政区划代码
	,t1.guar_mode	                 --	担保方式
	,t1.oth_repy_guar_way	         --	其他还款保证方式
	,t1.loan_time_lim_cat	         --	借款期限分类
	,t1.loan_form	                 --	贷款发放形式
	,t1.act_invest	                 --	贷款实际投向
	,t1.fund_sou	                 --	业务经营类型
	,t1.asset_trand_flag	         --	资产转让标志
	,t1.init_cred_name	             --	初始债权人名称
	,t1.init_cred_org_nm	         --	初始债权人机构代码
	,t1.orig_dbt_cate	             --	原债务种类
	,t1.init_rpy_sts	             --	债权转移时的还款状态
	,t1.acct_status	                 --	账户状态
	,t1.acct_bal	                 --	余额
	,t1.repay_prd	                 --	余额变化日期
	,t1.five_cate	                 --	五级分类
	,t1.five_cate_adj_date	         --	五级分类认定日期
	,t1.rem_rep_prd	                 --	剩余还款月数
	,t1.tot_overd	                 --	当前逾期总额
	,t1.overd_princ	                 --	当前逾期本金
	,t1.overd_dy	                 --	当前逾期天数
	,t1.lat_rpy_date                 --	最近一次实际还款日期
	,t1.lat_rpy_amt	                 --	最近一次实际还款金额
	,t1.lat_rpy_princ_amt	         --	最近一次实际归还本金
	,t1.rpmt_type                    --	还款形式
	,t1.lat_agrr_rpy_date	         --	最近一次约定还款日
	,t1.lat_agrr_rpy_amt	         --	最近一次约定还款金额
	,t1.nxt_agrr_rpy_date	         --	下一次约定还款日期
	,t1.close_date	                 --	账户关闭日期
from  dw_base.exp_credit_comp_compt_info_ready  t1
inner join dw_base.exp_credit_comp_compt_info_oth_dt t2
on t1.ln_id = t2.ln_id
and t2.day_id = '${v_sdate}'
where t1.day_id ='${v_sdate}'
;
commit;
-- 
-- 插入老系统已代偿项目的追偿信息，只插入  非月度表现信息段 字段，作为增量报送                      20251014
insert into dw_base.exp_credit_comp_compt_info(
	 day_id	                     --	数据日期
	,ln_id	                     --	贷款ID
	,cust_id	                 --	客户号
	,rpt_date_code               --	报告时点说明代码
	,acct_code                   --	账户标识码
	,acct_status	             --	账户状态
	,acct_bal	                 --	余额
	,repay_prd	                 --	余额变化日期
	,five_cate	                 --	五级分类
	,five_cate_adj_date	         --	五级分类认定日期
	,rem_rep_prd	                 --	剩余还款月数
	,tot_overd	                 --	当前逾期总额
	,overd_princ	                 --	当前逾期本金
	,overd_dy	                 --	当前逾期天数
	,lat_rpy_date                 --	最近一次实际还款日期
	,lat_rpy_amt	                 --	最近一次实际还款金额
	,lat_rpy_princ_amt	         --	最近一次实际归还本金
	,rpmt_type                    --	还款形式
	,lat_agrr_rpy_date	         --	最近一次约定还款日
	,lat_agrr_rpy_amt	         --	最近一次约定还款金额
	,nxt_agrr_rpy_date	         --	下一次约定还款日期
	,close_date	                 --	账户关闭日期
)
select 	 day_id	                     --	数据日期
	,tt1.ln_id	                     --	贷款ID
	,cust_id	                     --	客户号
	,rpt_date_code               --	报告时点说明代码
	,acct_code                    --	账户标识码
	,acct_status	                 --	账户状态
	,acct_bal	                 --	余额
	,repay_prd	                 --	余额变化日期
	,five_cate	                 --	五级分类
	,five_cate_adj_date	         --	五级分类认定日期
	,rem_rep_prd	                 --	剩余还款月数
	,tot_overd	                 --	当前逾期总额
	,overd_princ	                 --	当前逾期本金
	,overd_dy	                 --	当前逾期天数
	,lat_rpy_date                 --	最近一次实际还款日期
	,lat_rpy_amt	                 --	最近一次实际还款金额
	,lat_rpy_princ_amt	         --	最近一次实际归还本金
	,rpmt_type                    --	还款形式
	,lat_agrr_rpy_date	         --	最近一次约定还款日
	,lat_agrr_rpy_amt	         --	最近一次约定还款金额
	,nxt_agrr_rpy_date	         --	下一次约定还款日期
	,close_date	                 --	账户关闭日期
from (
select     
 '${v_sdate}' as day_id,  
			IFNULL(ACCT_NO,'')     as ln_id,              -- 合同号[用来关联老系统的旧数据]
		    CUST_ID,           
            if(ACCT_BAL = 0,'20','33') as rpt_date_code,                          --	报告时点说明代码			[余额为0就是关户，其他为正常还款状态]
		    concat(date_format(LAT_RPY_DATE,'%Y%m%d'),replace(replace(GUARANTEE_CODE,'-',''),'贷','D'))          as acct_code,          -- 最近一次还款日期 + 项目编号  
--            IFNULL(ACCT_STATUS,'') as ACCT_STATUS,   -- 账户状态
            if(ACCT_BAL = 0,'21','10') as  ACCT_STATUS,   -- 账户状态
            ACCT_BAL,       -- 余额
            IFNULL(DATE(BAL_CHG_DATE),'') as repay_prd,                                             -- 余额变化日期  
            IFNULL(FIVE_LEVEL_CLASSIFICATION,'') as FIVE_CATE,  -- 五级分类
            IFNULL(DATE(FIVE_CATE_ADJ_DATE),'')  as FIVE_CATE_ADJ_DATE,  -- 五级分类认定日期
--            null   as FIVE_CATE,                                  -- 五级分类
--            null   as FIVE_CATE_ADJ_DATE,                         -- 五级分类认定日期
            null as rem_rep_prd,                                -- 剩余还款月数  
            null as TOT_OVERD,                                  -- 当前逾期总额
            null as OVERD_PRINC,                                -- 当前逾期本金
            null as OVERD_DY,                                   -- 当前逾期天数
            IFNULL(DATE(LAT_RPY_DATE),'') as LAT_RPY_DATE,                   -- 最近一次实际还款日期        
            IFNULL(LAT_RPY_AMT,'')        as LAT_RPY_AMT,                           -- 最近一次实际还款金额
            IFNULL(LAT_RPY_PRINC_AMT,'')  as LAT_RPY_PRINC_AMT,               -- 最近一次实际归还本金
            '10'                          as RPMT_TYPE,                                       -- 还款形式
            IFNULL(DATE(LAT_AGRR_RPY_DATE),'') as LAT_AGRR_RPY_DATE, -- 最近一次约定还款日
            IFNULL(LAT_AGRR_RPY_AMT,'')   as LAT_AGRR_RPY_AMT,         -- 最近一次约定还款金额
            null as NXT_AGRR_RPY_DATE,                                 -- 下一次约定还款日期                                
            if(ACCT_BAL = 0,DATE(LAT_RPY_DATE),'') as close_date,              -- 账户关闭日期
			row_number() over(partition by case when ACCT_BAL = 0 then GUARANTEE_CODE end order by LAT_RPY_DATE) as rn    -- [根据项目编号分组，对金额为0的用入账日期排序由小到大]
            from (
                   select t4.id 'CUST_ID'
				         ,t1.GUARANTEE_CODE
						 ,replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace
                          (replace(replace(t5.WTBZHT_NO,'char(9)',''),'年委保字','NWBZ'),'“',''),'号','H'),'年担字第','NDZD')
                          ,'-',''),'"',''),'第','D'),'”',''),' ',''),'年见贷即保','NJDJB'),'个担贷字','GDDZ'),'特例','TL'),'委保字','WBZ')'ACCT_NO'
						 ,if(t2.OVER_TAG ='BJ','21',10)'ACCT_STATUS'
--						 ,if(t2.OVER_TAG ='BJ','0.00',t1.BALANCE_CLAIM) 'ACCT_BAL'
--                       ,if(t2.OVER_TAG ='BJ','0.00',round(coalesce(t3.TOTAL_COMPENSATION,0) - coalesce(t8.CUR_RECOVERY,0))) as ACCT_BAL
                         ,case when round(coalesce(t3.TOTAL_COMPENSATION,0) - coalesce(t8.CUR_RECOVERY,0)) < 1 then 0
						       else round(coalesce(t3.TOTAL_COMPENSATION,0) - coalesce(t8.CUR_RECOVERY,0)) end as ACCT_BAL    -- 余额
						 ,t3.PAYMENT_DATE'FIVE_CATE_ADJ_DATE'
						 ,ifnull(t1.ENTRY_DATA,t3.PAYMENT_DATE) 'BAL_CHG_DATE'
						 ,t1.ENTRY_DATA 'LAT_RPY_DATE'
						 ,round(t1.CUR_RECOVERY) 'LAT_RPY_AMT'
						 ,round(t1.CUR_RECOVERY) 'LAT_RPY_PRINC_AMT'
						 ,t7.LAT_AGRR_RPY_DATE
						 ,round(t7.RECEIPT_AMOUNT) 'LAT_AGRR_RPY_AMT'
--						 ,if(t2.OVER_TAG =  'BJ',t2.OVER_TIME,null) 'CLOSE_DATA'
						 ,t6.FIVE_LEVEL_CLASSIFICATION
					from (
                           select ID_RECOVERY_TRACKING  -- 关联追偿跟踪id
				                 ,GUARANTEE_CODE        -- 项目编号
				                 ,BALANCE_CLAIM         -- 剩余债权
				                 ,ENTRY_DATA            -- 入账日期
								 ,date_format(ENTRY_DATA,'%Y%m%d') as ENTRY_DATA_1
				                 ,sum(CUR_RECOVERY) * 10000 as CUR_RECOVERY          -- （本次）追回金额（元）
				           from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail            -- 追偿详情表
					       where 1 = 1
					       and date_format(CREATED_TIME,'%Y%m%d') = '${v_sdate}' 
						   and `STATUS` ='1'
                           and GUARANTEE_CODE != 'TJRD-2021-5M92-9497'          -- 这笔项目有问题，暂不上报(临时)
				           group by ID_RECOVERY_TRACKING,GUARANTEE_CODE,date_format(ENTRY_DATA,'%Y%m%d')				     					 
					     ) t1	 
					left join (
				                select ID
							          ,ID_CFBIZ_UNDERWRITING
							    	  ,RELATED_ITEM_NO      -- 关联项目编号
							          ,OVER_TAG             -- 追偿跟踪状态 （BJ  办结）
							          ,COMPENSATION_BALANCE -- 代偿余额
							    	  ,over_time            -- 追偿跟踪办结时间
							    FROM dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking              -- bh_recovery_tracking       追偿表
							    where `STATUS` ='1'       
						      ) t2
		            on ifnull(t1.ID_RECOVERY_TRACKING = t2.ID,t1.GUARANTEE_CODE = t2.RELATED_ITEM_NO)		 
					left join (
				                select ID_NO
				    			      ,ID_CFBIZ_UNDERWRITING  -- 关联合同ID
									  ,PAYMENT_DATE
									  ,TOTAL_COMPENSATION * 10000 as TOTAL_COMPENSATION  -- 代偿总额（元）
				    		    from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory                    -- 代偿表
				    			where `STATUS` ='1' and OVER_TAG ='BJ'
				    		  ) t3                
				    on t2.ID_CFBIZ_UNDERWRITING = t3.ID_CFBIZ_UNDERWRITING
				    left join (
				                select ID_NUMBER
							      ,id                      -- cust_id
								  ,ID_BUSINESS_INFORMATION -- 业务主键
								  ,CERT_TYPE       -- 证件类型
								  ,CUSTOMER_NATURE -- 客户性质
		                        from  dw_nd.ods_creditmid_v2_z_migrate_base_customers_history            -- 客户信息历史表,
		                        where CERT_TYPE ='2'  -- [企业]
				    		  ) t4
--		            on t3.ID_NO = t4.ID_NUMBER                                    -- [个人的关联条件]
                    on t3.ID_CFBIZ_UNDERWRITING = t4.ID_BUSINESS_INFORMATION      -- [企业的关联条件]
				    left join (
				                select ID_BUSINESS_INFORMATION
				    			      ,WTBZHT_NO   -- 委托保证合同编号
                                from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval             -- 审批
		            	        where delete_flag ='1'
				    		  ) t5 
		            on t3.ID_CFBIZ_UNDERWRITING = t5.ID_BUSINESS_INFORMATION
				    left join (
				                select id
				    			      ,FIVE_LEVEL_CLASSIFICATION  -- 五级分类
                                from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation           -- 业务申请表
		            	        where delete_flag ='1'
				    		  ) t6
				    on t3.ID_CFBIZ_UNDERWRITING = t6.id	
                    left join (
					            select min(LOAN_START_DATE) LOAN_START_DATE
				                      ,ID_BUSINESS_INFORMATION
									  ,LOAN_END_DATE
									  ,max(LOAN_END_DATE) LAT_AGRR_RPY_DATE
									  ,RECEIPT_AMOUNT 
				                from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation            -- 放款凭证表 
							    where delete_flag ='1' or DELETE_FLAG is null 
							    group by ID_BUSINESS_INFORMATION
							  ) t7 
				   on t3.ID_CFBIZ_UNDERWRITING = t7.ID_BUSINESS_INFORMATION	
				   left join (
				               select ID_RECOVERY_TRACKING  -- 关联追偿跟踪id
				                 ,GUARANTEE_CODE        -- 项目编号
				                 ,date_format(ENTRY_DATA,'%Y%m%d') as ENTRY_DATA_1            -- 入账日期
				                  ,sum(CUR_RECOVERY) over(partition by GUARANTEE_CODE order by date_format(ENTRY_DATA,'%Y%m%d')) * 10000 as CUR_RECOVERY          -- （累计）追回金额（元）[本次及之前的金额]
				               from dw_nd.ods_creditmid_v2_z_migrate_bh_recovery_tracking_detail            -- 追偿详情表
							   group by ID_RECOVERY_TRACKING,GUARANTEE_CODE,date_format(ENTRY_DATA,'%Y%m%d')
							 ) t8
					on t1.GUARANTEE_CODE = t8.GUARANTEE_CODE and t1.ENTRY_DATA_1 = t8.ENTRY_DATA_1
                   where t4.CUSTOMER_NATURE = 'enterprise'       -- [企业]				   
				) t 	
     ) tt1		
left join (select ln_id from dw_base.exp_credit_comp_compt_info where day_id < '${v_sdate}' and ACCT_BAL = 0) tt2
on tt1.ln_id = tt2.ln_id
where tt1.ACCT_BAL != 0 or (tt1.ACCT_BAL = 0 and tt1.rn = 1 and tt2.ln_id is null)	  -- [本次余额不为空0的继续上报；本次余额为0的，取最小的追偿入账日期，且之前的追偿余额不能是0]
;
commit;

-- 相关还款责任人(只有新开户的时候报送)

-- 每笔业务对应的反担保人信息,共同借款人信息
drop table if exists dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter ;
commit;

create table dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter (
	duty_type          varchar(60),
	apply_code         varchar(60),
	project_id         varchar(60),
	counter_name       varchar(60),
	id_type            varchar(4),
	id_no              varchar(40),
	index idx_tmp_exp_credit_comp_compt_info_xz_counter_project_id(project_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter

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
					row_number() over (partition by apply_code order by update_time desc) as rn
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
				   row_number() over (partition by apply_code,id_no,counter_name order by update_time desc) as rn
			from dw_nd.ods_bizhall_guar_apply_counter -- 反担保关联表  status状态字段不用限制
			where date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
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
					row_number() over (partition by apply_code order by update_time desc) as rn
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
				upper(id_no) id_no,
				row_number() over (partition by apply_code,upper(id_no) order by update_time desc) as rn
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
		select id,code,spouse_co_borrower,row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
		from dw_nd.ods_t_biz_project_main
	)t
	where rn = 1
) t3
on t1.guar_id = t3.id and t3.spouse_co_borrower is true
;
commit;


-- 授权的反担保人
drop table if exists dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_sq ;
commit;

create table dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_sq (
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

insert into dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_sq
select
	   t.duty_type, -- 1-共同债务人 2-反担保人 9-其他
	   t.apply_code,
	   t.project_id,   -- 担保业务系统ID
	   t.counter_name,  -- 反担保人/共同借款人名称
	   coalesce(t.id_type,t2.id_type),  -- 反担保人/共同借款人证件类型
	   coalesce(t.id_no,t2.id_no),  -- 反担保人/共同借款人证件号
	   t2.cust_code  -- 反担保人/共同借款人客户号
from dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter t -- 每笔申请记录对应的反担保人信息
inner join
(
  select customer_id
		,main_name
		,main_id_type
		,main_id_no
  from
  (
	select customer_id,main_name,main_id_type,main_id_no,row_number() over (partition by main_id_no order by update_time desc) as rn
	from dw_nd.ods_wxapp_cust_login_info     -- 用户注册信息
	where status = '10'  -- 已授权   授权的客户证件号都不为空，去掉了 customer_id is not null and main_id_no is null 这个条件
  ) t
  where rn = 1
)t1
on t.id_no = t1.main_id_no
left join (select cust_code,id_no,id_type from (
	select cust_code,id_no,id_type,row_number() over (partition by cust_code order by update_time desc) rn from dw_nd.ods_crm_cust_info
	)t where rn = 1
	)t2   -- mdy 20240911，之前是按照id_No取最新，但是会存在一个证件号对应多个客户号的情况，漏掉客户号，导致后面关联不到合同
on t.id_no = t2.id_no
;
commit;

-- 反担保合同
drop table if exists dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_contract ;
commit;

create table dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_contract (
	biz_id                varchar(64),
	contract_id           varchar(128),
	customer_id           varchar(64),
	contract_template_id  varchar(64),
	index idx_tmp_exp_credit_comp_compt_info_xz_counter_contract_biz_id(biz_id),
	index tmp_exp_credit_comp_compt_info_xz_counter_contract_customer_id(customer_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_contract
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
		   ,row_number() over (partition by biz_id,contract_id order by update_time desc) as rn
	from dw_nd.ods_comm_cont_comm_contract_info
	where contract_name like '%反担保%'
)a
where rn = 1
)t
where status = '2' -- 已签约
;
commit;

-- 补充反担保合同（线下签约）[合同号带‘线下’字样的属于线下签约]
drop table if exists dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_contract_xx ;
commit;

create table dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_contract_xx (
	project_id                varchar(64),
	ct_guar_person_name       varchar(128),
	ct_guar_person_id_no      varchar(64),
	count_cont_code           varchar(64),
	index idx_tmp_xz_counter_contract_xx_project_id(project_id),
	index idx_tmp_xz_counter_contract_xx_ct_guar_person_id_no(ct_guar_person_id_no)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_contract_xx
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
		   ,row_number() over (partition by project_id order by db_update_time desc,update_time desc) as rn
	from dw_nd.ods_t_ct_guar_person
)t
where rn = 1
;
commit;

-- 担保业务系统id 和项目编号转换
drop table if exists dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_main;
commit;

create table dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_main (
	project_id         varchar(60),
	guar_id            varchar(60),
	index credit_per_guar_info_xz_counter_main_project_id(project_id),
	index credit_per_guar_info_xz_counter_main_ct_guar_person_id_no(guar_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_main
select id,
	   code
from (
select id,
	   code,
	   row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
from dw_nd.ods_t_biz_project_main
)a
where rn = 1
;
commit;


-- 从风险检查表中拿产业集群信息
drop table if exists dw_tmp.tmp_exp_credit_comp_compt_info_check;
commit;

create table dw_tmp.tmp_exp_credit_comp_compt_info_check (
	project_id         varchar(60),
	aggregate_scheme   varchar(60),
	index tmp_exp_credit_comp_guar_info_checkproject_id(project_id),
	index tmp_exp_credit_comp_guar_info_check_aggregate_scheme(aggregate_scheme)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
;
commit;

insert into dw_tmp.tmp_exp_credit_comp_compt_info_check
select project_id,
	   aggregate_scheme
from (
select project_id,
	   aggregate_scheme,
	   row_number() over (partition by project_id order by update_time desc) as rn
from dw_nd.ods_t_risk_check_opinion
)a
where rn = 1
;
commit;

-- 核心企业管理中企业分险
drop table if exists dw_tmp.tmp_exp_credit_comp_compt_info_risk_comp;commit;
create table if not exists dw_tmp.tmp_exp_credit_comp_compt_info_risk_comp(
company_name varchar(200) comment'企业名称',
unified_social_credit_code varchar(50) comment '统一社会信用代码',
counter_guar_contract_number varchar(50) comment '反担保合同',
risk_grade varchar(255) comment'分险比例',
dictionaries_code varchar(50) comment '产业集群'
);
commit;

insert into dw_tmp.tmp_exp_credit_comp_compt_info_risk_comp
select t1.company_name,t1.unified_social_credit_code,t2.counter_guar_contract_number,t2.risk_grade,t2.dictionaries_code
from (
	select * from (
		select *,row_number() over (partition by id order by update_time desc) rn from dw_nd.ods_cem_company_base -- 核心企业基本表
	)t
	where rn = 1
)t1
inner join (
	select * from (
		select *,row_number() over (partition by id order by update_time desc) as rn from dw_nd.ods_cem_dictionaries  -- 企业产业集群关系
	)t
	where rn = 1
)t2
on t1.id = t2.cem_base_id -- 核心企业id    【经沟通，ods_cem_company_base的分险比例字段废弃，企业的分险比例用关系表中的】
;
commit;

-- 核心企业管理中自然人分险
drop table if exists dw_tmp.tmp_exp_credit_comp_compt_info_risk_natural;commit;
create table if not exists dw_tmp.tmp_exp_credit_comp_compt_info_risk_natural(
person_name varchar(200) comment'自然人名称',
person_identity varchar(50) comment '证件号',
counter_guar_contract_number varchar(50) comment '反担保合同',
risk_grade varchar(255) comment'分险比例',
dictionaries_code varchar(50) comment '产业集群'
);
commit;

insert into dw_tmp.tmp_exp_credit_comp_compt_info_risk_natural
select t1.person_name,t1.person_identity,t1.counter_guar_contract_number,t1.risk_grade,t2.dictionaries_code
	from (
		select id,person_name,person_identity,counter_guar_contract_number,risk_grade,cem_dictionaries_id
		from (
			select id,person_name,person_identity,counter_guar_contract_number,risk_grade,cem_dictionaries_id,row_number() over (partition by id order by update_time desc) as rn
			from dw_nd.ods_cem_natural -- 自然人基本表
		)t
		where rn = 1
	)t1
	inner join (
		select * from (
			select *,row_number() over (partition by id order by update_time desc) as rn from dw_nd.ods_cem_dictionaries  -- 企业产业集群关系
		)t
		where rn = 1
	)t2
on t1.cem_dictionaries_id = t2.id
;
commit;


-- 还款责任人信息
DELETE FROM dw_base.exp_credit_comp_compt_repay_duty_info where day_id = '${v_sdate}' ;
commit;
insert into dw_base.exp_credit_comp_compt_repay_duty_info
select * from (
select day_id,
	   ln_id,
	   cust_id,
	   info_id_type,
	   duty_name,
	   duty_cert_type,
	   duty_cert_no,
	   duty_type,
	   case when t.duty_type='2' and t1.company_name is not null and t1.risk_grade <> '' and t1.risk_grade is not null then t.duty_amt*t1.risk_grade
			when t.duty_type='2' and t2.person_name is not null and t2.risk_grade <> '' and t2.risk_grade is not null then t.duty_amt*t2.risk_grade
			when t.duty_type='2' then t.duty_amt
			else null
		end as duty_amt,
	   case when t.duty_type='2' and  t1.company_name is not null then concat(t1.counter_guar_contract_number,t.ln_id)
			when t.duty_type='2' and  t2.person_name is not null then concat(t2.counter_guar_contract_number,t.ln_id)
			when t.duty_type='2' then t.guar_cont_no
			else null
		end as guar_cont_no  -- 反担保合同
from (
select '${v_sdate}' as day_id,
	   t.ln_id,  -- 担保ID
	   t.cust_id,  -- 客户号
	   case when t2.id_type in ('01','10') then '1' when t2.id_type in ('02','20') then '2' else null end as info_id_type,  -- 身份类别  1-自然人  2-组织机构
	   t2.counter_name as duty_name, -- 责任人名称
	   '10' as duty_cert_type,  -- 责任人身份标识类型  10:居民身份证及其他以公民身份证号为标识的证件 20-统一社会信用代码
	   case when t2.id_type in ('01','10')  then t2.id_no when t2.id_type in ('02','20') then coalesce(t6.id_num,t7.zhongzheng_code) else null end as duty_cert_no,  -- 责任人身份标识号码
	   t2.duty_type, -- 1-共同债务人 2-反担保人 9-其他
	   case when t2.duty_type='2' then t.loan_amt else null end as duty_amt, -- 还款责任金额(担保金额)
	   case when t2.duty_type='2' then coalesce(t5.contract_id,t4.contract_id,t8.count_cont_code)
			else null
			end as guar_cont_no, -- 反担保合同编号
	   t7.ct_guar_person_id_no, -- 企业统一社会编码
	   t9.aggregate_scheme
from dw_base.exp_credit_comp_compt_info t
inner join dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_main t1  -- -- 担保业务系统id 和项目编号转换
on t.ln_id = t1.guar_id
inner join dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_sq t2  -- 授权的反担保人信息
on t1.project_id = t2.project_id
left join dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_contract t4
on t2.apply_code = t4.biz_id
and t2.cust_code = t4.customer_id  -- 客户号
and t2.duty_type='2'
left join dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_contract t5
on t2.apply_code = t5.biz_id
and t2.id_no = t5.customer_id  -- 证件号
left join dw_nd.ods_imp_comp_zzm t6
on t.ln_id = t6.guar_id
and t6.cust_type = '02' -- 反担保人
and t2.duty_type='2'
left join (
	select project_id,ct_guar_person_name,zhongzheng_code,ct_guar_person_id_no
	from (
		select id,project_id,ct_guar_person_name,zhongzheng_code,ct_guar_person_id_no,row_number() over (partition by id order by db_update_time desc,update_time desc) as rn
		from dw_nd.ods_t_ct_guar_person
				where data_type = '7' -- 出具批复最终定的担保人
	)t
	where rn = 1
)t7
on t1.project_Id = t7.project_Id
and t2.counter_name = t7.ct_guar_person_name
and t2.duty_type='2'
left join dw_tmp.tmp_exp_credit_comp_compt_info_xz_counter_contract_xx t8
on t1.project_Id = t8.project_Id
and t2.id_no = t8.ct_guar_person_id_no
and t8.count_cont_code is not null
and t2.duty_type='2'
left join dw_tmp.tmp_exp_credit_comp_compt_info_check t9
on t1.project_id = t9.project_id
-- left join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract t10
-- on t2.apply_code = t10.biz_id
-- and t2.id_no = t10.AUTHORIZED_CUSTOMER_ID  -- 证件号
-- and t2.duty_type='2'
-- left join dw_tmp.tmp_exp_credit_per_guar_info_xz_counter_contract t11
-- on t2.apply_code = t11.biz_id
-- and t2.cust_code = t11.AUTHORIZED_CUSTOMER_ID  -- 证件号
-- and t2.duty_type='2'
where t.day_id = '${v_sdate}'
)t
left join dw_tmp.tmp_exp_credit_comp_compt_info_risk_comp t1  -- 20231023优化，核心企业的集群方案与担保业务一致时，作为反担保人时，责任金额用合同金额*分险比例，反担保合同用协议合同+业务编号
on t.ct_guar_person_id_no = t1.unified_social_credit_code
and t.aggregate_scheme = t1.dictionaries_code
left join dw_tmp.tmp_exp_credit_comp_compt_info_risk_natural t2
on t.duty_cert_no = t2.person_identity
and t.aggregate_scheme = t2.dictionaries_code
where t.duty_cert_no is not null
)t
where t.guar_cont_no is not null  -- 反担保合同编号不为空

;

commit;



-- drop table dw_pbc.exp_credit_comp_compt_repay_duty_info;commit;
-- create  table dw_pbc.exp_credit_comp_compt_repay_duty_info (
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
--  guar_cont_no varchar(60)  comment '保证合同编号'
--  ) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC
-- ;
--  commit;

-- 同步集市
delete from dw_pbc.exp_credit_comp_compt_info where day_id = '${v_sdate}';
commit;
insert into dw_pbc.exp_credit_comp_compt_info
select day_id,
	   ln_id,
	   cust_id,
	   acct_type,
	   acct_code,
	   rpt_date,
	   rpt_date_code,
	   name,
	   id_type,
	   id_num,
	   mngmt_org_code,
	   busi_lines,
	   busi_dtl_lines,
	   open_date,
	   cy,
	   acct_cred_line,
	   loan_amt,
	   flag,
	   due_date,
	   repay_mode,
	   repay_freqcy,
	   apply_busi_dist,
	   guar_mode,
	   oth_repy_guar_way,
	   loan_time_lim_cat,
	   loan_form,
	   act_invest,
	   fund_sou,
	   asset_trand_flag,
	   init_cred_name,
	   init_cred_org_nm,
	   orig_dbt_cate,
	   init_rpy_sts,
	   acct_status,
	   acct_bal,
	   repay_prd,
	   five_cate,
	   five_cate_adj_date,
	   rem_rep_prd,
	   tot_overd,
	   overd_princ,
	   overd_dy,
	   lat_rpy_date,
	   lat_rpy_amt,
	   lat_rpy_princ_amt,
	   rpmt_type,
	   lat_agrr_rpy_date,
	   lat_agrr_rpy_amt,
	   nxt_agrr_rpy_date,
	   close_date
from dw_base.exp_credit_comp_compt_info
where day_id = '${v_sdate}' 
;
commit;
 -- 还款责任人信息
delete from dw_pbc.exp_credit_comp_compt_repay_duty_info  where day_id = '${v_sdate}' ;
commit;
insert into dw_pbc.exp_credit_comp_compt_repay_duty_info
select day_id
	   ,guar_id
	   ,cust_id
	   ,info_id_type
	   ,duty_name
	   ,duty_cert_type
	   ,duty_cert_no
	   ,duty_type
	   ,duty_amt
	   ,guar_cont_no
from  dw_base.exp_credit_comp_compt_repay_duty_info
where day_id = '${v_sdate}'
;
commit;

-- delete
-- from dw_pbc.exp_credit_comp_compt_info
-- where day_id = '${v_sdate}'
--  and ln_id in ('TJRD-2021-5Z85-959X', 'TJRD-2021-5S93-979U');
-- commit;
