-- 20251023 添加：账户类型不能为空，可以排掉增量更新的数据
-- 20251023 【在还款表现段增加报告时点说明代码字段】
-- t_en_acct_bs_sgmt	企业借贷-基础段

delete from creditda.t_en_acct_bs_sgmt where day_id = '${v_sdate}';

commit ;

insert into creditda.t_en_acct_bs_sgmt
select
concat(day_id,acct_code)               -- ID
,day_id
,ln_Id
,cust_Id
,'410'           -- 信息记录类型
,acct_type       -- 账户类型
,acct_code       -- 账户标识码
,rpt_date        -- 信息报告日期
,rpt_date_code   -- 报告时点说明代码
,name            -- 借款人名称
,id_type         -- 借款人身份标识类型
,id_num          -- 借款人身份标识号码
,mngmt_org_code  -- 业务管理机构代码
,now()     -- 创建时间
from creditda.exp_credit_comp_compt_info t1
where t1.day_id = '${v_sdate}'
and acct_type is not null	 -- [账户类型不能为空，可以排掉增量更新的数据]            20251023
;

commit ;


-- t_en_acct_bs_inf_sgmt	企业借贷-账户基本信息段
delete from creditda.t_en_acct_bs_inf_sgmt where day_id = '${v_sdate}';
commit ;

insert into creditda.t_en_acct_bs_inf_sgmt
select
concat(day_id,acct_code)
,day_id
,ln_id
,cust_id
,busi_lines          -- 借贷业务大类
,busi_dtl_lines      -- 借贷业务种类细分
,open_date           -- 开户日期
,cy                  -- 币种
,acct_cred_line      -- 信用额度
,loan_amt            -- 借款金额
,flag                -- 分次放款标志
,due_date            -- 到期日期
,repay_mode          -- 还款方式
,repay_freqcy        -- 还款频率
,apply_busi_dist     -- 业务申请地行政区划代码
,guar_mode           -- 担保方式
,oth_repy_guar_way   -- 其他还款保证方式
,loan_time_lim_cat   -- 借款期限分类
,loan_form             -- 贷款发放形式
,act_invest          -- 贷款实际投向
,fund_sou            -- 业务经营类型
,asset_trand_flag    -- 资产转让标识
,now()         -- 创建时间
from creditda.exp_credit_comp_compt_info t1
where t1.day_id = '${v_sdate}'
and acct_type is not null	 -- [账户类型不能为空，可以排掉增量更新的数据]            20251023
;
commit ;

-- t_en_acct_rlt_repymt_inf_sgm	企业借贷-相关还款责任人段 无 
-- t_en_acct_rlt_repymt_inf_sgm_el	企业借贷-相关还款责任人信息 无



 
-- 相关还款责任人段
delete from creditda.t_en_acct_rlt_repymt_inf_sgm  where day_id = '${v_sdate}';
commit ;
insert into creditda.t_en_acct_rlt_repymt_inf_sgm
select
	concat(t1.DAY_ID,t1.acct_code)
	,t1.DAY_ID
	,t1.ln_id
	,t1.cust_id
	,coalesce(t2.duty_qty,0) -- 责任人个数 
	,now() -- 创建时间
from creditda.exp_credit_comp_compt_info t1
left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from creditda.exp_credit_comp_compt_repay_duty_info 
where DAY_ID = '${v_sdate}'
group by guar_id
)t2
 on t1.ln_id = t2.guar_id
where t1.DAY_ID = '${v_sdate}'
-- and t1.rpt_date_code = '10' -- 只有新开户或者首次上报时上报该段【取消限制】
and t1.acct_type is not null	 -- [账户类型不能为空，可以排掉增量更新的数据]            20251023
;
commit;


 -- 相关还款责任人信息 
delete from creditda.t_en_acct_rlt_repymt_inf_sgm_el  where day_id = '${v_sdate}' ;
commit;
 
