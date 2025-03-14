   -- ---------------------------------------
-- 开发人   : xueguangmin
-- 开发时间 ：20220117
-- 目标表   ：dw_base.dwd_fin_loan_ac_dxretustatfee 客户当前保费逾期信息 
-- 源表     ：dw_nd.ods_gcredit_loan_ac_dxretustatfee 费用回收状态信息文件
-- 变更记录 ： 20220117:统一变动   
--             20220516 日志变量注释  xgm  
--             20241201 脚本的统一变更，MySQL5.0转MySQL8.0 zhangfl   
-- ---------------------------------------
-- 客户逾期信息-- 当前逾期 -- 保费

truncate table dw_base.dwd_fin_loan_ac_dxretustatfee;
insert into dw_base.dwd_fin_loan_ac_dxretustatfee
(
   drawndn_seqno , -- 客户编号 
   over_fee  , -- 拖欠保费
   over_days  -- 保费逾期天数 
)
select drawndn_seqno,over_fee,over_days
from  (
	select a.drawndn_seqno
		  ,dqyqje as over_fee 
		  ,dqyqts as over_days
	from ( 
			select  a.retustat_id
					,a.drawndn_seqno
					,schdu_fee-repay_fee as dqyqje 
					,'${v_sdate}' as dqyqts 
					,row_number()over(partition by drawndn_seqno order by update_time desc ) rn
			from dw_nd.ods_gcredit_loan_ac_dxretustatfee a  
			where   creator<>'担保业务管理系统' 
				and date_format(update_time,'%Y%m%d') <=  '${v_sdate}'
			) a
	where rn = 1
	) a 
where over_fee<>0  ;
commit; 