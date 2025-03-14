-- ---------------------------------------
-- 开发人   : liyy
-- 开发时间 ：20210311
-- 目标表   :  dwd_agmt_guar_info
-- 源表     ：
--             dwd_agmt_guar_proj_info
--             dwd_agmt_guar_aprv_info
--             dwd_agmt_guar_loan_info
--             dwd_agmt_guar_contn_pay_info
--             dwd_agmt_guar_check_info


-- 变更记录 ：20210422 业务系统放款信息表中只有 本次放款日、本次到期日, 放款日期 部分迁移后没有数据，需要取历史的数据 dwd_guar_info 放款时间、到期时间
--            20211011 1.增加保后检查已终止数据 2.自主续支        
--            20220211统一修改
--            20221101 逻辑变更 wyx
--            20230220 修改2处关联条件，busi_type is null 的也为进件项目，【busi_type = 'ProjectRegister'】 改为 【busi_type = 'ProjectRegister' or busi_type is null】,避免部分数据关联不上取不到值 zhangfl
--            20240102 wyj 修改续支业务93状态为90，补充zzxz业务93状态，别更改为90
--            20241201 脚本的统一变更，MySQL5.0转MySQL8.0并优化逻辑 zhangfl
-- ---------------------------------------
set interactive_timeout = 7200;
set wait_timeout = 7200;
-- -------------------------- 担保明细信息
-- delete from dw_base.dwd_agmt_guar_info ;
truncate  table  dw_base.dwd_agmt_guar_info;
commit ;

-- 1.项目表，首笔放款信息
insert into dw_base.dwd_agmt_guar_info
select
  '${v_sdate}' -- 数据日期
,t1.proj_id -- 项目ID
,t1.proj_no -- 项目编码（粒度合同）
,t1.proj_no -- 项目编号（粒度支用，第一笔和项目编号相同，其余的为XZ项目编号）
,'1'       -- 记录类型1 首笔放款 2续支放款 3 自主循环放款
,t1.source -- 项目来源 01 公司受理 02 银行直报
,t1.province_cd -- 所属省份
,t1.city_cd -- 所属地市
,t1.district_cd -- 所属区县
,t1.guar_class_cd -- 国家农担分类
,t1.econ_class_cd -- 国民经济分类
,t1.main_busi -- 经营主业
,t1.proj_type_cd -- 项目分类 01 首保项目、02 续保项目、 03 续保增额
,t1.proj_cata_cd -- 项目类型 01 产业集群\产业链、02 普通项目、03 灾后重建
,t1.main_type_cd -- 主体类型 01 自然人、02 法人
,t1.cust_type_cd -- 客户类型 01 家庭农场、02 种养大户、03 农民合作社
,t1.cust_id -- 客户id，后续关联到CRM
,t1.cust_name -- 客户名称
,t1.cert_no -- 身份证\统一社会信用码
,t1.tel_no -- 客户手机号
,t1.appl_amt -- 申保金额
,t1.appl_term -- 申保期限
,t1.oppos_guar_cd -- 申保反担保措施 01-无02-抵押03-质押04-保证05-以物抵债00-其他
,t1.oppos_guar_desc -- 申保反担保措施说明
,t1.guar_prod_cd -- 担保产品
,t1.guar_type -- 担保方式: 01 一般保证、02 连带责任保证
,t1.clus_scheme_cd -- 集群方案：项目类型为产业集群时，数据字典
,t1.loan_type -- 贷款方式：0-普通贷款1-自主循环贷（随借随还）2-非自主循环贷（一年一支用）
,t1.repay_type -- 还款方式:普通贷款时，必填。分期付息到期还本、利随本清、等额本金、等额本息01-先息后本02-利随本清03-等额本金04-等额本息05-循环贷06-其他
,t1.loan_rate -- 贷款年利率
,t1.loan_use -- 借款用途
,t1.is_first_loan -- 是否首贷，1是，0否
,t1.is_first_guar -- 是否首保 1是 0否
,t1.is_supp_poor -- 是否扶贫 1是，0否
,t1.loan_bank -- 贷款银行全称(合同章)
,t1.handle_bank -- 经办行(支行/部门)
,t1.bank_mgr_id -- 银行客户经理ID
,t1.bank_mgr_name -- 银行客户经理名称
,t1.bank_mgr_tel -- 银行客户经理联系方式
,t1.bank_mgr_cert_no
,t1.pre_aprv_id -- 预审编号
,t1.pre_aprv_result -- 预审结果，1通过，-1不通过
,t1.version -- 版本
,t1.is_del -- 是否删除:1-删除，0-未删除
,t1.proj_stt -- 项目状态：00-提报中10-审批中20-待签约30-待出函40-待放款50-已放款97-已作废98-已终止99-已否决91-不受理90-已解保
,t1.proj_stt -- 项目状态：00-提报中10-审批中20-待签约30-待出函40-待放款50-已放款97-已作废98-已终止99-已否决91-不受理90-已解保
,t1.proj_orig -- 项目数据来源：01-担保业务系统，02-迁移数据

