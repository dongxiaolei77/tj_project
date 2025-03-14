
-- ------------- 拆分
-- 企业担保-基本信息段
delete from dw_pbc.t_en_guar_acct_bs_inf_sgmt where day_id = '${v_sdate}';
commit;

insert into dw_pbc.t_en_guar_acct_bs_inf_sgmt
select  
concat(DAY_ID,acct_code)
,DAY_ID
,guar_id
,cust_id
,busi_lines -- 担保业务大类
,busi_dtil_lines -- 担保业务种类细分
,open_date -- 开户日期
,guar_amt -- 担保金额
,cy -- 币种
,due_date -- 到期日期
,guar_mode -- 反担保方式
,oth_repy_guar_way -- 其他还款保证方式
,sec_dep -- 保证金比例
,ctrct_txt_code -- 担保合同文本编号
,now() -- 创建时间
from dw_pbc.exp_credit_comp_guar_info t1
where t1.DAY_ID = '${v_sdate}'
;
commit;


-- 企业担保-基础段
delete from dw_pbc.t_en_guar_acct_bs_sgmt where day_id = '${v_sdate}';
commit;

insert into dw_pbc.t_en_guar_acct_bs_sgmt
select
concat(DAY_ID,acct_code)
,DAY_ID
,guar_id
,cust_id
,'440' -- 信息记录类型 
,acct_type -- 账户类型
,acct_code -- 账户标识码
,rpt_date -- 信息报告日期
,rpt_date_code -- 报告时点说明代码
,name -- 债务人名称
,id_type -- 债务人身份标识类型
,id_num -- 债务人身份标识号码
,mngmt_org_code -- 业务管理机构代码
,now() -- 创建时间
from dw_pbc.exp_credit_comp_guar_info t1
where t1.DAY_ID = '${v_sdate}'
;
commit;

-- 插入变更
insert into dw_pbc.t_en_guar_acct_bs_sgmt
select
concat(t1.DAY_ID,t1.acct_code)
,t1.DAY_ID
,t1.guar_id
,t1.cust_id
,null -- 信息记录类型 
,null -- 账户类型
,null -- 账户标识码
,null -- 信息报告日期
,null -- 报告时点说明代码
,t1.name -- 债务人名称
,t1.id_type -- 债务人身份标识类型
,t1.id_num -- 债务人身份标识号码
,t1.mngmt_org_code -- 业务管理机构代码
,now() -- 创建时间
from dw_pbc.exp_credit_comp_guar_info_change_b t1
inner join (
	select * from (
		select distinct guar_id,acct_type,rpt_date,rpt_date_code 
		from dw_pbc.exp_credit_comp_guar_info
		order by rpt_date DESC
	)t
	group by guar_id
)t2
on t1.guar_id = t2.guar_Id
where t1.DAY_ID = '${v_sdate}'
;
commit;


-- 按段更正标识
delete from  dw_pbc.t_en_guar_mdfc_bs_sgmt where day_id = '${v_sdate}'  AND mdfc_sgmt_code = 'B' ;commit ;
 
insert into dw_pbc.t_en_guar_mdfc_bs_sgmt
 SELECT distinct 
 concat(t1.DAY_ID,t1.acct_code)
 ,t1.DAY_ID
 ,t1.guar_id
 ,t1.cust_id
 ,'442'    -- 信息记录类型
 ,t1.acct_code    -- 待更正业务标识码
 -- ,DATE_FORMAT(t1.DAY_ID ,'%Y-%m-%d')        -- 信息报告日期
 ,t2.rpt_date
 ,'G1'       -- 账户类型
 ,'B'  -- 待更正段段标
 ,NOW()     -- 创建时间
 from dw_pbc.exp_credit_comp_guar_info_change_b t1
 inner join (
	select * from (
		select distinct guar_id,acct_type,rpt_date,rpt_date_code 
		from dw_pbc.exp_credit_comp_guar_info
		order by rpt_date DESC
	)t
	group by guar_id
)t2
on t1.guar_id = t2.guar_Id
 where t1.DAY_ID = '${v_sdate}'
 -- and t1.guar_id = '202408090007'
 ;
 commit ;
 
delete from dw_pbc.t_rd_en_sec_acct_mdfc where day_id = '${v_sdate}'  AND mdfc_sgmt_code = 'B' ;commit ;
 
