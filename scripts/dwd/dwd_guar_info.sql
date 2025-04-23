-- 开发人   : liyy
-- ---------------------------------------
-- 开发时间 ：20210414
-- 目标表   ： dw_base.dwd_guar_info_all
--             dw_base.dwd_guar_info_stat
--             dw_base.dwd_guar_info_new_busi
--             dw_base.dwd_guar_info_all_his
--             dw_base.dwd_guar_mgr_info
-- 源表     ：dw_nd.ods_t_proj_comp_aply               代偿申请表
--            dw_nd.ods_gcredit_customer_base          客户基本信息表
--            dw_nd.ods_t_sys_data_dict_value_v2       数据字典值表
--            dw_base.dwd_agmt_guar_info               担保信息明细
--            dw_nd.ods_gcredit_loan_ac_dxloanbookfee  费用交易流水信息文件
--            dw_nd.ods_bizhall_guar_online_biz        标准化线上业务台账表
--            dw_nd.ods_bizhall_guar_apply             业务大厅申请信息表
--            dw_nd.ods_bizhall_apply_base_info        申请基本信息表
--            dw_nd.ods_t_biz_project_main             主项目表（进件表）
--            dw_base.dwd_guar_cont_info_all           担保年度项目表
--            dw_nd.ods_t_biz_proj_xz                  续支项目表
--            dw_nd.ods_t_biz_proj_loan_check          贷后检查表（取自主续支项目）
--            dw_nd.ods_t_biz_proj_unguar	           解保项目表
--            dw_nd.ods_t_proj_comp_appropriation      拨付信息表
--            dw_base.dwd_mgr_info                     客户经理信息
--            dw_base.dwd_evt_wf_task_info             工作流审批表
--            dw_nd.ods_t_sys_user                     新业务中台用户信息表
--            dw_base.dim_area_info/dim_cust_type/dim_cust_class/dim_guar_class/dim_bank_info/dim_econ_info/dim_econ_pl_map/dim_item_stt 行政区划码表/主体类型码表/客户类型码表/国担分类码表/银行部门表/国民经济码表/国民经济品类映射表/项目状态码表（数仓）

-- 变更记录 ：20241201 脚本的统一变更，MySQL5.0转MySQL8.0并优化逻辑 zhangfl
-- ---------------------------------------

-- 代偿标志
drop table if exists dw_base.tmp_dwd_guar_info_compt ;
commit ;
create  table dw_base.tmp_dwd_guar_info_compt
(
guar_id   varchar(60) comment '客户编号'
,is_compt varchar(1)  comment '代偿标志 1 代偿 0 未代偿'
,key ( guar_id )
) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;
commit ;
insert into dw_base.tmp_dwd_guar_info_compt
select	guar_id
		,is_compt
from
(
	select	proj_code as guar_id
			,'1' as is_compt
			,status
			,row_number()over(partition by proj_code order by db_update_time desc) rn
	from dw_nd.ods_t_proj_comp_aply
) t
where t.rn = 1
and t.status = '50' -- '已代偿'

-- select
-- distinct seq_id
-- ,'1'
-- from 
-- (
-- select seq_id 
-- from dw_nd.ods_imp_portrait_info_new
-- where s_risk_stt = '已代偿' 
-- ) t
;
commit ;


-- 客户号
drop table if exists dw_base.tmp_dwd_guar_info_cust ;
commit;

create table dw_base.tmp_dwd_guar_info_cust
(
cust_id varchar(50) comment '业务系统客户号'
,cert_no varchar(50) comment '客户证件号'
,index idx_tmp_dwd_guar_info_cust_cert ( cert_no ) 
) engine=innodb  default charset=utf8mb4 collate=utf8mb4_bin row_format=dynamic ;
commit;

insert into dw_base.tmp_dwd_guar_info_cust
select	customer_id
		,upper(id_no)
from
(
	select	a.customer_id
			,a.id_no
			,row_number()over(partition by a.id_no order by a.update_time desc) rn
	from dw_nd.ods_gcredit_customer_base a
) t
where t.rn = 1
;
commit ;


-- 新业务中台
-- 担保业务平台续支业务上线
drop table if exists dw_tmp.tmp_guar_info_econ_info_01; commit;
create table if not exists dw_tmp.tmp_guar_info_econ_info_01
(
dict_code               varchar(100) comment '字典码值'
,code                   varchar(100) comment '字典值编码'
,value                  varchar(100) comment '字典值'
,parent_dict_value_code varchar(100) comment '父字典值编码'
,index idx_tmp_guar_info_econ_info_01_dict_code(dict_code)
,index idx_tmp_guar_info_econ_info_01_parent_code(parent_dict_value_code)
);
commit;

insert into dw_tmp.tmp_guar_info_econ_info_01 
select	dict_code
		,code
		,value
		,parent_dict_value_code
from
(
	select	id
			,dict_code
			,code
			,value
			,parent_dict_value_code
			,row_number()over(partition by code order by update_time desc) rn
	from dw_nd.ods_t_sys_data_dict_value_v2
	where dict_code like '%gbt%'
)t
where t.rn = 1
;
commit;


-- 业务对应的国民经济分类
drop table if exists dw_base.tmp_dwd_guar_info_econ ;
commit;