,t2.busi_type -- 业务类型ProjectRegister 项目提报ProjectXZ 项目续支ProjectCheck 贷后审查
,t2.aprv_no -- 批复编号
,t2.aprv_dt -- 批复日期
,t2.aprv_amt -- 批复金额(万元)
,t2.aprv_term -- 批复期限(月)
,t2.aprv_oppos_guar_cd -- 批复反担保措施 01-无02-抵押03-质押04-保证05-以物抵债00-其他
,t2.aprv_oppos_guar_desc -- 批复反担保措施说明
,t2.guar_rate -- 担保费率
,t2.demand -- 限制性条件或其他
,t2.aprv_sugt -- 批复意见

,t1.loan_cont_id -- 借款合编号
,t1.loan_cont_amt -- 借款合同金额(万元)
,t1.loan_cont_term -- 借款合同期限(月)
,t1.loan_cont_beg_dt -- 借款合同开始日
,t1.loan_cont_end_dt -- 借款合同到期日
,t1.loan_cont_rate -- 借款合同年化利率
,t1.is_sign_max_guar -- 是否已签订最高额度保证合同 1是 0 否
,t1.guar_cont_id -- 单笔保证合同编号

,t3.loan_letter_no -- 放款通知书编号
,t3.loan_letter_dt -- 放款通知书日期
,t3.risk_class -- 五级分类
,t3.debt_no -- 借据编号
,t3.loan_dt -- 放款日期
,t3.loan_amt -- 放款金额
,t3.loan_beg_dt -- 贷款开始日 
,t3.loan_end_dt -- 贷款结束日
,t3.loan_reg_dt -- 放款登记日期
,null -- 解保日期
,0    -- 续支期数
,t1.proj_orig -- 明细项目来源01-担保业务系统，02-迁移数据
,t1.create_dt
,t1.update_dt
,t1.submit_dt
,null
from dw_base.dwd_agmt_guar_proj_info t1      -- 项目信息
left join dw_base.dwd_agmt_guar_aprv_info t2 -- 批复信息
on t1.proj_no = t2.proj_no
and (t2.busi_type = 'ProjectRegister'  or t2.busi_type is null )       -- 20230220 zhangfl
left join dw_base.dwd_agmt_guar_loan_info t3 -- 批复信息
on t1.proj_no = t3.contn_pay_no
and (t3.busi_type = 'ProjectRegister'  
     or t3.busi_type is null  
	  )       -- 限制为放款
where t1.proj_no is not null
;
commit ;

-- 2.项目+批复+签约+loan 续支 续支表做主表，上个状态改为解保

insert into dw_base.dwd_agmt_guar_info
select
  '${v_sdate}' -- 数据日期
