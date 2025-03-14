-- exp_credit_per_guar_info 个人担保信息
-- exp_credit_per_guar_info_upd 个人担保信息更正信息

-- ------------- 拆分
-- 个人担保-基本信息段
delete from dw_pbc.t_in_guar_acct_bs_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_guar_acct_bs_inf_sgmt
select
concat(DAY_ID,acct_code)
,DAY_ID
,guar_id
,cust_id
,busi_lines -- 担保业务大类
,busi_dtil_lines -- 担保业务种类细分
,open_date -- 开户日期
,acct_cred_line -- 担保金额
,cy -- 币种
,due_date -- 到期日期
,guar_mode -- 反担保方式
,oth_repy_guar_way -- 其他还款保证方式
,sec_dep -- 保证金比例
,ctrct_txt_cd -- 担保合同文本编号
,now() -- 创建时间
from dw_pbc.exp_credit_per_guar_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;

-- 按段更新 C-基本信息段
insert into dw_pbc.t_in_guar_acct_bs_inf_sgmt
select
concat(DAY_ID,acct_code)
,DAY_ID
,guar_id
,cust_id
,busi_lines -- 担保业务大类
,busi_dtil_lines -- 担保业务种类细分
,open_date -- 开户日期
,acct_cred_line -- 担保金额
,cy -- 币种
,due_date -- 到期日期
,guar_mode -- 反担保方式
,oth_repy_guar_way -- 其他还款保证方式
,sec_dep -- 保证金比例
,ctrct_txt_cd -- 担保合同文本编号
,now() -- 创建时间
from dw_pbc.exp_credit_per_guar_info_change_c t1
where t1.DAY_ID = '${v_sdate}'
;
commit ;

delete from dw_pbc.t_in_guar_mdfc_bs_sgmt where day_id = '${v_sdate}'  AND mdfc_sgmt_code = 'C';commit ;
 
insert into dw_pbc.t_in_guar_mdfc_bs_sgmt
 SELECT
 concat('${v_sdate}',acct_code)
 ,'${v_sdate}'
 ,cust_id
 ,guar_id
 ,'232'    -- 信息记录类型
 ,acct_code    -- 待更正业务标识码
 ,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')        -- 信息报告日期
 ,'G1'       -- 账户类型
 ,'C'  -- 待更正段段标
 ,NOW()     -- 创建时间
 from dw_pbc.exp_credit_per_guar_info_change_c t1
 where t1.DAY_ID = '${v_sdate}'
 ;
 commit ;
 
 delete from dw_pbc.t_rd_in_sec_acct_mdfc where day_id = '${v_sdate}'  AND mdfc_sgmt_code = 'C';commit ;
 
insert into dw_pbc.t_rd_in_sec_acct_mdfc
 select
 null               ID
 ,'${v_sdate}'           
 ,guar_id          
 ,cust_id          
 ,DATE_FORMAT('${v_sdate}' ,'%Y-%m-%d')        --   信息报告日期
 ,concat('${v_sdate}',acct_code)    --    基础段ID
 ,'C'--    待更正段类型 待更正段类型：B-基础段；C-基本信息段；D-在保责任信息段；E-相关还款责任人段；F-抵质押物信息段
 ,concat('${v_sdate}',acct_code)  --    待更正段ID
 ,0             -- 状态
 ,now()         -- 创建时间
 ,now()         -- 更新时间
 ,null          -- 更新人ID
 ,null          -- 上报文件ID
 ,null          -- 文件行号      
 from dw_pbc.exp_credit_per_guar_info_change_c t1
 where t1.DAY_ID = '${v_sdate}'
 ;
 commit ;

-- 个人担保-基础段
delete from dw_pbc.t_in_guar_acct_bs_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_guar_acct_bs_sgmt
select
concat(DAY_ID,acct_code)
,DAY_ID
,guar_id
,cust_id
,'230' -- 信息记录类型
,acct_type -- 账户类型
,acct_code -- 账户标识码
,DAY_ID -- 信息报告日期
,rpt_date_code -- 报告时点说明代码
,name -- 债务人姓名
,id_type -- 债务人证件类型
,id_num -- 债务人证件号码
,mngmt_org_code -- 业务管理机构代码
,now() -- 创建时间
from dw_pbc.exp_credit_per_guar_info t1
where t1.DAY_ID = '${v_sdate}'
;

commit ;



-- 按段更新 - B 基础段
drop table if exists dw_pbc.tmp_t_in_guar_acct_bs_sgmt ;

commit;

