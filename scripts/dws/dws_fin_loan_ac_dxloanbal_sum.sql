-- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dws_fin_loan_ac_dxloanbal_sum  客户支用汇总信息
-- 源表     ：dw_base.dwd_fin_loan_ac_dxloanbal 客户支用明细信息、dw_base.dwd_fin_loan_ac_dxretustatfee 客户当前保费逾期信息
-- 变更记录 ： 20220117:统一变动  
--             20220516 日志变量注释  xgm  
--             20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl 
-- ---------------------------------------
 --  将支用信息汇总到客户级别 通过客户号关联 

 truncate  table dw_base.dws_fin_loan_ac_dxloanbal_sum ;
 insert into  dw_base.dws_fin_loan_ac_dxloanbal_sum  (
   cert_no , --  主体证件号
   cust_name , --  客户名称
   cust_id , -- 客户编号
   prod_code , -- 产品编号
   prod_name , -- 产品名称
   amt , --  放款金额
   bal , -- 本金余额
   abal , --  正常本金
   aubal , --  待转逾期本金
   over_prin , -- 拖欠本金
   over_int  ,-- 拖欠利息
   over_fee  , --  拖欠保费 
   over_days  , -- 保费逾期天数    
   dx_cn  -- 支用笔数
 ) 
 
 select  
   cert_no  , -- 主体证件号
   cust_name  , -- 客户名称
   cust_id , -- 客户编号
   prod_code , -- 产品编号
   prod_name , -- 产品名称
   sum(amt) , -- 放款金额
   sum(bal) , -- 本金余额
   sum(abal) , -- 正常本金
   sum(aubal) , -- 待转逾期本金
   sum(over_prin) , -- 拖欠本金
   sum(over_int)  , -- 拖欠利息
   sum(b.over_fee)  , --  拖欠保费 
   max(b.over_days)  , -- 保费逾期天数 
   count(*) -- 支用笔数
from  dw_base.dwd_fin_loan_ac_dxloanbal a
left join dw_base.dwd_fin_loan_ac_dxretustatfee b 
on a.drawndn_seqno=b.drawndn_seqno
group by  cert_no  ,cust_name  , cust_id , prod_code ,  prod_name ;

commit;