,t1.proj_id -- 项目ID
,t1.proj_no -- 项目编码（粒度合同）
,t.contn_pay_no -- 项目编号（粒度支用，第一笔和项目编号相同，其余的为XZ项目编号）
,'2'       -- 记录类型1 首笔放款 2续支放款 3 自主循环放款
,t1.source -- 项目来源 01 公司受理 02 银行直报
,t1.province_cd -- 所属省份
,t1.city_cd -- 所属地市
,t1.district_cd -- 所属区县
,t1.guar_class_cd -- 国家农担分类
,t1.econ_class_cd -- 国民经济分类
,t1.main_busi -- 经营主业
,'04' -- 项目分类 01 首保项目、02 续保项目、 03 续保增额、04续支
,t1.proj_cata_cd -- 项目类型 01 产业集群\产业链、02 普通项目、03 灾后重建
,t1.main_type_cd -- 主体类型 01 自然人、02 法人
,t1.cust_type_cd -- 客户类型 01 家庭农场、02 种养大户、03 农民合作社
,t1.cust_id -- 客户id，后续关联到CRM
,t1.cust_name -- 客户名称
,t1.cert_no -- 身份证\统一社会信用码
,t1.tel_no -- 客户手机号
,t1.appl_amt -- 申保金额
,t1.appl_term -- 申保期限
,t1.oppos_guar_cd -- 申保反担保措施 01-无02-抵押03-质押04-保证05-以物抵债00-其他
,t1.oppos_guar_desc -- 申保反担保措施说明
,t1.guar_prod_cd -- 担保产品
,t1.guar_type -- 担保方式: 01 一般保证、02 连带责任保证
,t1.clus_scheme_cd -- 集群方案：项目类型为产业集群时，数据字典
,t1.loan_type -- 贷款方式：0-普通贷款1-自主循环贷（随借随还）2-非自主循环贷（一年一支用）
,t1.repay_type -- 还款方式:普通贷款时，必填。分期付息到期还本、利随本清、等额本金、等额本息01-先息后本02-利随本清03-等额本金04-等额本息05-循环贷06-其他
,t1.loan_rate -- 贷款年利率
,t1.loan_use -- 借款用途
,t1.is_first_loan -- 是否首贷，1是，0否
,t1.is_first_guar -- 是否首保 1是 0否
,t1.is_supp_poor -- 是否扶贫 1是，0否
,t1.loan_bank -- 贷款银行全称(合同章)
,t1.handle_bank -- 经办行(支行/部门)
,t1.bank_mgr_id -- 银行客户经理ID
,t1.bank_mgr_name -- 银行客户经理名称
,t1.bank_mgr_tel -- 银行客户经理联系方式
,t1.bank_mgr_cert_no
,t1.pre_aprv_id -- 预审编号
,t1.pre_aprv_result -- 预审结果，1通过，-1不通过
,t1.version -- 版本
,t1.is_del -- 是否删除:1-删除，0-未删除
,t1.proj_stt -- 项目状态：00-提报中10-审批中20-待签约30-待出函40-待放款50-已放款97-已作废98-已终止99-已否决91-不受理90-已解保
,case when t.status = '10' then '00'         -- 项目状态：00-提报中10-审批中20-待签约30-待出函40-待放款50-已放款97-已作废98-已终止99-已否决91-不受理90-已解保
      when t.status in ('20','30') then '10' -- 续支状态  10-提报中20-审批中30-待缴费40-待出函50-待放款60-已放款         98-已终止99-已否决
	  when t.status = '40' then '30'
	  when t.status = '50' then '40'
	  when t.status = '60' then '50'
	  when t.status = '93' then '90'  -- mdy 20240102 将续支的代偿状态改为已解保
	  else t.status
	  end
,t1.proj_orig -- 项目数据来源：01-担保业务系统，02-迁移数据

,t2.busi_type -- 业务类型ProjectRegister 项目提报ProjectXZ 项目续支ProjectCheck 贷后审查
,t2.aprv_no -- 批复编号
,t2.aprv_dt -- 批复日期
,coalesce(t.aprv_amt,t2.aprv_amt) -- 批复金额(万元)
,coalesce(t.aprv_term,t2.aprv_term) -- 批复期限(月)
,t2.aprv_oppos_guar_cd -- 批复反担保措施 01-无02-抵押03-质押04-保证05-以物抵债00-其他
,t2.aprv_oppos_guar_desc -- 批复反担保措施说明
,coalesce(t.aprv_rate,t2.guar_rate) -- 担保费率
,t2.demand -- 限制性条件或其他
,t2.aprv_sugt -- 批复意见