insert into dw_pbc.t_rd_en_sec_acct_mdfc 
 select distinct 
 null               ID
 ,t1.DAY_ID          
 ,t1.guar_id          
 ,t1.cust_id          
 -- ,DATE_FORMAT(t1.DAY_ID ,'%Y-%m-%d')        --   信息报告日期
 ,t2.rpt_date
 ,concat(t1.DAY_ID,t1.acct_code)    --    基础段ID
 ,'B'--    待更正段类型 待更正段类型：B-基础段；C-基本信息段；D-在保责任信息段；E-相关还款责任人段；F-抵质押物信息段
 ,concat(t1.DAY_ID,t1.acct_code)  --    待更正段ID
 ,0             -- 状态
 ,now()         -- 创建时间
 ,now()         -- 更新时间
 ,null          -- 更新人ID
 ,null          -- 上报文件ID
 ,null          -- 文件行号      
 from dw_pbc.exp_credit_comp_guar_info_change_b t1
 inner join (
	select * from (
		select distinct guar_id,acct_type,rpt_date,rpt_date_code 
		from dw_pbc.exp_credit_comp_guar_info
		order by rpt_date DESC
	)t
	group by guar_id
)t2
on t1.guar_id = t2.guar_Id
 where t1.DAY_ID = '${v_sdate}'
 -- and t1.guar_id = '202408090007'
 ;
 commit ;
 


-- 企业担保-授信额度信息段
-- delete from t_en_guar_acct_cred_sgmt where day_id = '${v_sdate}';
-- insert into t_en_guar_acct_cred_sgmt
-- select
-- concat(DAY_ID,acct_code)
-- ,DAY_ID
-- ,guar_id
-- ,cust_id
-- ,'' -- 授信协议标识码
-- ,now() -- 创建时间
-- from exp_credit_comp_guar_info t1
-- where t1.DAY_ID = '${v_sdate}'
-- ;

-- 企业担保-在保责任信息段
delete from dw_pbc.t_en_guar_rlt_repymt_inf_sgmt where day_id = '${v_sdate}';
commit;

insert into dw_pbc.t_en_guar_rlt_repymt_inf_sgmt
select
concat(DAY_ID,acct_code)
,DAY_ID
,guar_id
,cust_id
,acct_status -- 账户状态
,loan_amt -- 在保余额
,repay_prd -- 余额变化日期
,five_cate -- 五级分类
,five_cate_adj_date -- 五级分类认定日期
,ri_ex -- 风险敞口
,comp_adv_flag -- 代偿(垫款)标志
,close_date -- 账户关闭日期
,now() -- 创建时间
from dw_pbc.exp_credit_comp_guar_info t1
where t1.DAY_ID = '${v_sdate}'
and rpt_date_code <> '50'   -- 其他信息变化 不上报在保责任信息段
;
commit;


   -- rlt_repymt_inf_sgmt_id
-- 企业担保-相关还款责任人段
delete from dw_pbc.t_en_rlt_repymt_inf_sgmt where day_id = '${v_sdate}';
commit ;
insert into dw_pbc.t_en_rlt_repymt_inf_sgmt
select
concat(t1.DAY_ID,t1.acct_code)
,t1.DAY_ID
,t1.guar_id
,t1.cust_id
,coalesce(t2.duty_qty,0) -- 责任人个数 
,now() -- 创建时间
from dw_pbc.exp_credit_comp_guar_info t1
left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from dw_pbc.exp_credit_comp_repay_duty_info 
where DAY_ID = '${v_sdate}'
group by guar_id
)t2
on t1.guar_id = t2.guar_id
where t1.DAY_ID = '${v_sdate}';

commit;


-- 插入按段更新
insert into dw_pbc.t_en_rlt_repymt_inf_sgmt
select distinct 
concat(t1.DAY_ID,t2.acct_code)
,t1.DAY_ID
,t1.guar_id
,t2.cust_id
,coalesce(t1.duty_qty,0) -- 责任人个数 
,now()
from (
select DAY_ID,guar_id,count(distinct duty_cert_no) as duty_qty
from dw_pbc.exp_credit_comp_guar_info_change_e 
where DAY_ID = '${v_sdate}'
-- and guar_id = '202408090007'
group by guar_id,DAY_ID
)t1
inner join (select distinct guar_id,cust_id,acct_code from dw_pbc.exp_credit_comp_guar_info)t2
on t1.guar_id = t2.guar_id