insert into creditda.t_en_acct_rlt_repymt_inf_sgm_el
select
   null  ID
  ,t1.day_id -- 数据日期,
  ,t1.guar_id -- 担保业务编号,
  ,t1.cust_id -- 客户号,
  ,concat(t1.day_id,t2.acct_code) -- 相关还款责任人段ID,
  ,t1.info_id_type -- 身份类别,
  ,t1.duty_name -- 责任人名称,
  ,t1.duty_cert_type -- 责任人身份标识类型,
  ,t1.duty_cert_no -- 责任人身份标识号码,
  ,t1.duty_type -- 还款责任人类型：1-共同债务人2-反担保人9-其他,
  ,t1.duty_amt -- 还款责任金额,
  ,case when coalesce(t3.duty_qty,0) >= 2 then '1' else '0' end as duty_flag -- 联保标志  0-单人保证/多人分保   1-联保（单人保证指该账户对应的担保交易仅有一个反担保人，多人分保指该账户对应的担保交易有多个反担保人，且每个反担保人独立分担一部分担保责任）1-联保（联保指该账户对应的担保交易有多个反担保人且共同承担担保责任）,
  -- ,concat('X3701010000337',t1.guar_cont_no) -- 保证合同编号,
  ,t1.guar_cont_no -- 保证合同编号,
  ,now() -- 创建时间,
from creditda.exp_credit_comp_compt_repay_duty_info t1
inner join creditda.exp_credit_comp_compt_info  t2 
on t1.guar_id = t2.ln_id
and t2.day_id = '${v_sdate}'
-- and t2.rpt_date_code = '10' -- 只有新开户或者首次上报时上报该段【取消限制】
left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from creditda.exp_credit_comp_compt_repay_duty_info 
where DAY_ID = '${v_sdate}'
group by guar_id
)t3
on t1.guar_id = t3.guar_id
where t1.day_id = '${v_sdate}'
and t1.guar_cont_no is not null 
and t2.acct_type is not null	 -- [账户类型不能为空，可以排掉增量更新的数据]            20251023

;
 
commit;


-- t_en_acct_motga_cltal_ctrct_inf_sgmt	企业借贷-抵质押物信息段 无
-- t_en_acct_motga_cltal_ctrct_inf_sgmt_el	企业借贷-抵（质）押合同信息 无

-- t_en_acct_cred_sgmt	企业借贷-授信额度信息段

-- t_en_acct_orig_creditor_inf_sgmt	企业借贷-初始债权说明段

delete from creditda.t_en_acct_orig_creditor_inf_sgmt where day_id = '${v_sdate}';
commit ;

insert into creditda.t_en_acct_orig_creditor_inf_sgmt
select
concat(day_id,acct_code)
,day_id
,ln_id
,cust_id
,init_cred_name     -- 初始债权人名称 
,init_cred_org_nm  -- 初始债权人机构代码 
,orig_dbt_cate      -- 原债务种类
,init_rpy_sts       -- 债权转移时的还款状态
,now()        -- 创建时间
from creditda.exp_credit_comp_compt_info t1
where t1.day_id = '${v_sdate}'
and t1.rpt_date_code= '10' -- 只有新开户或者首次上报时上报该段
and acct_type is not null	 -- [账户类型不能为空，可以排掉增量更新的数据]            20251023
;
commit ;

 
-- t_en_act_lblty_inf_sgmt	企业借贷-还款表现信息段
delete from creditda.t_en_act_lblty_inf_sgmt where day_id = '${v_sdate}';
commit ;

insert into creditda.t_en_act_lblty_inf_sgmt
select
concat(day_id,acct_code)
,day_id
,ln_id
,cust_id
,acct_status            -- 账户状态
,acct_bal               -- 余额
,repay_prd           -- 余额变化日期
,five_cate              -- 五级分类
,five_cate_adj_date     -- 五级分类认定日期
,rem_rep_prd               -- 剩余还款月数
,tot_overd              -- 当前逾期总额
,overd_princ            -- 当前逾期本金
,overd_dy               -- 当前逾期天数
,lat_rpy_date           -- 最近一次实际还款日期
,lat_rpy_amt            -- 最近一次实际还款金额
,lat_rpy_princ_amt      -- 最近一次实际归还本金
,rpmt_type              -- 还款形式
,lat_agrr_rpy_date      -- 最近一次约定还款日
,lat_agrr_rpy_amt       -- 最近一次约定还款金额
,nxt_agrr_rpy_date      -- 下一次约定还款日期
,close_date             -- 账户关闭日期
,now()            -- 创建时间
,rpt_date_code          -- 报告时点说明代码                    20251023 【在还款表现段增加报告时点说明代码字段】
from creditda.exp_credit_comp_compt_info t1
where t1.day_id = '${v_sdate}'
;commit ;

