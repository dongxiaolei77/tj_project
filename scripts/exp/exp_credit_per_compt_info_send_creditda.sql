-- 个人借贷-基本信息段
--
--
-- 


delete from creditda.t_in_acct_bs_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into creditda.t_in_acct_bs_inf_sgmt
select
concat(DAY_ID,acct_code)  -- ID
,DAY_ID
,ln_Id
,cust_Id
,busi_lines -- 借贷业务大类：1-贷款；2-信用卡；3-证券类融资；4-融资租赁；5-资产处置；6-垫款
,busi_dtl_lines -- 借贷业务种类细分
,open_date -- 开户日期
,cy -- 币种
,acct_cred_line -- 信用额度
,loan_amt -- 借款金额
,flag -- 分次放款标志
,due_date -- 到期日期
,repay_mode -- 还款方式：
,repay_freqcy -- 还款频率
,repay_prd -- 还款期数
,apply_busi_dist -- 业务申请地行政区划代码
,guar_mode -- 担保方式
,oth_repy_guar_way -- 其他还款保证方式：
,asset_trand_flag -- 资产转让标志
,fund_sou -- 业务经营类型
,loan_form -- 贷款发放形式
,credit_id -- 卡片标识号
,loan_con_code -- 贷款合同编号
,first_hou_loan_flag -- 是否为首套住房贷款
,now() -- 创建时间
from creditda.exp_credit_per_compt_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;


-- 增加更新段详细信息 C-基本信息段 
insert into creditda.t_in_acct_bs_inf_sgmt
select
concat(DAY_ID,acct_code)  -- ID
,DAY_ID
,guar_Id
,cust_Id
,busi_lines -- 借贷业务大类：1-贷款；2-信用卡；3-证券类融资；4-融资租赁；5-资产处置；6-垫款
,busi_dtl_lines -- 借贷业务种类细分
,open_date -- 开户日期
,cy -- 币种
,acct_cred_line -- 信用额度
,loan_amt -- 借款金额
,flag -- 分次放款标志
,due_date -- 到期日期
,repay_mode -- 还款方式：
,repay_freqcy -- 还款频率
,repay_prd -- 还款期数
,apply_busi_dist -- 业务申请地行政区划代码
,guar_mode -- 担保方式
,oth_repy_guar_way -- 其他还款保证方式：
,asset_trand_flag -- 资产转让标志
,fund_sou -- 业务经营类型
,loan_form -- 贷款发放形式
,credit_id -- 卡片标识号
,loan_con_code -- 贷款合同编号
,first_hou_loan_flag -- 是否为首套住房贷款
,now() -- 创建时间
from creditda.exp_credit_per_compt_info_change_c t1
where t1.DAY_ID = '${v_sdate}'
;
commit ;


-- 更正段信息
delete from creditda.t_in_acct_mdfc_bs_sgmt where day_id = '${v_sdate}' and mdfc_sgmt_code ='C';
commit ;
insert into creditda.t_in_acct_mdfc_bs_sgmt
select
concat('${v_sdate}',acct_code)
,'${v_sdate}'
,cust_id
,guar_id
,'212'    -- 信息记录类型
,acct_code    -- 待更正业务标识码
,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')         -- 信息报告日期
,'C1'       -- 账户类型
,'C'  -- 待更正段段标
,now()     -- 创建时间
from creditda.exp_credit_per_compt_info_change_c t1
where t1.DAY_ID = '${v_sdate}' 
;
commit ;

-- 更正报文
delete from creditda.t_rd_in_acct_mdfc where day_id = '${v_sdate}' and mdfc_sgmt_code ='C';
 
 commit ;
 
 insert into creditda.t_rd_in_acct_mdfc
 select
 null
 ,'${v_sdate}'
 ,cust_id
 ,guar_id
 ,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')         -- 信息报告日期
 ,concat('${v_sdate}',acct_code)       -- 基础段ID
 ,'C'   -- 待更正段类型 C-基本信息段；D-相关还款责任人段；G-初始债权说明段；J-非月度表现信息段；K-特殊交易说明段
 ,concat('${v_sdate}',acct_code)     -- 待更正段ID
 ,'0'           -- 状态
 ,now()      -- 创建时间
 ,now()      -- 更新时间
 ,null          -- 更新人ID
 ,null          -- 上报文件ID
 ,null          -- 文件行号
 from creditda.exp_credit_per_compt_info_change_c t1
 where t1.DAY_ID = '${v_sdate}' 
 ;
 
 commit ;