;
commit ;


-- 相关还款责任人信息 
 delete from dw_pbc.t_en_rlt_repymt_inf_sgmt_el   where day_id = '${v_sdate}';
 --
commit;
 -- 
 insert into dw_pbc.t_en_rlt_repymt_inf_sgmt_el
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
   ,concat('X3701010000337',t1.guar_cont_no) -- 保证合同编号,
   ,now() -- 创建时间,
 from dw_pbc.exp_credit_comp_repay_duty_info t1
 inner join    dw_pbc.exp_credit_comp_guar_info  t2 
    on t1.guar_id = t2.guar_id
   and t2.day_id = '${v_sdate}'
left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from dw_pbc.exp_credit_comp_repay_duty_info 
where DAY_ID = '${v_sdate}'
group by guar_id
)t3
on t1.guar_id = t3.guar_id
where t1.day_id = '${v_sdate}'
and t1.guar_cont_no is not null 
 ;
commit;


 -- 插入按段更正
 insert into dw_pbc.t_en_rlt_repymt_inf_sgmt_el
 select distinct 
   null ID
   ,t1.day_id -- 数据日期,
   ,t1.guar_id -- 担保业务编号,
   ,t1.cust_id -- 客户号,
   ,concat(t1.day_id,t2.acct_code) -- 相关还款责任人段ID,
   ,t1.info_id_type -- 身份类别,
   ,trim(t1.duty_name) -- 责任人名称,
   ,t1.duty_cert_type -- 责任人身份标识类型,
   ,t1.duty_cert_no -- 责任人身份标识号码,
   ,t1.duty_type -- 还款责任人类型：1-共同债务人2-反担保人9-其他,
   ,t1.duty_amt -- 还款责任金额,
   -- ,t1.duty_flag -- 联保标志：0-单人保证/多人分保（单人保证指该账户对应的担保交易仅有一个反担保人，多人分保指该账户对应的担保交易有多个反担保人，且每个反担保人独立分担一部分担保责任）1-联保（联保指该账户对应的担保交易有多个反担保人且共同承担担保责任）,
   ,case when coalesce(t3.duty_qty,0) >= 2 then '1' else '0' end as duty_flag -- 联保标志  0-单人保证/多人分保   1-联保
    ,concat('X3701010000337',t1.guar_cont_no) -- 保证合同编号,
   ,now() -- 创建时间,
 from dw_pbc.exp_credit_comp_guar_info_change_e t1
 inner join (select distinct guar_id,acct_code from dw_pbc.exp_credit_comp_guar_info) t2
    on t1.guar_id = t2.guar_id
left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from dw_pbc.exp_credit_comp_guar_info_change_e 
where DAY_ID = '${v_sdate}'
group by guar_id
)t3
 on t1.guar_id = t3.guar_id
 where t1.day_id = '${v_sdate}'
 -- and  t1.guar_id = '202408090007'
 ;
 commit ;
 
 
-- 按段更正标识
delete from  dw_pbc.t_en_guar_mdfc_bs_sgmt where day_id = '${v_sdate}'  AND mdfc_sgmt_code = 'E' ;commit ;
 
insert into dw_pbc.t_en_guar_mdfc_bs_sgmt
 SELECT distinct 
 concat(t1.DAY_ID,t2.acct_code)
 ,t1.DAY_ID
 ,t1.guar_id
 ,t1.cust_id
 ,'442'    -- 信息记录类型
 ,t2.acct_code    -- 待更正业务标识码
 ,DATE_FORMAT(t1.DAY_ID ,'%Y-%m-%d')        -- 信息报告日期
 ,'G1'       -- 账户类型
 ,'E'  -- 待更正段段标
 ,NOW()     -- 创建时间
 from dw_pbc.exp_credit_comp_guar_info_change_e t1
 inner join (select distinct guar_id,acct_code from dw_pbc.exp_credit_comp_guar_info) t2
 on t1.guar_id = t2.guar_id
 where t1.DAY_ID = '${v_sdate}'
 -- and t1.guar_id = '202408090007'
 ;
 commit ;
 
 delete from dw_pbc.t_rd_en_sec_acct_mdfc where day_id = '${v_sdate}'  AND mdfc_sgmt_code = 'E' ;commit ;
 