-- t_en_acct_spec_trst_dspn_sgmt	企业借贷-特殊交易说明段
-- t_en_acct_spec_trst_dspn_sgmt_el	企业借贷-特殊交易说明段交易信息


-- t_rd_en_acct_inf	企业借贷账户记录
delete from creditda.t_rd_en_acct_inf where day_id = '${v_sdate}';
commit;

insert into creditda.t_rd_en_acct_inf
select
null
,day_id
,ln_id
,cust_id
,day_id                              -- 信息报告日期
,concat(day_id,acct_code)                       -- 基础段ID
,concat(day_id,acct_code)                   -- 基本信息段ID
,concat(day_id,acct_code)                -- 相关还款责任人信息段ID
,concat(day_id,acct_code)         -- 抵质押物信息段ID
,concat(day_id,acct_code)                     -- 授信额度信息段ID
,concat(day_id,acct_code)             -- 初始债权说明段ID
,concat(day_id,acct_code)                 -- 还款表现信息段ID
,concat(day_id,acct_code)           -- 特殊交易说明段ID
,0                                -- 状态 
,now()                           -- 创建时间
,now()                           -- 更新时间
,null                        -- 更新人ID
,null                               -- 上报文件ID
,null                              -- 上报文件行号
from creditda.exp_credit_comp_compt_info t1
where t1.day_id = '${v_sdate}'
and acct_type is not null	 -- [账户类型不能为空，可以排掉增量更新的数据]            20251023
;
commit;










-- -- t_en_acct_mdfc_bs_sgmt	企业借贷更新-基础段

-- delete from creditda.t_en_acct_mdfc_bs_sgmt where day_id = '${v_sdate}';
-- insert into creditda.t_en_acct_mdfc_bs_sgmt
-- select
-- concat(day_id,acct_code) 
-- ,day_id
-- ,ln_id
-- ,cust_id
-- ,'412'     -- 信息记录类型
-- ,acct_code     -- 待更正业务标识码
-- ,day_id         -- 信息报告日期
-- ,acct_type        -- 账户类型
-- ,'C'   -- 待更正段段标
-- ,now()      -- 创建时间
-- from creditda.exp_credit_comp_compt_info t1
-- where t1.day_id = '${v_sdate}'
-- AND ln_id ='999901914' 
-- ;
-- commit;
-- insert into creditda.t_en_acct_mdfc_bs_sgmt
-- select
-- concat(day_id,acct_code) 
-- ,day_id
-- ,ln_id
-- ,cust_id
-- ,'412'     -- 信息记录类型
-- ,acct_code     -- 待更正业务标识码
-- ,day_id         -- 信息报告日期
-- ,acct_type        -- 账户类型
-- ,'H'   -- 待更正段段标
-- ,now()      -- 创建时间
-- from creditda.exp_credit_comp_compt_info t1
-- where t1.day_id = '${v_sdate}'
-- AND CUST_ID ='202008201730157731361062497' 
-- ;
-- commit;

-- t_rd_en_acct_inf_mdfc	企业借贷账户更正请求类记录
-- delete from creditda.t_rd_en_acct_inf_mdfc where day_id = '${v_sdate}';
-- insert into creditda.t_rd_en_acct_inf_mdfc
-- SELECT
-- null
-- ,day_id
-- ,ln_id
-- ,cust_id
-- ,day_id         -- 信息报告日期
-- ,concat(day_id,acct_code)       -- 基础段ID
-- ,'C'   -- 待更正段标
-- ,concat(day_id,acct_code)     -- 待更正段ID
-- ,0           -- 状态
-- ,NOW()   -- 创建时间
-- ,NOW()      -- 更新时间
-- ,null   -- 更新人ID
-- ,null          -- 上报文件ID
-- ,null         -- 文件行号
-- FROM  creditda.exp_credit_comp_compt_info t1
-- where t1.day_id = '${v_sdate}'
-- AND ln_id ='999901914' 
-- ;
-- commit;