,t1.loan_cont_id -- 借款合编号
,t1.loan_cont_amt -- 借款合同金额(万元)
,t1.loan_cont_term -- 借款合同期限(月)
,t1.loan_cont_beg_dt -- 借款合同开始日
,t1.loan_cont_end_dt -- 借款合同到期日
,t1.loan_cont_rate -- 借款合同年化利率
,t1.is_sign_max_guar -- 是否已签订最高额度保证合同 1是 0 否
,t1.guar_cont_id -- 单笔保证合同编号

,t3.loan_letter_no -- 放款通知书编号
,t3.loan_letter_dt -- 放款通知书日期
,t3.risk_class -- 五级分类
,t3.debt_no -- 借据编号
,t3.loan_dt -- 放款日期
,t3.loan_amt -- 放款金额
,t3.loan_beg_dt -- 贷款开始日
,t3.loan_end_dt -- 贷款结束日
,t3.loan_reg_dt -- 放款登记日期
,null -- 解保日期
,t.contn_pay_time -- 续支期数
,'01' -- 明细项目来源 01-担保业务系统，02-迁移数据
,t.create_dt
,t.update_dt
,t.submit_dt
,null
from dw_base.dwd_agmt_guar_contn_pay_info t
left join dw_base.dwd_agmt_guar_proj_info t1 -- 项目信息
on t.proj_no = t1.proj_no
left join dw_base.dwd_agmt_guar_aprv_info t2 -- 批复信息
on t1.proj_no = t2.proj_no
and t2.proj_no is not null
and t2.busi_type = 'ProjectXZ'         -- 限制为放款
left join dw_base.dwd_agmt_guar_loan_info t3 -- 批复信息
on t.contn_pay_no = t3.contn_pay_no
-- and t3.busi_type = 'ProjectXZ'         -- 限制为放款
and t3.contn_pay_no is not null 
where t.proj_no is not null 
;
commit ;


-- 续支成功数据,其他的状态为解保
truncate  table dw_base.dwd_agmt_guar_contn_pay_succ_info ; -- mdy 20221101 wyx

insert into dw_base.dwd_agmt_guar_contn_pay_succ_info
select 
distinct
day_id
,proj_id 
,proj_no
,proj_dtl_no
,contn_pay_time
from dw_base.dwd_agmt_guar_info
where proj_dtl_stt = '50' -- 50-已放款
and rcd_type='2'  -- 2续支放款
;
commit ;

-- 明细项目来源    更新 首笔放款
 update dw_base.dwd_agmt_guar_info t1 
 set t1.proj_dtl_stt ='90' ,
     t1.loan_clsd_dt = t1.loan_end_dt ,
  t1.auto_clsd_flag ='1'
 where t1.rcd_type = '1'
--   and t1.proj_dtl_stt not in ( '91', '97', '98', '99') 已放款的更新为解保
     and t1.proj_dtl_stt = '50'
 and exists (
 select 1 from dw_base.dwd_agmt_guar_contn_pay_succ_info t2 
 where t1.proj_no = t2.proj_no
 and t1.proj_dtl_no <> t2.proj_dtl_no
 )
 ;
commit ;

 -- 明细项目来源  01-担保业务系统 更新第二笔续支
 update dw_base.dwd_agmt_guar_info t1 
 set t1.proj_dtl_stt ='90',
     t1.loan_clsd_dt = t1.loan_end_dt ,
  t1.auto_clsd_flag ='1'
 where  t1.rcd_type='2'   -- 续支
   and t1.proj_dtl_stt = '50'
 and exists (
 select 1 from dw_base.dwd_agmt_guar_contn_pay_succ_info t2 
 where t1.proj_no = t2.proj_no
 and t1.proj_dtl_no <> t2.proj_dtl_no
 and t1.contn_pay_time < t2.contn_pay_time
 )
 ;
commit ;

-- 3 贷后检查表做主表 状态为  03-已确认 上个状态改为解保

insert into dw_base.dwd_agmt_guar_info
select
  '${v_sdate}' -- 数据日期