create  table dw_pbc.tmp_t_in_guar_acct_bs_sgmt (
guar_id varchar(60) 
,rpt_date date
,key(guar_id)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit;

-- 获取最晚信息报告日期
insert into dw_pbc.tmp_t_in_guar_acct_bs_sgmt
select
t1.guar_id
,max(t1.rpt_date)  -- 信息报告日期
from dw_pbc.t_in_guar_acct_bs_sgmt t1
inner join dw_pbc.exp_credit_per_guar_info_change_b t2
on t1.guar_id = t2.guar_id
and t2.day_id = '${v_sdate}'
where t1.day_id < '${v_sdate}'
group by t1.guar_id
;
commit ;

insert into dw_pbc.t_in_guar_acct_bs_sgmt
select
concat(DAY_ID,acct_code)
,DAY_ID
,guar_id
,cust_id
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
from dw_pbc.exp_credit_per_guar_info_change_b t1
where t1.DAY_ID = '${v_sdate}'
;

commit;


-- 按段更新
 delete from dw_pbc.t_in_guar_mdfc_bs_sgmt where day_id = '${v_sdate}' AND mdfc_sgmt_code = 'B';
 
 commit ;
 
 insert into dw_pbc.t_in_guar_mdfc_bs_sgmt
 SELECT
 concat(t1.day_id,t1.acct_code)
 ,t1.day_id
 ,t1.cust_id
 ,t1.guar_id
 ,'232'    -- 信息记录类型
 ,t1.acct_code    -- 待更正业务标识码
 ,t2.rpt_date       -- 注意 信息报告日期 取B段的最晚数据报告日期
 ,'G1'       -- 账户类型
 ,'B'  -- 待更正段段标
 ,NOW()     -- 创建时间
 from dw_pbc.exp_credit_per_guar_info_change_b t1
 inner join dw_pbc.tmp_t_in_guar_acct_bs_sgmt t2
         on t1.guar_id = t2.guar_id
 where t1.DAY_ID = '${v_sdate}'
 ;
 commit ;


-- 按段更新 上报文件
 delete from dw_pbc.t_rd_in_sec_acct_mdfc where day_id = '${v_sdate}'  AND mdfc_sgmt_code = 'B';commit ;
 insert into dw_pbc.t_rd_in_sec_acct_mdfc
 select
 null               ID
 ,'${v_sdate}'           
 ,t1.guar_id          
 ,t1.cust_id          
 ,t2.rpt_date        --   注意 信息报告日期 取B段的最晚数据报告日期
 ,concat('${v_sdate}',t1.acct_code)    --    基础段ID
 ,'B'--    待更正段类型 待更正段类型：B-基础段；C-基本信息段；D-在保责任信息段；E-相关还款责任人段；F-抵质押物信息段
 ,concat('${v_sdate}',t1.acct_code)  --    待更正段ID
 ,0             -- 状态
 ,now()         -- 创建时间
 ,now()         -- 更新时间
 ,null          -- 更新人ID
 ,null          -- 上报文件ID
 ,null          -- 文件行号      
 from dw_pbc.exp_credit_per_guar_info_change_b t1
 inner join dw_pbc.tmp_t_in_guar_acct_bs_sgmt t2
         on t1.guar_id = t2.guar_id
 where t1.DAY_ID = '${v_sdate}'
 ;
 commit ;

-- 个人担保-抵质押物信息段 

-- delete from dw_pbc.t_in_guar_motga_cltal_ctrct_inf_sgmt where day_id = '${v_sdate}';
-- 
-- commit ;
-- 
-- insert into dw_pbc.t_in_guar_motga_cltal_ctrct_inf_sgmt
-- select
-- concat(DAY_ID,acct_code)
-- ,DAY_ID
-- ,guar_id
-- ,cust_id
-- ,0 -- 抵质押合同个数 
-- ,now() -- 创建时间
-- from dw_pbc.exp_credit_per_guar_info t1
-- where t1.DAY_ID = '${v_sdate}'
-- 
-- ;
-- 
-- commit ;


-- 个人担保-在保责任信息段
delete from dw_pbc.t_in_guar_rlt_repymt_inf_sgmt where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_in_guar_rlt_repymt_inf_sgmt
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
from dw_pbc.exp_credit_per_guar_info t1
where t1.DAY_ID = '${v_sdate}'
and rpt_date_code <> '50'
;

commit ;


--  个人担保-相关还款责任人段
 delete from dw_pbc.t_in_rlt_repymt_inf_sgmt where day_id = '${v_sdate}';
 
 commit ;
 
 insert into dw_pbc.t_in_rlt_repymt_inf_sgmt
 select distinct 
 concat(t1.DAY_ID,t1.acct_code)
 ,t1.DAY_ID
 ,t1.guar_id
 ,t1.cust_id
 ,coalesce(t2.duty_qty,0) -- 责任人个数 
 ,now()
 from dw_pbc.exp_credit_per_guar_info t1
 left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from dw_pbc.exp_credit_per_repay_duty_info 
where DAY_ID = '${v_sdate}'
group by guar_id
)t2
 on t1.guar_id = t2.guar_id
 where t1.DAY_ID = '${v_sdate}'
 
 ;
 
 commit ;