-- 个人借贷-基础段
delete from creditda.t_in_acct_bs_sgmt where day_id = '${v_sdate}';

commit ;

insert into creditda.t_in_acct_bs_sgmt
select
concat(DAY_ID,acct_code)
,'${v_sdate}'
,ln_Id
,cust_Id
,'210' -- 信息记录类型
,acct_type -- 账户类型
,acct_code -- 账户标识码
,rpt_date -- 信息报告日期
,rpt_date_code -- 报告时点说明代码
,name -- 债务人姓名
,id_type -- 债务人证件类型
,id_num -- 债务人证件号码
,mngmt_org_code -- 业务管理机构代码
,now() -- 创建时间
from creditda.`exp_credit_per_compt_info` t1
where t1.DAY_ID = '${v_sdate}'
;
commit ;

-- 增加更新段详细信息 B-基础段

delete from creditda.tmp_t_in_acct_bs_sgmt ;

commit;

-- 获取最晚信息报告日期
insert into creditda.tmp_t_in_acct_bs_sgmt
select
t1.guar_id
,max(t1.rpt_date)  -- 信息报告日期
from creditda.t_in_acct_bs_sgmt t1
inner join creditda.exp_credit_per_compt_info_change_b t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id < '${v_sdate}'
group by t1.guar_id
;
commit;


-- 更正信息
insert into creditda.t_in_acct_bs_sgmt
select
concat(DAY_ID,acct_code)
,'${v_sdate}'
,guar_id
,cust_Id
,null -- 信息记录类型
,null -- 账户类型
,null -- 账户标识码
,null -- 信息报告日期
,null -- 报告时点说明代码
,name -- 债务人姓名
,id_type -- 债务人证件类型
,id_num -- 债务人证件号码
,mngmt_org_code -- 业务管理机构代码
,now() -- 创建时间
from creditda.exp_credit_per_compt_info_change_b t1
where t1.DAY_ID = '${v_sdate}'
;
commit ;

-- 更正段信息
delete from creditda.t_in_acct_mdfc_bs_sgmt where day_id = '${v_sdate}' and mdfc_sgmt_code ='B';
commit ;
insert into creditda.t_in_acct_mdfc_bs_sgmt
select
concat('${v_sdate}',acct_code)
,'${v_sdate}'
,t1.cust_id
,t1.guar_id
,'212'    -- 信息记录类型
,t1.acct_code    -- 待更正业务标识码
,t2.rpt_date         -- 信息报告日期
,'C1'       -- 账户类型
,'B'  -- 待更正段段标
,now()     -- 创建时间
from creditda.exp_credit_per_compt_info_change_b t1
inner join creditda.tmp_t_in_acct_bs_sgmt t2
         on t1.guar_id = t2.guar_id
where t1.DAY_ID = '${v_sdate}' 
;
commit ;

-- 更正报文
delete from creditda.t_rd_in_acct_mdfc where day_id = '${v_sdate}' and mdfc_sgmt_code ='B';
 
 commit ;
 
 insert into creditda.t_rd_in_acct_mdfc
 select
 null
 ,'${v_sdate}'
 ,t1.cust_id
 ,t1.guar_id
 ,t2.rpt_date         -- 信息报告日期
 ,concat('${v_sdate}',t1.acct_code)       -- 基础段ID
 ,'B'   -- 待更正段类型 C-基本信息段；D-相关还款责任人段；G-初始债权说明段；J-非月度表现信息段；K-特殊交易说明段
 ,concat('${v_sdate}',t1.acct_code)     -- 待更正段ID
 ,'0'           -- 状态
 ,now()      -- 创建时间
 ,now()      -- 更新时间
 ,null          -- 更新人ID
 ,null          -- 上报文件ID
 ,null          -- 文件行号
 from creditda.exp_credit_per_compt_info_change_b t1
 inner join creditda.tmp_t_in_acct_bs_sgmt t2
         on t1.guar_id = t2.guar_id
 where t1.DAY_ID = '${v_sdate}' 
 ;
 
 commit ;



