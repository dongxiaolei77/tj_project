-- ----------------------------------------
-- 开发人   : 
-- 开发时间 ：
-- 目标表   ：dwd_sdnd_report_proj_unguar_info     解保记录
-- 源表     ：                                     
--            dwd_guar_info_all                    业务信息宽表--项目域
--            dwd_guar_biz_unguar_info             担保年度业务解保信息表--项目域
--            dwd_sdnd_report_biz_no_base          国担上报范围表
-- 备注     ：
-- 变更记录 ：20240831 增加注释，代码结构优化 WangYX
--            20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl
-- ----------------------------------------
-- 日增量加载
delete from dw_base.dwd_sdnd_report_proj_unguar_info where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_sdnd_report_proj_unguar_info
(
 day_id
,proj_no_prov	-- 省农担担保项目编号
,unguar_amt	    -- 解保金额
,unguar_dt	    -- 解保日期
,unguar_reg_dt	-- 解保登记日期
)
select distinct '${v_sdate}'
	,t1.guar_id					as proj_no_prov
	,t1.loan_amt * 10000 		as unguar_amt			-- 解保金额
	,date(t2.biz_unguar_dt) 	as unguar_dt	        -- 解保日期
	,date(t2.biz_unguar_dt) 	as unguar_reg_dt	    -- 解保登记日期
from dw_base.dwd_guar_info_all t1 -- 业务信息宽表--项目域
left join dw_base.dwd_guar_biz_unguar_info t2 -- 担保年度业务解保信息表--项目域
on t1.guar_id = t2.biz_no
inner join dw_base.dwd_sdnd_report_biz_no_base t3 -- 国担上报范围表
on t1.guar_id = t3.biz_no
and t3.day_id = '${v_sdate}'
where t1.item_stt in ('已解保','已代偿')
;
commit;