,t1.proj_id -- 项目ID
,t1.proj_no -- 项目编码（粒度合同）
,t.check_no -- 项目编号（粒度支用，第一笔和项目编号相同，其余的为XZ项目编号）
,'3'       -- 记录类型1 首笔放款 2续支放款 3 自主循环放款
,t1.source -- 项目来源 01 公司受理 02 银行直报
,t1.province_cd -- 所属省份
,t1.city_cd -- 所属地市
,t1.district_cd -- 所属区县
,t1.guar_class_cd -- 国家农担分类
,t1.econ_class_cd -- 国民经济分类
,t1.main_busi -- 经营主业
,'05' -- 项目分类 01 首保项目、02 续保项目、 03 续保增额 04 续支 05 贷后检查-自动转存
,t1.proj_cata_cd -- 项目类型 01 产业集群\产业链、02 普通项目、03 灾后重建
,t1.main_type_cd -- 主体类型 01 自然人、02 法人
,t1.cust_type_cd -- 客户类型 01 家庭农场、02 种养大户、03 农民合作社
,t1.cust_id -- 客户id，后续关联到CRM
,t1.cust_name -- 客户名称
,t1.cert_no -- 身份证\统一社会信用码
,t1.tel_no -- 客户手机号
,t1.appl_amt -- 申保金额
,t1.appl_term -- 申保期限
,t1.oppos_guar_cd -- 申保反担保措施 01-无02-抵押03-质押04-保证05-以物抵债00-其他
,t1.oppos_guar_desc -- 申保反担保措施说明
,t1.guar_prod_cd -- 担保产品
,t1.guar_type -- 担保方式: 01 一般保证、02 连带责任保证
,t1.clus_scheme_cd -- 集群方案：项目类型为产业集群时，数据字典
,t1.loan_type -- 贷款方式：0-普通贷款1-自主循环贷（随借随还）2-非自主循环贷（一年一支用）
,t1.repay_type -- 还款方式:普通贷款时，必填。分期付息到期还本、利随本清、等额本金、等额本息01-先息后本02-利随本清03-等额本金04-等额本息05-循环贷06-其他
,t1.loan_rate -- 贷款年利率
,t1.loan_use -- 借款用途
,t1.is_first_loan -- 是否首贷，1是，0否
,t1.is_first_guar -- 是否首保 1是 0否
,t1.is_supp_poor -- 是否扶贫 1是，0否
,t1.loan_bank -- 贷款银行全称(合同章)
,t1.handle_bank -- 经办行(支行/部门)
,t1.bank_mgr_id -- 银行客户经理ID
,t1.bank_mgr_name -- 银行客户经理名称
,t1.bank_mgr_tel -- 银行客户经理联系方式
,t1.bank_mgr_cert_no
,t1.pre_aprv_id -- 预审编号
,t1.pre_aprv_result -- 预审结果，1通过，-1不通过
,t1.version -- 版本
,t1.is_del -- 是否删除:1-删除，0-未删除
,t1.proj_stt -- 项目状态：00-提报中10-审批中20-待签约30-待出函40-待放款50-已放款97-已作废98-已终止99-已否决91-不受理90-已解保
,case when check_stt = '03' then '50'
	  when check_stt = '93' then '90'  -- mdy 20240102续支业务已代偿改为已解保
      else check_stt 
      end	  -- 项目状态：00-提报中10-审批中20-待签约30-待出函40-待放款50-已放款97-已作废98-已终止99-已否决91-不受理90-已解保
              -- mdy 20211011	  
,t1.proj_orig -- 项目数据来源：01-担保业务系统，02-迁移数据

,t2.busi_type -- 业务类型ProjectRegister 项目提报ProjectXZ 项目续支ProjectCheck 贷后审查
,'' -- 批复编号
,t.guar_beg_dt -- 批复日期
,t.guar_amt -- 批复金额(万元)
,t2.aprv_term -- 批复期限(月)
,t2.aprv_oppos_guar_cd -- 批复反担保措施 01-无02-抵押03-质押04-保证05-以物抵债00-其他
,t2.aprv_oppos_guar_desc -- 批复反担保措施说明
,coalesce(t.guar_rate,t2.guar_rate) -- 担保费率
,t2.demand -- 限制性条件或其他
,t2.aprv_sugt -- 批复意见