-- 个人借贷-非月度表现信息段
delete from creditda.t_in_acct_dbt_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into creditda.t_in_acct_dbt_inf_sgmt
select
concat(DAY_ID,acct_code)  -- ID
,DAY_ID
,ln_Id
,cust_Id
,acct_status -- 账户状态
,acct_bal -- 余额
,five_cate -- 五级分类
,five_cate_adj_date -- 五级分类认定日期
,rem_rep_prd -- 剩余还款期数
,rpy_status -- 当前还款状态
,overd_prd -- 当前逾期期数
,tot_overd -- 当前逾期总额
,lat_rpy_amt -- 最近一次实际还款金额
,lat_rpy_date -- 最近一次实际还款日期
,close_date -- 账户关闭日期
,now() -- 创建时间
from creditda.exp_credit_per_compt_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;
 
-- 按段更新 J-非月度表现信息段
insert into creditda.t_in_acct_dbt_inf_sgmt
select
concat(DAY_ID,acct_code)  -- ID
,DAY_ID
,guar_id
,cust_Id
,acct_status -- 账户状态
,acct_bal -- 余额
,five_cate -- 五级分类
,five_cate_adj_date -- 五级分类认定日期
,rem_rep_prd -- 剩余还款期数
,rpy_status -- 当前还款状态
,overd_prd -- 当前逾期期数
,tot_overd -- 当前逾期总额
,lat_rpy_amt -- 最近一次实际还款金额
,lat_rpy_date -- 最近一次实际还款日期
,close_date -- 账户关闭日期
,now() -- 创建时间
from creditda.exp_credit_per_compt_info_change_j t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;


-- 更正段信息
delete from creditda.t_in_acct_mdfc_bs_sgmt where day_id = '${v_sdate}' and mdfc_sgmt_code ='J';
commit ;
insert into creditda.t_in_acct_mdfc_bs_sgmt
select
concat('${v_sdate}',acct_code)
,'${v_sdate}'
,t1.cust_id
,t1.guar_id
,'212'    -- 信息记录类型
,t1.acct_code    -- 待更正业务标识码
,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')         -- 信息报告日期
,'C1'       -- 账户类型
,'J'  -- 待更正段段标
,now()     -- 创建时间
from creditda.exp_credit_per_compt_info_change_j t1
where t1.DAY_ID = '${v_sdate}' 
;
commit ;

-- 更正报文
delete from creditda.t_rd_in_acct_mdfc where day_id = '${v_sdate}' and mdfc_sgmt_code ='J';
 
 commit ;
 
 insert into creditda.t_rd_in_acct_mdfc
 select
 null
 ,'${v_sdate}'
 ,t1.cust_id
 ,t1.guar_id
 ,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')         -- 信息报告日期
 ,concat('${v_sdate}',t1.acct_code)       -- 基础段ID
 ,'J'   -- 待更正段类型 C-基本信息段；D-相关还款责任人段；G-初始债权说明段；J-非月度表现信息段；K-特殊交易说明段
 ,concat('${v_sdate}',t1.acct_code)     -- 待更正段ID
 ,'0'           -- 状态
 ,now()      -- 创建时间
 ,now()      -- 更新时间
 ,null          -- 更新人ID
 ,null          -- 上报文件ID
 ,null          -- 文件行号
 from creditda.exp_credit_per_compt_info_change_j t1
 where t1.DAY_ID = '${v_sdate}' 
 ;
 
 commit ;
 

