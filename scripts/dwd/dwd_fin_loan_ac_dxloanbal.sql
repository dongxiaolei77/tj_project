-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_fin_loan_ac_dxloanbal 客户支用明细信息 
-- 源表     ：dw_nd.ods_gcredit_loan_ac_dxloanbal 贷款台账信息文件
-- 变更记录 ： 20220117:统一变动 
--             20220516 日志变量注释  xgm      
-- ---------------------------------------
-- set @etl_date='${v_sdate}';
-- set @time=now();
-- set @table_name='dwd_fin_loan_ac_dxloanbal';
-- set @sorting=@sorting+1;
-- set @auto_increment_increment=1;  
  
 -- 客户支用明细信息 
truncate table  dw_base.dwd_fin_loan_ac_dxloanbal;
insert into  dw_base.dwd_fin_loan_ac_dxloanbal  (
   drawndn_seqno , --  支用编号
   cert_no   , --  主体证件号
   cust_id   , --  客户编号
   cust_name   , --  客户名称
   prod_code   , --  产品编号
   prod_name   , --  产品名称
   terms   , --  期数
   amt   , --  放款金额
   bal   , --  本金余额
   abal   , --  正常本金
   aubal  , --   待转逾期本金
   over_prin  , --   拖欠本金
   over_int  , --  拖欠利息
   start_date -- 支用时间
 ) 
 select  drawndn_seqno , -- 支用编号
   id_number , -- 证件号
   out_customer_id , -- 外部客户号
   customer_name , --  客户名称
   prod_id , --  产品编号
   prod_name , -- 产品名称
   terms , --  期数
   amt , --  放款金额
   bal , -- 本金余额
   abal , -- 正常本金
   aubal , --  待转逾期本金
   over_prin , -- 拖欠本金
   over_int  , --  拖欠利息
   start_date -- 支用时间
 from 
 (
select  
   drawndn_seqno , -- 支用编号
   id_number , -- 证件号
   out_customer_id , -- 外部客户号
   customer_name , --  客户名称
   prod_id , --  产品编号
   prod_name , -- 产品名称
   terms , --  期数
   amt , --  放款金额
   bal , -- 本金余额
   abal , -- 正常本金
   aubal , --  待转逾期本金
   over_prin , -- 拖欠本金
   over_int  , --  拖欠利息
   start_date -- 支用时间
   ,row_number() over(partition by drawndn_seqno order by update_time desc) as rk
 from dw_nd.ods_gcredit_loan_ac_dxloanbal 
 where prod_id='PA0080501' and  loan_scenario<>1 
 and date_format(update_time,'%Y%m%d') <=  '${v_sdate}' 
 ) a 
 where rk = 1 ;
 
-- select row_count() into @rowcnt;
commit;

-- insert into dw_base.pub_etl_log -- values (@etl_date,@pro_name,@table_name,@sorting,concat('客户支用明细信息表加载完成,共插入',@rowcnt,'条'),@time,now());commit;