-- insert into creditda.t_rd_en_acct_inf_mdfc
-- SELECT
-- null
-- ,day_id
-- ,ln_id
-- ,cust_id
-- ,day_id         -- 信息报告日期
-- ,concat(day_id,acct_code)       -- 基础段ID
-- ,'H'   -- 待更正段标
-- ,concat(day_id,acct_code)     -- 待更正段ID
-- ,0           -- 状态
-- ,NOW()   -- 创建时间
-- ,NOW()      -- 更新时间
-- ,null   -- 更新人ID
-- ,null          -- 上报文件ID
-- ,null         -- 文件行号
-- FROM  creditda.exp_credit_comp_compt_info t1
-- where t1.day_id = '${v_sdate}'
-- AND CUST_ID ='202008201730157731361062497' 
-- ;
-- commit;

-- t_rd_en_acct_inf_id_cags_inf	企业借贷账户标识变更请求记录

-- t_rd_en_acct_inf_del	    企业借贷账户按段删除请求类记录

-- delete from creditda.t_rd_en_acct_inf_del where day_id = '${v_sdate}';
-- insert into creditda.t_rd_en_acct_inf_del
-- SELECT
-- null
-- ,day_id
-- ,ln_id
-- ,cust_id
-- ,day_id            -- 信息报告日期
-- ,'413'             -- 信息记录类型
-- ,acct_code      -- 待删除业务标识码
-- ,'C'           -- 待删除段段标C-基本信息段 H-还款表现信息段 I-特定交易说明段
-- ,''    -- 待删除起始日期
-- ,DATE_FORMAT(day_id,'%Y-%m-%d')      -- 待删除结束日期
-- ,0              -- 状态
-- ,now()          -- 创建时间
-- ,now()          -- 更新时间
-- ,null           -- 更新人ID
-- ,null           -- 上报文件ID
-- ,null           -- 文件行号
-- FROM  creditda.exp_credit_comp_compt_info t1
-- where t1.day_id = '${v_sdate}'
-- AND ln_id ='20201229-023' 
-- ;
-- commit;
-- 
-- insert into creditda.t_rd_en_acct_inf_del
-- SELECT
-- null
-- ,day_id
-- ,ln_id
-- ,cust_id
-- ,day_id            -- 信息报告日期
-- ,'413'             -- 信息记录类型
-- ,acct_code      -- 待删除业务标识码
-- ,'H'           -- 待删除段段标C-基本信息段 H-还款表现信息段 I-特定交易说明段
-- ,''    -- 待删除起始日期
-- ,DATE_FORMAT(day_id,'%Y-%m-%d')      -- 待删除结束日期
-- ,0              -- 状态
-- ,now()          -- 创建时间
-- ,now()          -- 更新时间
-- ,null           -- 更新人ID
-- ,null           -- 上报文件ID
-- ,null           -- 文件行号
-- FROM  creditda.exp_credit_comp_compt_info t1
-- where t1.day_id = '${v_sdate}'
-- AND ln_id ='20201229-023' 
-- ;
-- commit;
-- 
-- -- t_rd_en_acct_inf_ent_del	企业借贷账户整笔删除请求类记录
-- 
-- delete from creditda.t_rd_en_acct_inf_ent_del where day_id = '${v_sdate}';
-- insert into creditda.t_rd_en_acct_inf_ent_del
-- SELECT
-- null
-- ,day_id
-- ,ln_id
-- ,cust_id
-- ,day_id            -- 信息报告日期
-- ,'414'             -- 信息记录类型
-- ,acct_code      -- 待删除业务标识码
-- ,0            -- 状态
-- ,now()       -- 创建时间
-- ,now()       -- 更新时间
-- ,null    -- 更新人ID
-- ,null           -- 上报文件ID
-- ,null          -- 文件行号
-- FROM  creditda.exp_credit_comp_compt_info t1
-- where t1.day_id = '${v_sdate}'
-- AND ln_id ='20201229-023' 
-- ;
-- commit;
-- 