-- 个人借贷-初始债权说明段
delete from creditda.t_in_acct_orig_creditor_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into creditda.t_in_acct_orig_creditor_inf_sgmt
select
concat(DAY_ID,acct_code)  -- ID
,DAY_ID
,ln_Id
,cust_Id
,init_cred_name -- 初始债权人名称 
,init_cred_org_nm -- 初始债权人机构代码 
,orig_dbt_cate -- 原债务种类
,init_rpy_sts -- 债权转移时的还款状态
,now() -- 创建时间
from creditda.exp_credit_per_compt_info t1
where t1.DAY_ID = '${v_sdate}'
and rpt_date_code  in ('10')
;

commit ;


-- 按段更新 G-初始债权说明段
insert into creditda.t_in_acct_orig_creditor_inf_sgmt
select
concat(DAY_ID,acct_code)  -- ID
,DAY_ID
,guar_Id
,cust_Id
,init_cred_name -- 初始债权人名称 
,init_cred_org_nm -- 初始债权人机构代码 
,orig_dbt_cate -- 原债务种类
,init_rpy_sts -- 债权转移时的还款状态
,now() -- 创建时间
from creditda.exp_credit_per_compt_info_change_g t1
where t1.DAY_ID = '${v_sdate}'
;
commit ;


-- 更正段信息
delete from creditda.t_in_acct_mdfc_bs_sgmt where day_id = '${v_sdate}' and mdfc_sgmt_code ='G';
commit ;
insert into creditda.t_in_acct_mdfc_bs_sgmt
select
concat('${v_sdate}',acct_code)
,'${v_sdate}'
,t1.cust_id
,t1.guar_id
,'212'    -- 信息记录类型
,t1.acct_code    -- 待更正业务标识码
,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')         -- 信息报告日期
,'C1'       -- 账户类型
,'G'  -- 待更正段段标
,now()     -- 创建时间
from creditda.exp_credit_per_compt_info_change_g t1
where t1.DAY_ID = '${v_sdate}' 
;
commit ;

-- 更正报文
delete from creditda.t_rd_in_acct_mdfc where day_id = '${v_sdate}' and mdfc_sgmt_code ='G';
 
 commit ;
 
 insert into creditda.t_rd_in_acct_mdfc
 select
 null
 ,'${v_sdate}'
 ,t1.cust_id
 ,t1.guar_id
 ,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')         -- 信息报告日期
 ,concat('${v_sdate}',t1.acct_code)       -- 基础段ID
 ,'G'   -- 待更正段类型 C-基本信息段；D-相关还款责任人段；G-初始债权说明段；J-非月度表现信息段；K-特殊交易说明段
 ,concat('${v_sdate}',t1.acct_code)     -- 待更正段ID
 ,'0'           -- 状态
 ,now()      -- 创建时间
 ,now()      -- 更新时间
 ,null          -- 更新人ID
 ,null          -- 上报文件ID
 ,null          -- 文件行号
 from creditda.exp_credit_per_compt_info_change_g t1
 where t1.DAY_ID = '${v_sdate}' 
 ;
 
 commit ;
 
     
--  t_in_acct_rlt_repymt_inf_sgm	个人借贷-相关还款责任人段 
delete from creditda.t_in_acct_rlt_repymt_inf_sgm where day_id = '${v_sdate}';
commit ;

insert into creditda.t_in_acct_rlt_repymt_inf_sgm
 select
 concat(t1.DAY_ID,t1.acct_code)
 ,t1.DAY_ID
 ,t1.ln_id
 ,t1.cust_id
 ,coalesce(t2.duty_qty,0) -- 责任人个数 
 ,now()
 from creditda.exp_credit_per_compt_info t1
 left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from creditda.exp_credit_per_compt_duty_info 
where DAY_ID = '${v_sdate}'
group by guar_id
)t2
 on t1.ln_id = t2.guar_id
 where t1.DAY_ID = '${v_sdate}'
  ;
 commit;
 