insert into dw_pbc.t_rd_en_sec_acct_mdfc 
 select distinct 
 null               ID
 ,t1.DAY_ID          
 ,t1.guar_id          
 ,t1.cust_id          
 ,DATE_FORMAT(t1.DAY_ID ,'%Y-%m-%d')        --   信息报告日期
 ,concat(t1.DAY_ID,t2.acct_code)    --    基础段ID
 ,'E'--    待更正段类型 待更正段类型：B-基础段；C-基本信息段；D-在保责任信息段；E-相关还款责任人段；F-抵质押物信息段
 ,concat(t1.DAY_ID,t2.acct_code)  --    待更正段ID
 ,0             -- 状态
 ,now()         -- 创建时间
 ,now()         -- 更新时间
 ,null          -- 更新人ID
 ,null          -- 上报文件ID
 ,null          -- 文件行号      
 from dw_pbc.exp_credit_comp_guar_info_change_e t1
  inner join (select distinct guar_id,acct_code from dw_pbc.exp_credit_comp_guar_info) t2
 on t1.guar_id = t2.guar_id
 where t1.DAY_ID = '${v_sdate}'
 -- and t1.guar_id = '202408090007'
 ;
 commit ;
 

-- 企业担保账户记录
-- t_rd_en_sec_acct_inf

delete from dw_pbc.t_rd_en_sec_acct_inf where day_id = '${v_sdate}';
commit;

insert into dw_pbc.t_rd_en_sec_acct_inf
select
null  -- ID
,DAY_ID -- DAY_ID
,guar_id
,CUST_ID
,DAY_ID -- 信息报告日期
,concat(DAY_ID,acct_code) -- 基础段
,concat(DAY_ID,acct_code) -- 基本信息段
,concat(DAY_ID,acct_code) -- 相关还款责任人段
,concat(DAY_ID,acct_code) -- 抵质押物信息段
,concat(DAY_ID,acct_code) -- 授信额度信息段
,concat(DAY_ID,acct_code) -- 在保责任信息段
,0 -- 状态
,now() -- 创建时间
,now() -- 更新时间
,null -- 更新人ID
,null -- 上报文件ID
,null -- 文件行号
from dw_pbc.exp_credit_comp_guar_info  t1
where t1.DAY_ID = '${v_sdate}'
;
commit;


-- -- 企业担保-相关还款责任人段详情
-- --  t_en_rlt_repymt_inf_sgmt_el


-- -- 企业担保账户按段更正请求记录
-- delete from dw_pbc.t_en_guar_mdfc_bs_sgmt where day_id = '${v_sdate}'; COMMIT;
-- insert into dw_pbc.t_en_guar_mdfc_bs_sgmt
-- select
-- concat(day_id,acct_code)
-- ,day_id
-- ,guar_id
-- ,cust_id
-- ,'442'     -- 信息记录类型
-- ,acct_code     -- 待更正业务标识码
-- ,rpt_date -- 信息报告日期
-- ,acct_type        -- 账户类型
-- ,'C'   -- 待更正段段标
-- ,now()      -- 创建时间
-- from dw_pbc.exp_credit_comp_guar_info t1
-- where t1.day_id = '${v_sdate}'
-- and guar_id='20200302-052'
-- ;
-- commit;

-- insert into dw_pbc.t_en_guar_mdfc_bs_sgmt
-- select
-- concat(day_id,acct_code)
-- ,day_id
-- ,guar_id
-- ,cust_id
-- ,'442'     -- 信息记录类型
-- ,acct_code     -- 待更正业务标识码
-- ,rpt_date       -- 信息报告日期
-- ,acct_type        -- 账户类型
-- ,'D'   -- 待更正段段标
-- ,now()      -- 创建时间
-- from dw_pbc.exp_credit_comp_guar_info t1
-- where t1.day_id = '${v_sdate}'
-- and cust_id='202008191036440201361050064'
-- ;
-- commit;

-- delete from dw_pbc.t_rd_en_sec_acct_mdfc where day_id = '${v_sdate}'; COMMIT;
-- insert into dw_pbc.t_rd_en_sec_acct_mdfc
-- select
-- null
-- ,day_id
-- ,guar_id
-- ,cust_id
-- ,rpt_date        -- 信息报告日期
-- ,concat(day_id,acct_code)      -- 基础段ID
-- ,'C'  -- 待更正段标：B-基础段；C-基本信息段；D-在保责任信息段；E-相关还款责任人段；F-抵质押物信息段；G-授信额度信息段
-- ,concat(day_id,acct_code)    -- 待更正段ID
-- ,0 AS STATUS         -- 状态
-- ,now()     -- 创建时间
-- ,now()     -- 更新时间
-- ,null      -- 更新人ID
-- ,null         -- 上报文件ID
-- ,null        -- 文件行号
-- from dw_pbc.exp_credit_comp_guar_info t1
-- where t1.day_id = '${v_sdate}'
-- and guar_id='20200302-052'
-- ;
-- commit;