,t1.loan_cont_id -- 借款合编号
,t1.loan_cont_amt -- 借款合同金额(万元)
,t1.loan_cont_term -- 借款合同期限(月)
,t1.loan_cont_beg_dt -- 借款合同开始日
,t1.loan_cont_end_dt -- 借款合同到期日
,t1.loan_cont_rate -- 借款合同年化利率
,t1.is_sign_max_guar -- 是否已签订最高额度保证合同 1是 0 否
,t1.guar_cont_id -- 单笔保证合同编号

,t3.loan_letter_no -- 放款通知书编号 -- mdy 20211011 增加放款通知书信息
,t3.loan_letter_dt -- 放款通知书日期 -- mdy 20211011 增加放款通知书信息
,t3.risk_class -- 五级分类
,t3.debt_no -- 借据编号
,t.guar_beg_dt -- 放款日期
,t.guar_amt -- 放款金额
,t.guar_beg_dt -- 贷款开始日
,t.guar_end_dt -- 贷款结束日
,t.guar_beg_dt -- 放款登记日期
,null -- 解保日期
,0 -- 续支期数
,'01' -- 明细项目来源01-担保业务系统，02-迁移数据
,t.create_dt
,t.update_dt
,t.submit_dt
,null
from dw_base.dwd_agmt_guar_check_info t  -- 自主循环贷
left join dw_base.dwd_agmt_guar_proj_info t1 -- 项目信息
on t.proj_no = t1.proj_no
left join dw_base.dwd_agmt_guar_aprv_info t2 -- 批复信息
on t1.proj_no = t2.proj_no
and t2.proj_no is not null
and (t2.busi_type = 'ProjectRegister'
     or t2.busi_type is null 
	 )         -- 限制为放款
left join dw_base.dwd_agmt_guar_loan_info t3 -- 批复信息
on t.check_no = t3.contn_pay_no
and (t3.busi_type = 'ProjectRegister'  or t3.busi_type is null)       -- 20230220 zhangfl
and t3.contn_pay_no is not null
where t.check_stt  in( '03','93','98','99','90')  --  mdy 20211011 只登记已确认 已终止 已否决 01-登记中 02-确认中 03-已确认 98-已终止 99-已否决  -- mdy 20240102 增加93 已代偿
and t.check_type = '02'
and t.proj_no is not null
;
commit ;


-- 更新自主循环贷数据   自主循环贷成功数据,其他的状态为解保
truncate  table dw_base.dwd_agmt_guar_check_succ_info ; -- mdy 20221101 wyx

insert into dw_base.dwd_agmt_guar_check_succ_info
select 
distinct
day_id
,proj_id 
,proj_no
,proj_dtl_no
,loan_beg_dt
from dw_base.dwd_agmt_guar_info
where proj_dtl_stt = '50' -- 50-已放款
and rcd_type='3'  -- 3 自主循环放款
;
commit ;


-- 明细项目来源    更新 首笔放款
 update dw_base.dwd_agmt_guar_info t1 
 set t1.proj_dtl_stt ='90' ,
     t1.loan_clsd_dt = t1.loan_beg_dt ,
  t1.auto_clsd_flag ='1'
 where t1.rcd_type = '1'
 and  t1.proj_dtl_stt = '50'
 and exists (
 select 1 from dw_base.dwd_agmt_guar_check_succ_info t2 
 where t1.proj_no = t2.proj_no
 and t1.proj_dtl_no <> t2.proj_dtl_no
 )
 ;
commit ;

 -- 明细项目来源  01-担保业务系统 更新 自主循环放款
 update dw_base.dwd_agmt_guar_info t1 
 set t1.proj_dtl_stt ='90',
     t1.loan_clsd_dt = t1.loan_beg_dt ,
  t1.auto_clsd_flag ='1'
 where t1.proj_dtl_orig = '01'
 and t1.rcd_type='3'   --  自主循环放款
 and t1.proj_dtl_stt = '50'
 and exists (
 select 1 from dw_base.dwd_agmt_guar_check_succ_info t2 
 where t1.proj_no = t2.proj_no
 and t1.proj_dtl_no <> t2.proj_dtl_no
 and t1.loan_beg_dt < t2.loan_beg_dt  -- 放款日期
 )
 ;
commit ;