-- t_in_acct_rlt_repymt_inf_sgm_el 个人借贷相关还款责任人信息
delete from creditda.t_in_acct_rlt_repymt_inf_sgm_el where day_id = '${v_sdate}';
commit ;

 insert into creditda.t_in_acct_rlt_repymt_inf_sgm_el
 select
    null ID
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
    ,case when coalesce(t3.duty_qty,0) >= 2 then '1' else '0' end as duty_flag  -- 联保标志  0-单人保证/多人分保   1-联保（单人保证指该账户对应的担保交易仅有一个反担保人，多人分保指该账户对应的担保交易有多个反担保人，且每个反担保人独立分担一部分担保责任）1-联保（联保指该账户对应的担保交易有多个反担保人且共同承担担保责任）,
    -- ,concat('X3701010000337',t1.guar_cont_no) -- 保证合同编号,
	,t1.guar_cont_no -- 保证合同编号,
    ,now() -- 创建时间,
  from creditda.exp_credit_per_compt_duty_info t1
  inner join creditda.exp_credit_per_compt_info t2
     on t1.guar_id = t2.ln_id
    and t2.day_id = '${v_sdate}'
 left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from creditda.exp_credit_per_compt_duty_info 
where DAY_ID = '${v_sdate}'
group by guar_id
)t3
 on t1.guar_id = t3.guar_id
  where t1.day_id = '${v_sdate}'
  ;
  commit ;

-- t_in_acct_cred_sgmt	个人借贷-授信额度信息段 无需上报


	
delete from creditda.t_rd_in_acct_inf where day_id = '${v_sdate}';

commit ;

insert into creditda.t_rd_in_acct_inf
select
null	 --	ID
,t1.DAY_ID	 
,t1.ln_Id
,t1.cust_id
,t1.DAY_ID --	信息报告日期
,concat(t1.DAY_ID,t1.acct_code)	 --	基础段ID
,concat(t1.DAY_ID,t1.acct_code)	 --	基本信息段ID
,concat(t1.DAY_ID,t1.acct_code)	 --	相关还款责任人信息段ID
,concat(t1.DAY_ID,t1.acct_code)	 --	抵质押物信息段ID
,concat(t1.DAY_ID,t1.acct_code)	 --	授信额度信息段ID
,case when t3.guar_id is not null then concat(t1.DAY_ID,t1.acct_code)	else t2.orig_creditor_inf_sgmt_id end  --	初始债权说明段ID
,concat(t1.DAY_ID,t1.acct_code)	 --	月度表现信息段ID
,concat(t1.DAY_ID,t1.acct_code)	 --	大额专项分期信息段ID
,concat(t1.DAY_ID,t1.acct_code)	 --	非月度表现信息段ID
,concat(t1.DAY_ID,t1.acct_code)	 --	特殊交易说明段ID
,0	 --	状态：0-未处理；1-审核通过；2-审核未通过；3-已上报；4-上报成功；5-上报失败；6-失败已处理
,now()	 --	创建时间
,now()	 --	更新时间
,null	 --	更新人ID
,null	 --	上报文件ID
,null	 --	上报文件行号
from creditda.exp_credit_per_compt_info t1
left join (
	select guar_id,orig_creditor_inf_sgmt_id 
	from (
		select guar_id,orig_creditor_inf_sgmt_id 
		from creditda.t_rd_in_acct_inf 
		where DAY_ID < '${v_sdate}'
		order by day_id
	)t
	group by guar_id
)t2
on t1.ln_Id = t2.guar_id
left join creditda.t_in_acct_orig_creditor_inf_sgmt t3
on t1.ln_Id = t3.guar_id
and t3.DAY_ID = '${v_sdate}'
where t1.DAY_ID = '${v_sdate}'
;

commit ;