-- 
-- insert into dw_pbc.t_rd_en_sec_acct_mdfc
-- select
-- null
-- ,day_id
-- ,guar_id
-- ,cust_id
-- ,rpt_date        -- 信息报告日期
-- ,concat(day_id,acct_code)      -- 基础段ID
-- ,'D'  -- 待更正段标：B-基础段；C-基本信息段；D-在保责任信息段；E-相关还款责任人段；F-抵质押物信息段；G-授信额度信息段
-- ,concat(day_id,acct_code)    -- 待更正段ID
-- ,0          -- 状态
-- ,now()     -- 创建时间
-- ,now()     -- 更新时间
-- ,null      -- 更新人ID
-- ,null         -- 上报文件ID
-- ,null        -- 文件行号
-- from dw_pbc.exp_credit_comp_guar_info t1
-- where t1.day_id = '${v_sdate}'
-- AND cust_id='202008191036440201361050064'
-- ;
-- commit;

-- -- 按段删除
-- delete from dw_pbc.t_rd_en_sec_acct_del where day_id = '${v_sdate}'; COMMIT;
-- insert into dw_pbc.t_rd_en_sec_acct_del
-- select
-- null
-- ,day_id
-- ,guar_id
-- ,cust_id
-- ,rpt_date         -- 信息报告日期
-- ,'443'     -- 信息记录类型
-- ,acct_code     -- 待删除业务标识码
-- ,'C'    -- 待删除段段标：C-基本信息段；D-在保责任信息段
-- ,''   -- 待删除起始日期
-- ,DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y-%m-%d')     -- 待删除结束日期
-- ,0           -- 状态
-- ,now()      -- 创建时间
-- ,now()      -- 更新时间
-- ,null   -- 更新人ID
-- ,null          -- 上报文件ID
-- ,null         -- 文件行号
-- from dw_pbc.exp_credit_comp_guar_info t1
-- where t1.DAY_ID = '${v_sdate}'
-- AND guar_id= '20200323-252'
-- ; 
-- commit;
-- 
-- insert into dw_pbc.t_rd_en_sec_acct_del
-- select
-- null
-- ,day_id
-- ,guar_id
-- ,cust_id
-- ,rpt_date         -- 信息报告日期
-- ,'443'     -- 信息记录类型
-- ,acct_code     -- 待删除业务标识码
-- ,'D'    -- 待删除段段标：C-基本信息段；D-在保责任信息段
-- ,''   -- 待删除起始日期
-- ,DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y-%m-%d')     -- 待删除结束日期
-- ,0           -- 状态
-- ,now()      -- 创建时间
-- ,now()      -- 更新时间
-- ,null   -- 更新人ID
-- ,null          -- 上报文件ID
-- ,null         -- 文件行号
-- from dw_pbc.exp_credit_comp_guar_info t1
-- where t1.DAY_ID = '${v_sdate}'
-- AND guar_id= '20200323-252'
-- ; 
-- commit; 
-- 
-- -- 整笔删除
-- delete from dw_pbc.t_rd_en_sec_acct_ent_del where day_id = '${v_sdate}'; COMMIT;
-- insert into dw_pbc.t_rd_en_sec_acct_ent_del
-- select
-- null
-- ,day_id
-- ,guar_id
-- ,cust_id
-- ,rpt_date        -- 信息报告日期
-- ,'444'    -- 信息记录类型
-- ,acct_code    -- 待删除业务标识
-- ,0          -- 状态
-- ,now()    -- 创建时间
-- ,now()    -- 更新时间
-- ,null  -- 更新人ID
-- ,null         -- 上报文件ID
-- ,null        -- 文件行号
-- from dw_pbc.exp_credit_comp_guar_info t1
-- where t1.DAY_ID = '${v_sdate}'
-- AND guar_id= '20200323-252'
-- ; 
-- commit;