create  table dw_base.tmp_dwd_guar_info_econ(
   proj_dtl_no     varchar(100)  ,
   econ_class_cd   varchar(100)  ,
   econ_class_desc varchar(100)  ,
INDEX  (proj_dtl_no) 
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;

insert into dw_base.tmp_dwd_guar_info_econ
select
proj_dtl_no
,econ_class_cd
,t2.value
from
(
	select	proj_dtl_no
			,case when length(econ_class_cd)='23' then substr(econ_class_cd,18,4)        
				when length(econ_class_cd)='16' then substr(econ_class_cd,12,3)       --  更改截取字段的位置 20211104  
				when length(econ_class_cd)='10' then substr(econ_class_cd,7,2)        --  更改截取字段的位置
				else substr(econ_class_cd,3,1)                                        -- 更改截取字段的位置
			end econ_class_cd
	from dw_base.dwd_agmt_guar_info
) t1 
left join dw_tmp.tmp_guar_info_econ_info_01  t2                           
on t1.econ_class_cd = t2.code
;
commit ;	  


-- 产业集群
drop table if exists dw_base.tmp_dwd_guar_info_new_busi_value_v2 ;
commit;

create  table dw_base.tmp_dwd_guar_info_new_busi_value_v2(
   code varchar(100)  ,
   dict_code  varchar(100)  ,
   value varchar(1024)  ,
   INDEX  (code) 
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;

insert into dw_base.tmp_dwd_guar_info_new_busi_value_v2
select	code
		,dict_code
		,value
from
(
	select	code
			,dict_code
			,value
			,update_time
			,row_number()over(partition by code,dict_code order by update_time desc ) rn
	from dw_nd.ods_t_sys_data_dict_value_v2 
) t
where t.rn = 1
;
commit ;


-- 20211029
-- 保费

drop table if exists dw_base.tmp_dwd_guar_info_new_busi_fee ;
commit;

create  table dw_base.tmp_dwd_guar_info_new_busi_fee(
   guar_id varchar(100)  ,
   guar_fee decimal(18,2) ,
   INDEX  (guar_id) 
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;

insert into dw_base.tmp_dwd_guar_info_new_busi_fee
select drawndn_seqno
,repay_fee
from 
(
	select	drawndn_seqno
			,repay_fee  -- 实还费用
			,update_time
			,row_number()over(partition by drawndn_seqno order by update_time desc ) rn
	from dw_nd.ods_gcredit_loan_ac_dxloanbookfee
	where status not in ( '3','4') -- 1-交易完成，2-交易中，3-已退款，4-已取消
	and repay_mode ='01'
) t
where t.rn = 1
;
commit ;

truncate table dw_base.dwd_guar_info_new_busi ;
commit ;

insert into dw_base.dwd_guar_info_new_busi
select
t1.day_id                    -- 数据日期
,t1.proj_dtl_no -- 台账编号
,cust_id -- 客户号
,null -- 提单人
,null -- 提单人部门
,null -- 表单标题
,null -- 审批结果
,null -- 当前节点
,coalesce(t16.area_name, t3.sup_area_name) -- 城市 -- 20230224 zhangfl
,t1.city_cd	-- 城市编码
,t3.area_name -- 区县
,t1.district_cd -- 区县编码
,t4.value	  -- 客户类型
,t5.value -- 客户分类
,cust_name -- 客户名称
,cert_no -- 身份证号
,tel_no -- 联系电话
,t6.value -- 国担分类
,t11.econ_class_desc  -- 国民经济分类
,loan_use -- 借款用途
,t7.value -- 担保产品
,t8.value -- 集群方案
,case when is_first_loan ='1' then '是' 
      when is_first_loan ='0' then '否' 
      end	  -- 是否首贷
,case when is_first_guar ='1' then '是' 
      when is_first_guar ='0' then '否' 
      end  is_first_guar -- 是否首保
,case when is_supp_poor ='1' then '是' 
      when is_supp_poor ='0' then '否' 
      end is_supp_poor -- 是否扶贫
,case when loan_type= '0' then '0'
      when loan_type in ('1','2') then '0'
	  end loan_type -- 是否循环贷   -- 0-普通贷款1-自主循环贷（随借随还）2-非自主循环贷（一年一支用）
,case when bank_name like '%农业银行%' then '农业银行'
      when bank_name like '%邮政储蓄%' or bank_name like '%邮储%' then '邮储银行'
      when bank_name like '%农村商业%' or bank_name like '%农商%' then '农商银行'
      else '其他银行' end as bank_type -- 银行分类
,coalesce(t9.bank_name,t1.handle_bank) as loan_bank -- 贷款银行 -- mdy 20220523 wyx
,t1.handle_bank as loan_bank_id
,bank_mgr_name -- 银行客户经理
,null -- 项目主调
,null -- 项目辅调
,contn_pay_time -- 续支期数
,aprv_amt -- 批复金额
,aprv_term -- 批复期限
,oppos_guar_desc -- 反担保措施
,main_busi -- 经营主业备注
,loan_cont_id -- 贷款合同编号
,loan_cont_amt -- 贷款合同金额
,t1.loan_cont_rate -- 贷款合同利率
,loan_cont_term -- 贷款合同期限
,null    -- 合同期限备注
,date_format(loan_beg_dt,'%Y%m%d') -- 贷款开始时间
,date_format(loan_end_dt,'%Y%m%d') -- 贷款结束时间
,t10.value -- 合同还款类型
,null -- 委保合同编号
,guar_cont_id -- 保证合同编号（最高额担保合同）
,t1.guar_rate -- 担保费率
,loan_letter_no -- 放款通知书编号
,date_format(loan_letter_dt,'%Y%m%d') -- 放款通知书日期 20211011
,t1.loan_amt -- 放款金额
,date_format(loan_beg_dt,'%Y%m%d') -- 首笔放款日期
,date_format(loan_end_dt,'%Y%m%d') -- 责任到期日
,date_format(loan_end_dt,'%Y%m%d') -- 责任解除日
,null -- 
,'担保业务管理系统新' -- 数据来源
, 
case -- when t12.guar_id is not null  then '已解保'
     when proj_dtl_stt = '00' then '提报中'
     when proj_dtl_stt = '10' then '审批中'
	 when proj_dtl_stt = '20' then '待签约'
	 when proj_dtl_stt = '30' then '待出函'
	 when proj_dtl_stt = '40' then '待放款'
	 when proj_dtl_stt = '50' then '已放款'
	 when proj_dtl_stt = '97' then '已作废'
	 when proj_dtl_stt = '98' then '已终止'
	 when proj_dtl_stt = '99' then '已否决'
	 when proj_dtl_stt = '91' then '不受理'
	 when proj_dtl_stt = '90' then '已解保'
	 when proj_dtl_stt = '92' then '超期终止'   -- 业务数据项目状态添加“超期终止”   20211122
	 when proj_dtl_stt = '93' then '已代偿'
	 end  proj_dtl_stt -- 项目状态
,null -- 双控政策
,null -- 贴息政策
,risk_class -- 五级分类
,null -- 数据校准员
,null -- 数据是否核对
, null-- 数据描述
,appl_amt -- 申保金额（万元）
,aprv_amt -- 初审金额（万元）
,t15.guar_fee -- 保费金额
,null -- 保费银行卡号
,null -- 保费银行卡开户行
,date_format(update_dt,'%Y%m%d') -- 操作时间
,date_format(create_dt,'%Y%m%d') -- 提单时间
,date_format(submit_dt,'%Y%m%d') -- 受理时间(提报时间)
,date_format(aprv_dt,'%Y%m%d') -- 批复日期
,date_format(loan_letter_dt,'%Y%m%d') -- 出函时间
,date_format(loan_dt,'%Y%m%d') -- 放款时间
,null -- 是否在审在保
,null -- 是否关闭
,null -- 是否解保
,null -- 是否退审
,coalesce(t14.is_compt,'0') -- 是否代偿
,null -- 是否逾期
,null -- 逾期天数
,date_format(loan_reg_dt,'%Y%m%d') -- 放款登记日期
from dw_base.dwd_agmt_guar_info t1 
left join dw_base.dim_area_info t3  -- mdy 20220518 wyx
on t1.district_cd = t3.area_cd
and t3.area_lvl = '3'
left join dw_base.dim_cust_type t4 
on t1.main_type_cd = t4.code
left join dw_base.dim_cust_class t5
on t1.cust_type_cd = t5.code
left join dw_base.dim_guar_class t6
on t1.guar_class_cd = t6.code
left join dw_base.tmp_dwd_guar_info_new_busi_value_v2 t7 -- 取产品类型字典
on t1.guar_prod_cd = t7.code
and t7.dict_code = 'productWarranty'
left join dw_base.tmp_dwd_guar_info_new_busi_value_v2 t8 -- 集群方案
on t1.clus_scheme_cd = t8.code
and t8.dict_code ='aggregateScheme'
left join dw_base.dim_bank_info t9 -- mdy 20220523 wyx
on t1.handle_bank = t9.bank_id
left join dw_base.tmp_dwd_guar_info_new_busi_value_v2 t10 
on t1.repay_type= t10.code
and t10.dict_code ='repaymentMethod'
left join dw_base.tmp_dwd_guar_info_econ t11
on t1.proj_dtl_no = t11.proj_dtl_no

left join dw_base.tmp_dwd_guar_info_compt t14
on t1.proj_dtl_no =t14.guar_id
left join dw_base.tmp_dwd_guar_info_new_busi_fee t15
on t1.proj_dtl_no = t15.guar_id
left join dw_base.dim_area_info t16  -- mdy 20230224 zhangfl
on t1.city_cd = t16.area_cd and t16.area_lvl = '2'
;
commit;

-- 更新状态
update  dw_base.dwd_guar_info_new_busi t1
,dw_base.tmp_dwd_guar_info_cust t2
set t1.cust_id = t2.cust_id
where t1.cert_no = t2.cert_no
;
commit;
-- 更新状态
update dw_base.dwd_guar_info_new_busi set item_stt ='已否决'
where aprv_amt =0 and data_source = '担保业务管理系统新' and item_stt ='待签约'
;
commit;



-- 所有台账信息 
truncate table dw_base.dwd_guar_info_all ;
commit;

-- 1.插入新台账 续支上线后的数据
insert into dw_base.dwd_guar_info_all
(day_id
,guar_id
,cust_id
,creator
,creator_dep
,form_title
,aprv_result
,cur_node_name
,city_name
,city_code
,county_name
,country_code
,town_name
,village_name
,cust_type
,cust_class
,cust_name
,cert_no
,tel_no
,guar_class
,econ_class
,loan_use
,guar_prod
,clus_scheme
,is_first_loan
,is_first_guar
,is_supp_poor
,is_circ_loan
,bank_class
,loan_bank
,loan_bank_id
,bank_mgr
,mgr_a
,mgr_b
,goon_term
,aprv_amt
,aprv_term
,protect_guar
,remark
,loan_no
,loan_amt
,loan_rate
,loan_term
,cont_term_remark
,loan_begin_dt
,loan_end_dt
,repay_type
,trust_cont_no
,guar_cnot_no
,guar_rate
,loan_notify_no
,loan_notify_dt
,guar_amt
,first_loan_dt
,due_dt
,relieve_dt
,guar_manager
,data_source
,item_stt
,contr_policy
,discnt_policy
,risk_class
,data_check
,is_check
,data_desc
,appl_amt
,first_aprv_amt
,guar_fee
,card_no
,bank_no
,opera_tm
,create_dt
,accept_dt
,aprv_dt
,notify_dt
,grant_dt
,is_work
,is_close
,is_remove
,is_reject
,is_compensate
,is_ovd
,ovd_days
,loan_reg_dt)
select 
day_id
,guar_id
,cust_id
,creator
,creator_dep
,form_title
,aprv_result
,cur_node_name
,city_name
,city_code
,county_name
,country_code
,null as town_name
,null as village_name
,cust_type
,cust_class
,cust_name
,cert_no
,tel_no
,guar_class
,econ_class
,loan_use
,guar_prod
,clus_scheme
,is_first_loan
,is_first_guar
,is_supp_poor
,is_circ_loan
,case when loan_bank like '%农业银行%' then '农业银行'
      when loan_bank like '%邮政储蓄%' or loan_bank like '%邮储%' then '邮储银行'
      when loan_bank like '%农村商业%' or loan_bank like '%农商%' then '农商银行'
	  when loan_bank like '%建设%' or loan_bank like '%建行%' then '建设银行'
	  when loan_bank like '%工商%' or loan_bank like '%工行%' then '工商银行'
	  when loan_bank like '%齐鲁%' then '齐鲁银行'
	  when loan_bank like '%齐商%' then '齐商银行'
	  when loan_bank like '%中国银行%' then '中国银行'
	  when loan_bank like '%兴业%' then '兴业银行'
	  when loan_bank like '%恒丰%' then '恒丰银行'
	  when loan_bank like '%交通%' then '交通银行'
	  when loan_bank like '%华夏%' then '华夏银行'
      else '其他银行' end as bank_class -- 银行分类 -- mdy 20231013 wyx
,loan_bank
,loan_bank_id
,bank_mgr
,mgr_a
,mgr_b
,goon_term
,aprv_amt
,aprv_term
,protect_guar
,remark
,loan_no
,loan_amt
,loan_rate
,loan_term
,cont_term_remark
,loan_begin_dt
,loan_end_dt
,repay_type
,trust_cont_no
,guar_cnot_no
,guar_rate
,loan_notify_no
,loan_notify_dt
,guar_amt
,first_loan_dt
,due_dt
,relieve_dt
,guar_manager
,data_source
,item_stt
,contr_policy
,discnt_policy
,risk_class
,data_check
,is_check
,data_desc
,appl_amt
,first_aprv_amt
,guar_fee
,card_no
,bank_no
,opera_tm
,create_dt
,accept_dt
,aprv_dt
,notify_dt
,grant_dt
,is_work
,is_close
,is_remove
,is_reject
,is_compensate
,is_ovd
,ovd_days
,loan_reg_dt
from dw_base.dwd_guar_info_new_busi
;
commit ;



-- 2.线上业务切源 -- 20231109 wyx
-- 标准线上业务台账数据的国民经济分类/国家农担分类处理 zhangfl 20231214
drop table if exists dw_tmp.tmp_dwd_guar_info_all_online_biz_econ ;
commit;

create table dw_tmp.tmp_dwd_guar_info_all_online_biz_econ(
 apply_code        varchar(64)  comment '业务编号'
,econ_code         varchar(10)  comment '国民经济分类编码'
,econ_name         varchar(300) comment '国民经济分类名称'
,guar_code         varchar(10)  comment '国家农担分类编码'
,guar_name         varchar(100) comment '国家农担分类名称'
,index idx_tmp_dwd_guar_info_all_online_biz_econ_ap(apply_code)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin comment='标准线上业务台账数据的国民经济分类/国家农担分类编码';
commit;

insert into dw_tmp.tmp_dwd_guar_info_all_online_biz_econ
select t1.apply_code
,t1.econ_code
,t2.econ_name
,t1.guar_code
,t3.value as guar_name
from
(
	select	t1.apply_code
			,coalesce(t1.econ_code, t2.econ_code) as econ_code
			,coalesce(t1.guar_code, t1.guar_code) as guar_code
	from 
	(
		select	t.apply_code
				,substring_index(substring_index(concat(national_economy_classify,','), ',', 1), '/', -1) as econ_code
				,substring_index(concat(national_guarantee_classify,','), ',', 1) as guar_code
		from
		(
			select apply_code,national_economy_classify,national_guarantee_classify, row_number()over(partition by apply_code order by update_time desc) rn
			from dw_nd.ods_bizhall_guar_online_biz 
			where push_after_loan= '1'
		) t 
		where t.rn = 1
	) t1
    
	left join 
	(
		select	t.apply_code
				,substring_index(substring_index(concat(national_economy_classify,','), ',', 1), '/', -1) as econ_code
				,substring_index(concat(national_guarantee_classify,','), ',', 1) as guar_code
		from
		(
			select apply_code,national_economy_classify,national_guarantee_classify, row_number()over(partition by apply_code order by update_time desc) rn
			from dw_nd.ods_bizhall_guar_apply
		) t 
		where t.rn = 1
	) t2
	on t1.apply_code = t2.apply_code
) t1

left join dw_base.dim_econ_info t2
on t1.econ_code = t2.econ_cd

left join dw_base.dim_guar_class t3
on t1.guar_code = t3.code
;
commit;

insert into dw_base.dwd_guar_info_all
(day_id
,guar_id
,cust_id
,creator
,creator_dep
,form_title
,aprv_result
,cur_node_name
,city_name
,city_code
,county_name
,country_code
,town_name
,village_name
,cust_type
,cust_class
,cust_name
,cert_no
,tel_no
,guar_class
,econ_class
,loan_use
,guar_prod
,clus_scheme
,is_first_loan
,is_first_guar
,is_supp_poor
,is_circ_loan
,bank_class
,loan_bank
,loan_bank_id
,bank_mgr
,mgr_a
,mgr_b
,goon_term
,aprv_amt
,aprv_term
,protect_guar
,remark
,loan_no
,loan_amt
,loan_rate
,loan_term
,cont_term_remark
,loan_begin_dt
,loan_end_dt
,repay_type
,trust_cont_no
,guar_cnot_no
,guar_rate
,loan_notify_no
,loan_notify_dt
,guar_amt
,first_loan_dt
,due_dt
,relieve_dt
,guar_manager
,data_source
,item_stt
,contr_policy
,discnt_policy
,risk_class
,data_check
,is_check
,data_desc
,appl_amt
,first_aprv_amt
,guar_fee
,card_no
,bank_no
,opera_tm
,create_dt
,accept_dt
,aprv_dt
,notify_dt
,grant_dt
,is_work
,is_close
,is_remove
,is_reject
,is_compensate
,is_ovd
,ovd_days
,loan_reg_dt)
select 
-- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d')      -- 数据日期
'${v_sdate}'
,t1.apply_code    -- 台账编号
,t1.cust_code     -- 客户号
,null             -- 提单人
,null             -- 提单人部门
,null             -- 表单标题
,null             -- 审批结果
,null             -- 当前节点
,t4.sup_area_name -- 城市
,t4.sup_area_cd
,t4.area_name     -- 区县
,t4.area_cd
,t5.sup_area_name -- 乡镇
,t5.area_name     -- 村庄
,t9.value         -- 客户类型
,t6.value         -- 客户分类
,t1.cust_name     -- 客户名称
,t1.cust_id_no    -- 身份证号
,t1.cust_mobile   -- 联系电话
,t0.guar_name     -- t8.guar_class    -- 国担分类                            -- 调整直接从 线上标准台账 出 20231214
,t0.econ_name     -- SUBSTRING_INDEX(econ_class_lv4,'/',-1)  -- 国民经济分类 -- 调整直接从 线上标准台账 出 20231214
,t2.apply_use     -- 借款用途
,t1.product_name  -- 担保产品
,null             -- 集群方案
,null             -- 是否首贷
,t2.first_guar    -- 是否首保
,null             -- 是否扶贫
,null             -- 是否循环贷
,case when t1.loan_bank like '%农业银行%' then '农业银行'
      when t1.loan_bank like '%邮政储蓄%' or t1.loan_bank like '%邮储%' then '邮储银行'
      when t1.loan_bank like '%农村商业%' or t1.loan_bank like '%农商%' then '农商银行'
	  when t1.loan_bank like '%建设%' or t1.loan_bank like '%建行%' then '建设银行'
	  when t1.loan_bank like '%工商%' or t1.loan_bank like '%工行%' then '工商银行'
	  when t1.loan_bank like '%齐鲁%' then '齐鲁银行'
	  when t1.loan_bank like '%齐商%' then '齐商银行'
	  when t1.loan_bank like '%中国银行%' then '中国银行'
	  when t1.loan_bank like '%兴业%' then '兴业银行'
	  when t1.loan_bank like '%恒丰%' then '恒丰银行'
	  when t1.loan_bank like '%交通%' then '交通银行'
	  when t1.loan_bank like '%华夏%' then '华夏银行'
      else '其他银行' end as bank_class -- 银行分类
,t1.loan_bank      -- 贷款银行
,t1.loan_bank_id   -- 贷款银行机构id
,t2.bank_manager_name -- 银行客户经理
,null              -- 项目主调
,null              -- 项目辅调
,null              -- 续支期数
,t2.reply_amount   -- 批复金额
,t2.reply_period   -- 批复期限
,t2.counter_des    -- 反担保措施
,t8.econ_class_lv4 -- 经营主业备注
,t1.loan_contract_no  -- 贷款合同编号
,t1.final_credit_limit/10000       -- 贷款合同金额
,0 + cast(t1.bank_rate as char)      -- 贷款合同利率
,0 + cast(t1.loan_period as char)    -- 贷款合同期限
,null              -- 合同期限备注
,date_format(t1.loan_start,'%Y%m%d')     -- 贷款开始时间
,date_format(t1.loan_end,'%Y%m%d')       -- 贷款结束时间
,t2.bank_loan_back_type -- 合同还款类型
,null              -- 委保合同编号
,null              -- 保证合同编号（最高额担保合同）
,0 + cast(t1.fee_rate as char)       -- 担保费率
,t2.ele_guar_code  -- 放款通知书编号
,date_format(t1.loan_start,'%Y%m%d')   -- 放款时间（放款通知书日期）
,t1.loan_amt/10000       -- 放款金额
,date_format(t1.loan_start,'%Y%m%d')  -- 首笔放款日期
,date_format(t1.loan_end,'%Y%m%d')    -- 责任到期日
,date_format(t1.loan_end,'%Y%m%d')    -- 责任解除日
,null              -- guar_manager
,'标准线上业务台账' -- 数据来源   edit by bingk   修正为线上业务标准台账
,case when t1.busi_status <> '43' and t1.push_after_loan= '1' then '已放款' 
      when t1.busi_status = '43' and t1.push_after_loan= '1'then '已解保' 
      else '提报中' end -- 项目状态
,null              -- 双控政策
,null              -- 贴息政策
,null              -- 五级分类
,null              -- 数据校准员
,null              -- 数据是否核对
,null              -- 数据描述
,t2.apply_amt      -- 申保金额（万元）
,t2.reply_amount   -- 初审金额（万元）
,t2.trial_fee      -- 保费金额       -- 保费试算金额 -- 要确认对不对
,null              -- 保费银行卡号
,null              -- 保费银行卡开户行
,date_format(t1.update_time,'%Y%m%d') -- 操作时间
,date_format(t1.create_time,'%Y%m%d') -- 提单时间
,date_format(t1.apply_time,'%Y%m%d')  -- 受理时间
,date_format(t1.apply_time,'%Y%m%d')  -- 批复日期
,date_format(t1.apply_time,'%Y%m%d')  -- 出函时间（放款通知书日期）
,date_format(t1.loan_start,'%Y%m%d')   -- 放款时间
,null              -- 是否在审在保
,null              -- 是否关闭
,case when t1.busi_status = '43' then '是' else '否' end -- 是否解保
,null              -- 是否退审
,null              -- 是否代偿
,case when t1.repay_status = '2' then '是' else '否' end -- 是否逾期
,null              -- 逾期天数
,date_format(t1.loan_start,'%Y%m%d')   -- 放款登记日期
from
(
	select *
	from
	(
		select *, row_number()over(partition by apply_code order by update_time desc) rn
		from dw_nd.ods_bizhall_guar_online_biz
		where push_after_loan= '1'
	) t
	where t.rn = 1
) t1
inner join dw_tmp.tmp_dwd_guar_info_all_online_biz_econ t0 -- 国民经济分类/国担分类直取
on t1.apply_code = t0.apply_code
inner join 
(
	select *
	from
	(
		select *, row_number()over(partition by apply_code order by update_time desc) rn
		from dw_nd.ods_bizhall_guar_apply
	) t
	where t.rn = 1
) t2
on t1.apply_code = t2.apply_code
left join
(
	select *
	from
	(
		select *, row_number()over(partition by apply_code order by update_time desc) rn
		from dw_nd.ods_bizhall_apply_base_info
	) t
	where t.rn = 1
) t3
on t1.apply_code = t3.apply_code
left join dw_base.dim_area_info t4
on t1.region = t4.area_cd
left join dw_base.dim_area_info t5
on t2.town_code = t5.area_cd
left join dw_base.tmp_dwd_guar_info_new_busi_value_v2 t6
on t3.mgt_form = t6.code
and t6.dict_code = 'managementContentType'

left join dw_base.tmp_dwd_guar_info_new_busi_value_v2 t7
on t2.category_third = t7.code
and t7.dict_code = 'category' -- 三级品类(取)

left join dw_base.dim_econ_pl_map t8
on t7.value = t8.ind_type_lv3_value
left join dw_base.dim_cust_type t9
on t1.cust_type = t9.code   
;
commit;




-- 更新地市
-- update dw_base.dwd_guar_info_all  set city_name = replace(city_name,'市','') ;
-- commit;

-- 更新县区
-- update dw_base.dwd_guar_info_all  set city_name = concat(city_name,'市') ;
-- commit;






-- 补充乡镇村庄 20231007 wangyuanxin
drop table if exists dw_tmp.tmp_dwd_guar_info_all_village_update ;
commit;

CREATE TABLE dw_tmp.tmp_dwd_guar_info_all_village_update (
  code varchar(40)  COMMENT '业务编号',
  town varchar(64)  COMMENT '乡镇/街道',
  village varchar(64)  COMMENT '村/社区',
  KEY tmp_dwd_guar_info_all_village_update_code (code) COMMENT '业务编号索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ;
commit;

insert into dw_tmp.tmp_dwd_guar_info_all_village_update
(
 code
,town
,village
)
select
 t4.guar_no
,t2.area_name
,t3.area_name
from
(
	select	code
			,country
			,village
	from
	(
		select
		code
		,country
		,village
		,row_number()over(partition by code order by db_update_time desc) rn
		from dw_nd.ods_t_biz_project_main
	) t
	where t.rn = 1
) t1
inner join dw_base.dwd_guar_cont_info_all t4
on t1.code = t4.proj_no
left join dw_base.dim_area_info t2
on t1.country = t2.area_cd
left join dw_base.dim_area_info t3
on t1.village = t3.area_cd
where t1.country is not null or t1.village is null
;
commit;


update dw_base.dwd_guar_info_all t1
inner join dw_tmp.tmp_dwd_guar_info_all_village_update t2
on t1.guar_id = t2.code
set t1.town_name = t2.town
	,t1.village_name = t2.village
;
commit;


-- 更新状态 增加已代偿    20211123
update dw_base.dwd_guar_info_all t1
inner join dw_base.tmp_dwd_guar_info_compt t2 -- 代偿标志  
on t1.guar_id = t2.guar_id
set t1.item_stt = '已代偿'
where t2.is_compt = '1';

commit;


-- add 20230807 更新台账的项目状态以担保系统为准，除“已代偿”数据外不再依赖画像系统 zhangfl------------------------
drop table if exists dw_tmp.tmp_dwd_guar_info_all_item_stt ;
commit;

create table dw_tmp.tmp_dwd_guar_info_all_item_stt(
 guar_id        varchar(100) comment '业务编号'
,item_stt_code  varchar(10)  comment '项目状态'
,project_id     varchar(64)  comment '项目ID'
,term           varchar(1)   comment '项目期数'
,index idx_tmp_dwd_guar_info_all_item_stt_gid(guar_id)
,index idx_tmp_dwd_guar_info_all_item_stt_pid(project_id)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin comment='担保业务系统的项目状态';
commit;

-- 1.进件、续支、自主续支的项目的状态
insert into dw_tmp.tmp_dwd_guar_info_all_item_stt
(guar_id
,item_stt_code
,project_id
,term
)
select code as guar_id  -- 业务编号
       ,proj_status as item_stt_code -- 业务状态
       ,id as project_id   -- 项目ID
       ,'1' as term        -- 项目期数
from
(
	select id, code, proj_status,row_number()over(partition by code order by db_update_time desc,update_time desc) rn
	from dw_nd.ods_t_biz_project_main 
) t  -- 进件表数据
where code is not null
and t.rn = 1

union all
select code as guar_id  -- 业务编号
       ,case when t.status = '10' then '00'         -- 项目状态：00-提报中10-审批中20-待签约30-待出函40-待放款50-已放款97-已作废98-已终止99-已否决91-不受理90-已解保
             when t.status in ('20','30') then '10' -- 续支状态  10-提报中20-审批中30-待缴费40-待出函50-待放款60-已放款         98-已终止99-已否决
             when t.status = '40' then '30'
             when t.status = '50' then '40'
             when t.status = '60' then '50'
             else t.status end as item_stt_code -- 业务状态
       ,project_id   -- 项目ID
       ,term         -- 项目期数
from
(
	select project_id, code, status, term, row_number()over(partition by code order by db_update_time desc,update_time desc) rn
	from dw_nd.ods_t_biz_proj_xz
) t  -- 续支数据
where code is not null
and t.rn = 1

union all
select code as guar_id  -- 业务编号
       ,case when t.status = '03' then '50' else t.status end as item_stt_code -- 业务状态
       ,project_id   -- 项目ID
       ,term         -- 项目期数
from
(
	select project_id, code, status, term, row_number()over(partition by code order by db_update_time desc,update_time desc) rn
	from dw_nd.ods_t_biz_proj_loan_check
	where type = '02'
) t  -- 自主续支数据
where code is not null
and t.rn = 1
;
commit;

drop table if exists dw_tmp.tmp_dwd_guar_info_all_item_stt_maxterm ;
commit;

create table dw_tmp.tmp_dwd_guar_info_all_item_stt_maxterm(
 project_id      varchar(100) comment '业务ID'
 ,max_term       varchar(1)   comment '最大续支期数'
 ,index idx_tmp_dwd_guar_info_all_item_stt_maxterm_id(project_id)
 ) engine=innodb default charset=utf8mb4 collate=utf8mb4_bin comment='担保业务系统的项目最大续支期数';
 commit;
 
insert into dw_tmp.tmp_dwd_guar_info_all_item_stt_maxterm(
  project_id
  ,max_term
)
select project_id
       ,max(term) as max_term
  from dw_tmp.tmp_dwd_guar_info_all_item_stt
 where item_stt_code = '50'
 group by project_id
;
commit;

-- 2.更新 当下一期续支存在且为“已放款”更新上一期业务状态为已解保
update dw_tmp.tmp_dwd_guar_info_all_item_stt t1, dw_tmp.tmp_dwd_guar_info_all_item_stt_maxterm t2
set t1.item_stt_code = '90'
where t1.project_id = t2.project_id 
and t1.term < t2.max_term
and t1.item_stt_code not in ('98', '99', '92') -- 上一笔状态为：已终止、已否决、超期终止、已关闭则不更新状态
;
commit;

-- 3.根据画像“已代偿”数据更新原业务为已代偿
drop table if exists dw_tmp.tmp_dwd_guar_info_all_main_comp ;
commit;
create table dw_tmp.tmp_dwd_guar_info_all_main_comp
(project_id  varchar(100) comment '业务ID'
,index idx_tmp_dwd_guar_info_all_main_comp_id(project_id)
)engine=innodb default charset=utf8mb4 collate=utf8mb4_bin comment='画像系统代偿数据对应的原业务ID';
 commit;

insert into dw_tmp.tmp_dwd_guar_info_all_main_comp
select t2.project_id
from dw_base.tmp_dwd_guar_info_compt t1  -- 画像系统代偿担保年度业务编号
left join dw_tmp.tmp_dwd_guar_info_all_item_stt t2
on t1.guar_id = t2.guar_id
;
commit;

update dw_tmp.tmp_dwd_guar_info_all_item_stt t1, dw_tmp.tmp_dwd_guar_info_all_main_comp t2
set t1.item_stt_code = '93'
where t1.project_id = t2.project_id
and t1.term = '1'
;
commit;

update dw_tmp.tmp_dwd_guar_info_all_item_stt
set item_stt_code =
  case when item_stt_code = '00' then '提报中'
     when item_stt_code = '10' then '审批中'
	 when item_stt_code = '20' then '待签约'
	 when item_stt_code = '30' then '待出函'
	 when item_stt_code = '40' then '待放款'
	 when item_stt_code = '50' then '已放款'
	 when item_stt_code = '97' then '已作废'
	 when item_stt_code = '98' then '已终止'
	 when item_stt_code = '99' then '已否决'
	 when item_stt_code = '91' then '不受理'
	 when item_stt_code = '90' then '已解保'
	 when item_stt_code = '92' then '超期终止'   -- 业务数据项目状态添加“超期终止”   20211122
	 when item_stt_code = '93' then '已代偿'
	 end;
commit;

-- 4.迁移表数据的业务状态
-- 5.潍坊V贷的数据

-- 6.根据临时表更新台账的项目状态
update dw_base.dwd_guar_info_all t1, dw_tmp.tmp_dwd_guar_info_all_item_stt t2
set t1.item_stt = t2.item_stt_code
where t1.guar_id = t2.guar_id
;
commit;
-- add 20230807 ------------------------------------------------------------------------------------------

-- 删除码值临时表   （国民经济分类临时表部分存在一对多关系，再创建一个新临时表 20211104）
drop table if exists dw_base.tmp_ods_imp_econ_info;
commit;

-- 创建码值临时表
create table dw_base.tmp_ods_imp_econ_info(                
             code varchar(100),      -- 码值             
			 value varchar(100),     -- 名称
             INDEX (code)
)ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

commit;

-- 码值临时表插入数据
insert into dw_base.tmp_ods_imp_econ_info(
					 code,
					 value )
select	value,
		max(code) as code
       
from  dw_tmp.tmp_guar_info_econ_info_01
group by value
having count(1) = 1			                          -- code与value一一对应的
			 
union all                                             -- 与一个value对应多个code 并集
select c.code,
       c.value 
from
(
	select code,value, row_number()over(partition by value order by code desc) rn
	from dw_tmp.tmp_guar_info_econ_info_01
	where value in(select value
					from  dw_tmp.tmp_guar_info_econ_info_01
					group by value
					having count(1) != 1)  -- 一组有多个的
	and length(code) !=1
) c					  -- 长度不等于1的
where c.rn = 1
;
commit;



-- 删除中间临时表 （创建此表 使guar_id 与 国民经济编码 直接关联 20211104）
drop table if exists dw_base.tmp_dwd_guar_info_all_mid;
commit;

-- 创建中间临时表
create table dw_base.tmp_dwd_guar_info_all_mid(
             guar_id varchar(100),  -- 台账编号             
			 code varchar(100),     -- 国民经济分类编码
             INDEX (guar_id)
)ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

commit;

-- 中间临时表插入数据
insert into dw_base.tmp_dwd_guar_info_all_mid(                     -- 先插入guar_id不在dwd_guar_info_new_busi 里面的数据 20211104
            guar_id, -- 台账编号          
			code)    -- 国民经济分类编码
select b.guar_id,  
       c.code
from (select guar_id,                                              -- 台账编号
             substring_index(econ_class,'/',-1) as econ_class      -- 取字符串最后一个分隔符后的字符串
      from dw_base.dwd_guar_info_all a
      where not exists(select guar_id 
       	               from dw_base.dwd_guar_info_new_busi
		               where guar_id = a.guar_id)
		and not exists(select apply_code                              -- 且guar_id不在 标准线上业务台账 里面 20231214
       	               from dw_tmp.tmp_dwd_guar_info_all_online_biz_econ
		               where apply_code = a.guar_id)) b
left join dw_base.tmp_ods_imp_econ_info c
on b.econ_class = c.value;

commit;
			                       
insert into dw_base.tmp_dwd_guar_info_all_mid(                     -- 再插入guar_id在dwd_guar_info_new_busi 里面的数据  20211104
            guar_id, -- 台账编号
			code)    -- 国民经济分类编码
select a.guar_id,
       b.econ_class_cd
from  dw_base.dwd_guar_info_new_busi a
left join dw_base.tmp_dwd_guar_info_econ b                 
on a.guar_id = b.proj_dtl_no;

commit;

insert into dw_base.tmp_dwd_guar_info_all_mid(                     -- 再插入guar_id在 标准线上业务台账 里面的数据  20231214
            guar_id, -- 台账编号
			code)    -- 国民经济分类编码
select t.apply_code
       ,t.econ_code
  from dw_tmp.tmp_dwd_guar_info_all_online_biz_econ t;
commit;

-- 解保信息临时表   20211123
drop table if exists dw_base.tmp_ods_t_biz_proj_unguar_idt; 
commit;

create table dw_base.tmp_ods_t_biz_proj_unguar_idt(
project_id varchar(50),     -- 业务ID
unguar_date varchar(8),      -- 解保日期
index (project_id)
)ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

commit;


insert into dw_base.tmp_ods_t_biz_proj_unguar_idt(
project_id,  -- 业务ID
unguar_date) -- 解保日期
select b.project_id,
       b.unguar_date
from
(
	select	a.project_id,
			a.unguar_date,
			a.status
	from
	(
		select	project_id,                                    --  原项目id
				date_format(unguar_date,'%Y%m%d') unguar_date, --  解保日期
				status,                                         -- 状态
				row_number()over(partition by project_id order by update_time desc) rn
		from dw_nd.ods_t_biz_proj_unguar	  --  解保项目表
	) a
	where a.rn = 1
) b
where b.status = '20'   -- 20已解保 
;
commit;

-- 代偿信息临时表    20211123
drop table if exists dw_base.tmp_comp_totl_date_time_tdt; 
commit;

create table dw_base.tmp_comp_totl_date_time_tdt(
proj_code varchar(50),     -- 业务ID
approp_totl decimal(18,2), -- 代偿金额
approp_date varchar(8),    -- 代偿日期
update_time varchar(8),    -- 代偿登记日期
index (proj_code)
)ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;

commit;

insert into dw_base.tmp_comp_totl_date_time_tdt(
proj_code,    -- 业务ID
approp_totl,  -- 代偿金额
approp_date,  -- 代偿日期
update_time)  -- 代偿登记日期
select t1.proj_code,   -- 原业务编号
       t2.approp_totl, -- 须拨付代偿款金额（本息）
	   t2.approp_date, -- 代偿款拨付申请日
	   t2.update_time  -- 最后修改时间
from
(
	select a.id,a.proj_code
	from
	(
		select	id,             -- 主键
				project_id,     -- 项目ID
				proj_code,      -- 原业务编号
				db_update_time  -- 修改日期？？
				,row_number()over(partition by project_id order by db_update_time desc) rn
		from dw_nd.ods_t_proj_comp_aply   -- 代偿申请信息表
		where status = '50'    -- 50为已代偿
	) a 
	where a.rn = 1
) t1
left join
(
	select b.comp_id,b.approp_totl,b.approp_date,b.update_time 
	from
	(
		select comp_id,                                         -- 代偿ID
				approp_totl,                                     -- 须拨付代偿款金额（本息）
				date_format(approp_date,'%Y%m%d') approp_date,   -- 代偿款拨付申请日
				date_format(update_time,'%Y%m%d') update_time    -- 最后修改时间
				,row_number()over(partition by comp_id order by update_time desc) rn
		from dw_nd.ods_t_proj_comp_appropriation  --  拨付信息表
	) b 
	where b.rn = 1
) t2
on t1.id = t2.comp_id; 
commit;

-- 删除产业集群临时表 
drop table if exists dw_base.tmp_ind_clus_gid_code;  -- 产业集群临时表    20211123
commit;

-- 创建产业集群临时表              
create table dw_base.tmp_ind_clus_gid_code(
code varchar(100),
value varchar(1024),
INDEX (code) 
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;

commit; 

-- 产业集群临时表插入数据
insert into dw_base.tmp_ind_clus_gid_code(
code,
value
)
select a.code,a.value 
from
(
	select code,value,row_number()over(partition by value order by create_time desc) rn
	from dw_nd.ods_t_sys_data_dict_value_v2 
	where dict_code ='aggregateScheme'
) a                -- 取创建时间最晚的 
where a.rn = 1
;
commit;



-- dwd_guar_info_stat
-- 20220511 添加project_id字段，添加project_no字段
drop table if exists dw_tmp.tmp_guar_info_stat_proj_tmp01 ;
commit;
create table if not exists dw_tmp.tmp_guar_info_stat_proj_tmp01 
(
code	         varchar(50) COMMENT '业务编号'
,code_last         varchar(50) COMMENT '前业务编号'
,project_id varchar(64) COMMENT '项目编号'
,index idx_tmp_guar_info_stat_proj_tmp01_code( code )
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;
-- 插入进件
insert into dw_tmp.tmp_guar_info_stat_proj_tmp01
 select 
 a.code as code  -- 进件项目编号
,a.code as code_last -- 前业务编号
,a.id  as project_id  -- 进件project_id 新增
from 
(
	select CODE,id
	from
	(
		select CODE,id,row_number()over(partition by code order by update_time desc) rn
		from dw_nd.ods_t_biz_project_main 
		where code is not null 
	)a
	where a.rn = 1
)a  -- 进件
;
commit;

-- 插入续支
insert into dw_tmp.tmp_guar_info_stat_proj_tmp01
select 
 a.CODE as code              -- 续支项目编号
,b.code as code_last         -- 上游项目编号
,a.project_id as project_id  -- 续支project_id 新增
from 
(
	select CODE,project_id
	from
	(
		select CODE,project_id,id,row_number()over(partition by id order by db_update_time desc,update_time desc) rn
		from dw_nd.ods_t_biz_proj_xz 
		where code is not null 
	)a
	where a.rn = 1
)a
inner join 
(
	select CODE,id
	from
	(
		select CODE,id,row_number()over(partition by code order by db_update_time desc,update_time desc) rn
		from dw_nd.ods_t_biz_project_main 
		where code is not null 
	)b
	where b.rn = 1
)b  
on  a.project_Id =b.id  
 ;commit;
 
 -- 插入自主续支
insert into dw_tmp.tmp_guar_info_stat_proj_tmp01
select 
 a.CODE  as code   
,c.code  as code_last        
,a.project_id  as  project_id  
from 
(
	select CODE,project_id
	from
	(
		select CODE,project_id,id,row_number()over(partition by id order by db_update_time desc) rn
		from dw_nd.ods_t_biz_proj_loan_check
		where code is not null 
	)a
	where a.rn = 1
)a -- 自主续支
inner join 
(
	select CODE,id
	from
	(
		select CODE,id,row_number()over(partition by code order by db_update_time desc,update_time desc) rn
		from dw_nd.ods_t_biz_project_main 
		where code is not null 
	)c
	where c.rn = 1
)c  
on a.project_Id = c.id  
;
commit ;

-- 20241126 插入线上产品台账
insert into dw_tmp.tmp_guar_info_stat_proj_tmp01
select	t1.apply_code   as code
		,t1.apply_code as code_last
		,t2.id         as project_id
from
(
	select apply_code
	from
	(
		select apply_code, row_number()over(partition by apply_code order by update_time desc) rn
		from dw_nd.ods_bizhall_guar_online_biz
		where push_after_loan= '1'
	) t
	where t.rn = 1
) t1
inner join dw_tmp.tmp_dwd_guar_info_all_online_biz_econ t0 -- 国民经济分类/国担分类直取
on t1.apply_code = t0.apply_code
inner join 
(
	select id,apply_code
	from
	(
		select id,apply_code, row_number()over(partition by apply_code order by update_time desc) rn
		from dw_nd.ods_bizhall_guar_apply
	) t
	where t.rn = 1
) t2
on t1.apply_code = t2.apply_code
;
commit;

-- 机构
drop table if exists dw_tmp.tmp_guar_info_stat_city ;
commit;
create table if not exists dw_tmp.tmp_guar_info_stat_city 
(
city_code	         varchar(50)
,city_name         varchar(200)
,index tmp_guar_info_stat_city_city_code( city_code )
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;

insert into dw_tmp.tmp_guar_info_stat_city
select area_cd as city_code,substr(area_name,1,2) as city_name -- mdy 20220524 wyx
from dw_base.dim_area_info where area_lvl = '2'
;
commit;


drop table if exists dw_tmp.tmp_guar_info_stat_city02 ;
commit;
create table if not exists dw_tmp.tmp_guar_info_stat_city02 
(
area_cd	           varchar(50)
,area_name         varchar(200)
,sup_area_name     varchar(200)
,index tmp_guar_info_stat_city_area_cd( area_cd )
,index tmp_guar_info_stat_city_area_name( area_name(60) )
) 
ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC ;
commit ;

insert into dw_tmp.tmp_guar_info_stat_city02
select  area_cd,area_name,sup_area_name
from dw_base.dim_area_info 
where area_lvl = '3'
;
commit;



-- 插入数据
delete from dw_base.dwd_guar_info_stat;
commit;

insert into dw_base.dwd_guar_info_stat
(
day_id          -- 数据日期
,cust_id         -- 客户号
,guar_id         -- 担保ID
,city_code       -- 地市
,country_code    -- 县区
,cust_type_code  -- 客户大类
,cust_class_code -- 客户分类
,guar_code       -- 农担分类
,econ_code       -- 国民经济分类
,prod_code       -- 产品
,bank_code       -- 银行
,loan_rate       -- 贷款利率
,guar_rate       -- 担保利率
,item_stt_code   -- 项目状态
,term            -- 贷款合同期数
,loan_star_dt    -- 贷款开始时间
,loan_end_dt     -- 贷款结束时间
,loan_reg_dt     -- 放款登记时间
,ovd_days        -- 逾期天数
,data_source     -- 数据来源
,risk_class      -- 五级分类
,appl_amt        -- 申请金额
,loan_amt        -- 贷款金额      
,grant_amt       -- 放款金额
,cert_no         -- 身份证号       -- 增加字段  20211118
,scheme_code     -- 产业集群       -- 增加字段  20211118
,unguar_dt       -- 解保日期           -- 增加字段  20211123
,compt_amt       -- 代偿金额           -- 增加字段  20211123
,compt_dt        -- 代偿日期           -- 增加字段  20211123
,compt_reg_dt    -- 代偿登记日期       -- 增加字段  20211123
,project_no 	 -- 前业务编号	-- 增加字段 20220511
,project_id 	 -- 项目编号	-- 增加字段20220511
)
select
-- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d') -- 数据日期
'${v_sdate}'
,cust_id -- 客户号
,t1.guar_id -- 担保ID
,t1.city_code -- 地市
,t1.country_code  -- 县区
,coalesce(t4.code,'99')  -- 客户大类
,coalesce(t5.code,'07') -- 客户分类
,coalesce(t6.code,'99') -- 农担分类
,t11.code -- 国民经济分类
,case when data_source in ('诸葛祥雨数据','道一云线上数据','龙戈数据') and guar_prod ='农耕贷' then '9999'
      else coalesce(t7.code,'9999') 
      end -- 产品
, coalesce(t8.code,'OTHER') -- 银行
,loan_rate -- 贷款利率
,guar_rate -- 担保利率
,case when t1.item_stt = '已批复' then '04'
      when t1.item_stt = '已出函' then '05'
	  when t1.item_stt in ('手工关闭','已关闭','不受理') then '09'
	  else coalesce(t9.code,'02') end item_stt_code -- 项目状态
,loan_term -- 贷款合同期数
,loan_begin_dt -- 贷款开始时间
,loan_end_dt -- 贷款结束时间
,case when loan_reg_dt is null or loan_reg_dt ='' then  loan_begin_dt  else date_format(loan_reg_dt,'%Y%m%d') end
,ovd_days -- 逾期天数
,data_source -- 数据来源
,risk_class -- 五级分类
,appl_amt -- 申请金额
,loan_amt -- 贷款金额
,guar_amt -- 放款金额
,t1.cert_no -- 身份证号          -- 增加字段  20211118
,t12.code scheme_code   -- 产业集群          -- 增加字段  20211118
,case when t1.item_stt in( '已解保' ,'已代偿') and t13.unguar_date is null then t1.loan_end_dt
 else  t13.unguar_date end unguar_dt  -- 解保日期      -- 增加字段，修改判断逻辑   20211123
,t14.approp_totl  -- 代偿金额                          -- 增加字段   20211123
,t14.approp_date  -- 代偿日期                          -- 增加字段   20211123
,t14.update_time  -- 代偿登记日期                      -- 增加字段   20211123
,case when t1.guar_id like '%SDAGWF%XZ%'  then substr(t1.guar_id,1,15)
		when t15.code_last is not null then t15.code_last
		else t1.guar_id 
		end project_no   -- 增加字段   20220511 前业务编号 project_id
,t15.project_id -- 增加字段   20220511  项目id
from dw_base.dwd_guar_info_all t1
-- left join dw_tmp.tmp_guar_info_stat_city t2
-- on t1.city_name = t2.city_name
left join dw_base.dim_cust_type t4
on t1.cust_type = t4.value
left join dw_base.dim_cust_class t5
on t1.cust_class = t5.value
left join dw_base.dim_guar_class t6
on t1.guar_class = t6.value
left join dw_base.tmp_dwd_guar_info_new_busi_value_v2 t7
on t1.guar_prod = t7.value
and t7.dict_code = 'productWarranty'
left join dw_base.dim_bank_class t8
on t1.bank_class = t8.value
left join dw_base.dim_item_stt t9
on t1.item_stt = t9.value
-- left join dw_tmp.tmp_guar_info_stat_city02   t10  -- mdy 20220518 wyx
-- on t1.city_name = t10.sup_area_name
-- and t1.county_name = t10.area_name
left join dw_base.tmp_dwd_guar_info_all_mid t11       --  关联新建中间表      20211104
on t1.guar_id = t11.guar_id
left join dw_base.tmp_ind_clus_gid_code t12           --    关联产业集群临时表    20211123  
on t1.clus_scheme = t12.value
left join dw_base.tmp_ods_t_biz_proj_unguar_idt t13           --  关联解保信息临时表    20211123
on t1.guar_id = t13.project_id
left join dw_base.tmp_comp_totl_date_time_tdt t14             --  关联代偿信息临时表    20211123
on t1.guar_id = t14.proj_code
left join dw_tmp.tmp_guar_info_stat_proj_tmp01 t15
on t1.guar_id = t15.code
;
commit;



-- 历史表
delete from dw_base.dwd_guar_info_all_his where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_guar_info_all_his
select 
* 
from dw_base.dwd_guar_info_all
;

commit;






-- 20210531 农担项目负责人信息 dwd_guar_mgr_info
-- 银行客户经理
drop table if exists dw_base.tmp_dwd_guar_mgr_info_bank_mgr ;
commit;

create  table dw_base.tmp_dwd_guar_mgr_info_bank_mgr(
   guar_id varchar(100)  ,
   proj_type_cd varchar(2),
   loan_type varchar(2) ,
   bank_mgr_id varchar(100)  ,
   bank_mgr_name  varchar(100)  ,
   bank_mgr_tel  varchar(50)  ,
   INDEX( guar_id ) 
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

insert into dw_base.tmp_dwd_guar_mgr_info_bank_mgr
select proj_dtl_no
       ,proj_type_cd   -- 01 首保项目、02 续保项目、 03 续保增额 04 续支 05 贷后检查-自动转存
       ,loan_type      -- 0-普通贷款1-自主循环贷（随借随还）2-非自主循环贷（一年一支用）
	   ,bank_mgr_id
	   ,t2.mgr_name
       ,bank_mgr_tel 
from dw_base.dwd_agmt_guar_info t1 
left join  dw_base.dwd_mgr_info t2 
on t1.bank_mgr_id = t2. mgr_id
where proj_dtl_no is not null
;
commit;

drop table if exists dw_base.tmp_dwd_guar_mgr_info_nd_mgr ;
commit;


create  table dw_base.tmp_dwd_guar_mgr_info_nd_mgr(
   guar_id varchar(100)  ,
   nd_mgr_id varchar(100)  ,
   nd_mgr_name  varchar(100)  ,
   nd_mgr_tel varchar(50),
   INDEX( guar_id ) 
) ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC 
;
commit;

-- 农担项目经理
insert into dw_base.tmp_dwd_guar_mgr_info_nd_mgr
select t1.proj_no
       ,t1.worker_id
	   ,t2.real_name
	   ,t2.phone_number
from       
(
	select proj_no,worker_id
	from 
	(
		select proj_no,worker_id,updt_tm,row_number()over(partition by proj_no order by begin_tm desc) rn
		from dw_base.dwd_evt_wf_task_info
		where task_name ='合同审查'
	) t 
	where t.rn = 1
) t1
left join
(
	select user_id,real_name,phone_number
	from
	(
		SELECT user_id,real_name,phone_number,update_time,row_number()over(partition by user_id order by update_time desc) rn
		FROM dw_nd.ods_t_sys_user
	) t
	where t.rn = 1
) t2
on t1.worker_id = t2.user_id
;
commit ;

 
   
truncate table dw_base.dwd_guar_mgr_info ;
commit ;


insert into dw_base.dwd_guar_mgr_info
select
-- DATE_FORMAT(date_sub(date(now()),interval 1 day),'%Y%m%d') -- 数据日期
'${v_sdate}'
,t1.guar_id -- 项目编号
,t2.proj_type_cd -- 项目分类 01 首保项目、02 续保项目、 03 续保增额 04 续支 05 贷后检查-自动转存
,t2.loan_type -- 贷款类型
,t1.cust_id -- 客户号
,t1.cust_name -- 客户姓名
,''  -- 证件类型
,t1.cert_no -- 证件号码
,t3.nd_mgr_id -- 农担合同审查人员id
,t3.nd_mgr_name -- 农担合同审查人员姓名
,t3.nd_mgr_tel -- 农担合同审查人员联系方式
,t2.bank_mgr_id -- 银行客户经理id
,t2.bank_mgr_name -- 银行客户经理姓名
,t2.bank_mgr_tel -- 银行客户经理联系方式
from dw_base.dwd_guar_info_all t1
left join dw_base.tmp_dwd_guar_mgr_info_bank_mgr t2
on t1.guar_id = t2.guar_id
left join dw_base.tmp_dwd_guar_mgr_info_nd_mgr t3 -- 农担项目经理
on t1.guar_id = t3.guar_id
 ;
commit ;


update dw_base.dwd_guar_mgr_info  t1
left join
(
	select mgr_name,max(mgr_id) as mgr_id,max(tel_no) as tel_no
	from dw_base.dwd_mgr_info
	group by mgr_name
	having count( mgr_name)=1 
) t2
on t1.mgr_name=t2.mgr_name
set t1.mgr_id=t2.mgr_id,t1.mgr_tel=t2.tel_no
where t1.mgr_name is not null and t1.mgr_id is null
;
commit;

-- 删除银行客户经理信息临时表 VD NX RZ   20211112
drop table if exists dw_base.tmp_ods_mgr_vd_nx_rz;
commit;

-- 创建银行客户经理信息临时表 VD NX RZ   20211112
create table dw_base.tmp_ods_mgr_vd_nx_rz(
code varchar(100),            -- 业务编号
mgr_id varchar(100),          -- 经理ID
mgr_name varchar(100),        -- 经理姓名
index (mgr_id)
)ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;
commit;

-- 银行客户经理信息临时表 VD NX RZ插入数据   20211112
insert into dw_base.tmp_ods_mgr_vd_nx_rz(
						code,
					    mgr_id,
						mgr_name)
select  t1.code,
		t1.creator,
		t2.mgr_name
from
(
	select	a.code,
			a.creator
	from
	(
		select	code
				,creator
				,row_number()over(partition by code order by update_time desc) rn
		from dw_nd.ods_t_biz_project_main  -- 主项目表
		where code like 'VD%' or code like 'NX%' or code like 'RZ%' -- 银行客户经理编号存储为银行系统编号 VD NX RZ 
	)a 
	where a.rn = 1
) t1
left join (select  mgr_id,
			       mgr_name 
		  from dw_base.dwd_mgr_info) t2   -- 客户经理信息表
on t1.creator = t2.mgr_id;
commit;

-- 修改银行客户经理 VD NX RZ   ID 姓名   20211112
update dw_base.dwd_guar_mgr_info t1 
inner join dw_base.tmp_ods_mgr_vd_nx_rz t2
on t1.guar_id = t2.code
set t1.mgr_id = t2.mgr_id,t1.mgr_name = t2.mgr_name
;

commit ;


-- 农担项目负责人经理id临时表  20211118
drop table if exists dw_base.tmp_dwd_guar_mgr_info_mgr_id;
commit;

create table dw_base.tmp_dwd_guar_mgr_info_mgr_id(
guar_id varchar(50),  -- 业务ID
mgr_id varchar(50),   -- 经理ID
index idx_tmp_dwd_guar_mgr_info_guar_id(guar_id),
index idx_tmp_dwd_guar_mgr_info_mgr_id(mgr_id)
)ENGINE=InnoDB  DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin ROW_FORMAT=DYNAMIC;
commit;

insert into dw_base.tmp_dwd_guar_mgr_info_mgr_id
select guar_id,mgr_id 
from dw_base.dwd_guar_mgr_info;
commit;


-- 修改台账星型表数据  客户经理     20211118
update dw_base.dwd_guar_info_stat t1               -- 担保台账星型表
left join dw_base.tmp_dwd_guar_mgr_info_mgr_id t2  -- 农担项目负责人信息临时表
on t1.guar_id = t2.guar_id 
set t1.mgr_id = t2.mgr_id;        -- 客户经理
commit;