-- -- 个人借贷账户标识变更请求记录
-- delete from creditda.t_rd_in_acct_id_cags_inf where day_id = '${v_sdate}';
-- commit ;
-- insert into creditda.t_rd_in_acct_id_cags_inf
-- select
-- null                -- ID
-- day_id            -- 
-- rpt_date          -- 信息报告日期
-- ln_id             -- 
-- cust_id           -- 
-- inf_rec_type      -- 信息记录类型
-- od_bnes_code      -- 原业务标识码
-- nw_bnes_code      -- 新业务标识码
-- status            -- 状态：0-未处理；1-审核通过；2-审核未通过；3-已上报；4-上报成功；5-上报失败；6-失败已处理
-- create_time       -- 创建时间
-- update_time       -- 更新时间
-- update_user_id    -- 更新人ID
-- file_id           -- 上报文件ID
-- file_row          -- 文件行号
-- from creditda.
-- ;


















-- delete from t_in_acct_mdfc_bs_sgmt where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d');
-- 
-- commit ;
-- 
-- insert into t_in_acct_mdfc_bs_sgmt
-- select
-- concat(DAY_ID,acct_code)
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,'212'    -- 信息记录类型
-- ,acct_code    -- 待更正业务标识码
-- ,day_id        -- 信息报告日期
-- ,acct_type       -- 账户类型
-- ,'C'  -- 待更正段段标
-- ,now()     -- 创建时间
-- from exp_credit_per_compt_info
-- where  cust_id = '202009170955573431361050718'
-- ;
-- 
-- commit ;
 
-- G
-- insert into t_in_acct_mdfc_bs_sgmt
-- select
-- concat(DAY_ID,acct_code)
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,'212'    -- 信息记录类型
-- ,acct_code    -- 待更正业务标识码
-- ,day_id        -- 信息报告日期
-- ,acct_type       -- 账户类型
-- ,'G'  -- 待更正段段标
-- ,now()     -- 创建时间
-- from exp_credit_per_compt_info
-- where   acct_code = 'X3701010000337888801451'
-- ;
-- 
-- commit ;

-- J
-- insert into t_in_acct_mdfc_bs_sgmt
-- select
-- concat(DAY_ID,acct_code)
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,'212'    -- 信息记录类型
-- ,acct_code    -- 待更正业务标识码
-- ,day_id        -- 信息报告日期
-- ,acct_type       -- 账户类型
-- ,'J'  -- 待更正段段标
-- ,now()     -- 创建时间
-- from exp_credit_per_compt_info
-- where cust_id = '202009231052212991361052986'
-- ;
 

-- commit ;


-- 更新主表
-- delete from t_rd_in_acct_mdfc where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d');
-- 
-- commit ;
-- 
-- insert into t_rd_in_acct_mdfc
-- select
-- null
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,day_id         -- 信息报告日期
-- ,concat(DAY_ID,acct_code)       -- 基础段ID
-- ,'C'   -- 待更正段类型 C-基本信息段；D-相关还款责任人段；G-初始债权说明段；J-非月度表现信息段；K-特殊交易说明段
-- ,concat(DAY_ID,acct_code)     -- 待更正段ID
-- ,'0'           -- 状态
-- ,now()      -- 创建时间
-- ,now()      -- 更新时间
-- ,null          -- 更新人ID
-- ,null          -- 上报文件ID
-- ,null          -- 文件行号
-- from exp_credit_per_compt_info
-- where cust_id = '202009170955573431361050718'
-- ;
-- 
-- commit ;

 

-- insert into t_rd_in_acct_mdfc
-- select
-- null
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,day_id         -- 信息报告日期
-- ,concat(DAY_ID,acct_code)       -- 基础段ID
-- ,'G'   -- 待更正段类型 C-基本信息段；D-相关还款责任人段；G-初始债权说明段；J-非月度表现信息段；K-特殊交易说明段
-- ,concat(DAY_ID,acct_code)     -- 待更正段ID
-- ,'0'           -- 状态
-- ,now()      -- 创建时间
-- ,now()      -- 更新时间
-- ,null          -- 更新人ID
-- ,null          -- 上报文件ID
-- ,null          -- 文件行号
-- from exp_credit_per_compt_info
-- where   acct_code = 'X3701010000337888801451'
-- ;
-- 
-- commit ;