-- 插入按段更新
insert into dw_pbc.t_in_rlt_repymt_inf_sgmt
select distinct 
concat(t1.DAY_ID,t2.acct_code)
,t1.DAY_ID
,t1.guar_id
,t2.cust_id
,coalesce(t1.duty_qty,0) -- 责任人个数 
,now()
from (
select DAY_ID,guar_id,count(distinct duty_cert_no) as duty_qty
from dw_pbc.exp_credit_per_guar_info_change_e 
where DAY_ID = '${v_sdate}'
-- and guar_id = '202408090007'
group by guar_id,DAY_ID
)t1
inner join (select distinct guar_id,cust_id,acct_code from dw_pbc.exp_credit_per_guar_info)t2
on t1.guar_id = t2.guar_id

;
commit ;

-- 4 个人相关还款责任人信息 
 delete from dw_pbc.t_in_rlt_repymt_inf_sgmt_el where day_id = '${v_sdate}';
 
 commit ;
 
 insert into dw_pbc.t_in_rlt_repymt_inf_sgmt_el
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
 from dw_pbc.exp_credit_per_repay_duty_info t1
 inner join dw_pbc.exp_credit_per_guar_info t2
    on t1.guar_id = t2.guar_id
   and t2.day_id = '${v_sdate}'
left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from dw_pbc.exp_credit_per_repay_duty_info 
where DAY_ID = '${v_sdate}'
group by guar_id
)t3
 on t1.guar_id = t3.guar_id

 where t1.day_id = '${v_sdate}'
 ;
 commit ;
 
 -- 插入按段更正
 insert into dw_pbc.t_in_rlt_repymt_inf_sgmt_el
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
 from dw_pbc.exp_credit_per_guar_info_change_e t1
 inner join (select distinct guar_id,acct_code from dw_pbc.exp_credit_per_guar_info) t2
    on t1.guar_id = t2.guar_id
left join (
select guar_id,count(distinct duty_cert_no) as duty_qty
from dw_pbc.exp_credit_per_guar_info_change_e 
where DAY_ID = '${v_sdate}'
group by guar_id
)t3
 on t1.guar_id = t3.guar_id
 where t1.day_id = '${v_sdate}'
 -- and  t1.guar_id = '202408090007'
 ;
 commit ;
 
 
-- 按段更正标识
delete from  dw_pbc.t_in_guar_mdfc_bs_sgmt where day_id = '${v_sdate}'  AND mdfc_sgmt_code = 'E' ;commit ;
 
insert into dw_pbc.t_in_guar_mdfc_bs_sgmt
 SELECT distinct 
 concat(t1.DAY_ID,t2.acct_code)
 ,t1.DAY_ID
 ,t1.cust_id
 ,t1.guar_id
 ,'232'    -- 信息记录类型
 ,t2.acct_code    -- 待更正业务标识码
 ,DATE_FORMAT(t1.DAY_ID ,'%Y-%m-%d')        -- 信息报告日期
 ,'G1'       -- 账户类型
 ,'E'  -- 待更正段段标
 ,NOW()     -- 创建时间
 from dw_pbc.exp_credit_per_guar_info_change_e t1
 inner join (select distinct guar_id,acct_code from dw_pbc.exp_credit_per_guar_info) t2
 on t1.guar_id = t2.guar_id
 where t1.DAY_ID = '${v_sdate}'
 -- and t1.guar_id = '202408090007'
 ;
 commit ;
 
 delete from dw_pbc.t_rd_in_sec_acct_mdfc where day_id = '${v_sdate}'  AND mdfc_sgmt_code = 'E' ;commit ;
 
insert into dw_pbc.t_rd_in_sec_acct_mdfc
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
 from dw_pbc.exp_credit_per_guar_info_change_e t1
  inner join (select distinct guar_id,acct_code from dw_pbc.exp_credit_per_guar_info) t2
 on t1.guar_id = t2.guar_id
 where t1.DAY_ID = '${v_sdate}'
 -- and t1.guar_id = '202408090007'
 ;
 commit ;
 
 
 
--  抵（质）押合同标识码(没有相关信息，不提供)
--  t_in_guar_motga_cltal_ctrct_inf_sgmt_el  

 
--  个人担保账户记录
-- t_rd_en_sec_acct_in


delete from dw_pbc.t_rd_in_sec_acct_inf where day_id = '${v_sdate}';

commit ;

insert into dw_pbc.t_rd_in_sec_acct_inf
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
,concat(DAY_ID,acct_code) -- 在保责任信息段
,0 -- 状态
,now() -- 创建时间
,now() -- 更新时间
,null -- 更新人ID
,null -- 上报文件ID
,null -- 文件行号
from dw_pbc.exp_credit_per_guar_info t1
where t1.DAY_ID = '${v_sdate}'

;

commit ;