-- insert into t_rd_in_acct_mdfc
-- select
-- null
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,day_id         -- 信息报告日期
-- ,concat(DAY_ID,acct_code)       -- 基础段ID
-- ,'J'   -- 待更正段类型 C-基本信息段；D-相关还款责任人段；G-初始债权说明段；J-非月度表现信息段；K-特殊交易说明段
-- ,concat(DAY_ID,acct_code)     -- 待更正段ID
-- ,'0'           -- 状态
-- ,now()      -- 创建时间
-- ,now()      -- 更新时间
-- ,null          -- 更新人ID
-- ,null          -- 上报文件ID
-- ,null          -- 文件行号
-- from exp_credit_per_compt_info
-- where   cust_id = '202009231052212991361052986'
-- ;
 
-- commit ;

 



-- 按段删除
-- delete from t_rd_in_acct_del where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d');
-- 
-- commit ;
-- 
-- insert into t_rd_in_acct_del
-- select
-- null
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,day_id -- 信息报告日期
-- ,'213' -- 信息记录类型 个人借贷账户按段删除请求记录
-- ,acct_code -- 待删除业务标识码
-- ,'C' -- 待删除段段标C-基本信息段　J-非月度表现信息段　K-特殊交易说明段　　　
-- ,'' -- 待删除起始日期
-- ,DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y-%m-%d') -- 待删除结束日期
-- ,'0' -- 状态
-- ,now() -- 创建时间
-- ,now() -- 更新时间
-- ,null  -- 更新人ID
-- ,null  -- 上报文件ID
-- ,null  -- 文件行号
-- from exp_credit_per_compt_info
-- where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- and cust_id = '202009030924024231361053697'
-- ;
-- 
-- commit ;


-- insert into t_rd_in_acct_del
-- select
-- null
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,day_id -- 信息报告日期
-- ,'213' -- 信息记录类型 个人借贷账户按段删除请求记录
-- ,acct_code -- 待删除业务标识码
-- ,'J' -- 待删除段段标C-基本信息段　J-非月度表现信息段　K-特殊交易说明段　　　
-- ,'' -- 待删除起始日期
-- ,DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y-%m-%d') -- 待删除结束日期
-- ,'0' -- 状态
-- ,now() -- 创建时间
-- ,now() -- 更新时间
-- ,null  -- 更新人ID
-- ,null  -- 上报文件ID
-- ,null  -- 文件行号
-- from exp_credit_per_compt_info
-- where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- and cust_id = '202009030924024231361053697'
-- ;

-- commit ;

-- insert into t_rd_in_acct_del
-- select
-- null
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,day_id -- 信息报告日期
-- ,'213' -- 信息记录类型 个人借贷账户按段删除请求记录
-- ,acct_code -- 待删除业务标识码
-- ,'K' -- 待删除段段标C-基本信息段　J-非月度表现信息段　K-特殊交易说明段　　　
-- ,'' -- 待删除起始日期
-- ,DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y-%m-%d') -- 待删除结束日期
-- ,'0' -- 状态
-- ,now() -- 创建时间
-- ,now() -- 更新时间
-- ,null  -- 更新人ID
-- ,null  -- 上报文件ID
-- ,null  -- 文件行号
-- from exp_credit_per_compt_info
-- where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- and cust_id = '202009030924024231361053697'
-- ;
-- 
-- commit ;


-- 整笔删除
-- delete from t_rd_in_acct_ent_del where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d');
-- 
-- commit ;
-- 
-- insert into t_rd_in_acct_ent_del
-- select
-- null
-- ,day_id
-- ,cust_id
-- ,ln_id
-- ,day_id       -- 信息报告日期
-- ,'214'   -- 信息记录类型
-- ,acct_code   -- 待删除业务标识码
-- ,0         -- 状态
-- ,now()    -- 创建时间
-- ,now()    -- 更新时间
-- ,null -- 更新人ID
-- ,null        -- 上报文件ID
-- ,null       -- 文件行号
-- from exp_credit_per_compt_info
-- where day_id = DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')
-- and acct_code = 'X3701010000337201801078'
-- ; 
-- 
-- commit ;







