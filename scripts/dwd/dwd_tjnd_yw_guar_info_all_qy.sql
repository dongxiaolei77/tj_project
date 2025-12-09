-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241213
-- 目标表   :dwd_tjnd_yw_guar_info_all_qy      		   迁移业务宽表
-- 源表     ： dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation   -- 申请表
--			  dw_nd.ods_creditmid_v2_z_migrate_base_customers_history    -- 客户表
--            dw_nd.ods_creditmid_v2_z_migrate_afg_counter_guarantor     -- 共同借款人表
--            dw_nd.ods_tjnd_yw_base_product_management   -- 产品表
--            dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement  -- 合作机构表
--            dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation    -- 放款凭证表
--            dw_nd.ods_tjnd_yw_wf_process_business   	  -- 工作流引擎表
--            dw_nd.ods_tjnd_yw_wf_activity_instance  	  -- 工作流任务表
--            dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_letter	  -- 担保函表
--            dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_relieve     -- 解保表
--            dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory           -- 代偿表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------


/*
create table `dwd_tjnd_yw_guar_info_all_qy` (
  `day_id` varchar(8) default null comment '数据日期',
  `id_business_information` bigint not null comment '业务主键id',
  `guarantee_code` varchar(100) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '业务编码',
  `id_approval` bigint default null comment '关联核保id',
  `id_customer` bigint default null comment '关联客户主键',
  `customer_name` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '客户姓名',
  `cert_type` varchar(200) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '证件类型',
  `id_number` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '证件号码',
  `area` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '区域',
  `enter_code` varchar(255) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '所在部门编码',
  `is_stock_customer` varchar(10) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '是否存量客户（1-新增；2-存量）',
  `is_first_loan` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '是否首贷',
  `gt_amount` decimal(32,2) default null comment '在保金额',
  `busi_mode_name` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '业务模式名称',
  `gur_state` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '担保状态',
  `counter_gur_method` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '反担保方式',
  `apply_time` datetime default null,
  `application_amount` decimal(32,2) default null comment '申请金额',
  `term` decimal(32,2) default null comment '期限',
  `over_time` datetime default null,
  `appr_dt` varchar(8) default null comment '批复日期',
  `cooperative_bank_first` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '合作银行一级',
  `cooperative_bank_second` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '合作银行二级',
  `cooperative_bank_third` varchar(200) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '合作银行三级',
  `cooperative_bank_fourth` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '合作银行四级',
  `full_bank_name` varchar(100) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '合作银行全称',
  `product_grade` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '产品',
  `product_name` varchar(50) character set utf8 collate utf8_general_ci default null comment '产品名称',
  `product_labeling` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '产品标签',
  `application_type` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '申请类型（业务申请-ywsq；支用申请-zysq）',
  `guarantee_tate` decimal(32,4) default null comment '担保费率',
  `is_revolving_loan` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '是否循环贷',
  `coop_org_id` bigint default null comment '合作机构id',
  `coop_org_name` varchar(200) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '合作机构名称',
  `coop_gov_id` bigint default null comment '合作政府id',
  `coop_gov_name` varchar(200) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '合作政府名称',
  `mainbody_type_corp` varchar(50) character set utf8 collate utf8_general_ci default null comment '主体类型',
  `customer_nature` varchar(200) character set utf8 collate utf8_general_ci default null comment '客户性质',
  `cust_type` varchar(200) character set utf8 collate utf8_general_ci default '2' comment '客户类型',
  `cust_source` varchar(50) character set utf8 collate utf8_general_ci default null comment '客户来源',
  `gender` varchar(50) character set utf8 collate utf8_general_ci default null comment '性别',
  `address` varchar(200) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '户籍住址',
  `marriage_sta` varchar(200) character set utf8 collate utf8_general_ci default null comment '婚姻状况',
  `tel` varchar(50) character set utf8 collate utf8_general_ci default null comment '联系电话',
  `contacts_addr` varchar(200) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '联系地址',
  `spouse_name` varchar(50) character set utf8 collate utf8_general_ci default null comment '配偶姓名',
  `spouse_id_no` varchar(50) character set utf8 collate utf8_general_ci default null comment '配偶证件号码',
  `spouse_tel` varchar(50) character set utf8 collate utf8_general_ci default null comment '配偶手机号码',
  `enterpise_type` varchar(50) character set utf8 collate utf8_general_ci default null comment '企业划型',
  `legal_representative` varchar(50) character set utf8 collate utf8_general_ci default null comment '法定代表人',
  `legal_representative_id` varchar(50) character set utf8 collate utf8_general_ci default null comment '法定代表人身份证号',
  `leg_tel`varchar(50) character set utf8 collate utf8_general_ci default null comment '法定代表人联系电话',
  `industry_category_company` varchar(50) character set utf8 collate utf8_general_ci default null comment '行业分类（公司）',
  `industry_category_nation` varchar(50) character set utf8 collate utf8_general_ci default null comment '行业分类（国标）',
  `enterpri_scale` varchar(50) character set utf8 collate utf8_general_ci default null comment '企业规模',
  `unit` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '经营规模-单位',
  `business_revenue` decimal(32,2) default null comment '经营收入',
  `operation_loan` decimal(32,2) default null comment '其中经营性贷款',
  `office_address` varchar(200) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '经营地址',
  `related_agreement_id` bigint default null comment '关联协议id',
  `related_agreement` varchar(100) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '协议名称',
  `agreement_type` varchar(50) character set utf8 collate utf8_general_ci default null comment '协议类型',
  `compensatory_rate_upper` double default null comment '代偿上限率',
  `bank_org_rate` double default null comment '银行分险比例',
  `gov_org_rate` double default null comment '政府分险比例',
  `coop_org_rate` double default null comment '合作机构分险比例',
  `compensation_period` decimal(32,2) default null comment '代偿期限[天]',
  `lend_reg_dt` varchar(8) default null comment '计入在保日期',
  `repayment_way` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '还款方式',
  `approval_total` decimal(32,2) default null comment '本次审批金额',
  `loan_contract_no` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '借款合同编号',
  `loan_contract_amount` decimal(32,2) default null comment '借款合同金额',
  `contracr_start_date` date default null comment '合同起始日期',
  `contracr_end_date` date default null comment '合同结束日期',
  `guarantee_period` decimal(32,2) default null comment '保函期限',
  `year_loan_rate` decimal(32,6) default null comment '年贷款利率',
  `guaranty_contract_no` varchar(200) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '保证合同编号',
  `letter_of_guarante_no` varchar(50) character set utf8mb4 collate utf8mb4_0900_ai_ci default null comment '保函编号',
  `date_of_set` date default null comment '解保日期',
  `is_compt` varchar(1) default null comment '是否已代偿',
  `total_compensation` decimal(32,2) default null comment '代偿总额',
  `payment_date` date default null comment '代偿拨付日期',
  key `id_inx` (`id_business_information`)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='迁移业务宽表'
*/

delete
from dw_base.dwd_tjnd_yw_guar_info_all_qy
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_yw_guar_info_all_qy
select distinct '${v_sdate}'                                  as day_id                  -- 数据日期
     , a.id                                          as id_business_information -- 业务主键
     , a.guarantee_code                                                         -- 业务编号
     , a.id_approval                                                            -- 核保id
     , a.id_customer                                                            -- 客户id
     , a.customer_name                                                          -- 客户名称
     , a.cert_type                                                              -- 证件类型
     , a.id_number                                                              -- 证件号码
     , a.area                                                                   -- 区域代码
     , a.enter_code                                                             -- 办事处代码
     , a.is_stock_customer                                                      -- 是否存量客户（1-新增；2-存量）
     , a.is_first_loan                                                          -- 是否首贷
     , a.gt_amount                                                              -- 在保金额
     , a.busi_mode_name                                                         -- 业务模式名称
     , a.gur_state                                                              -- 业务状态
     , a.counter_gur_method                                                     -- 反担保方式
     , a.created_time                                                           -- 申请日期
     , a.application_amount                                                     -- 申请金额
     , a.term                                                                   -- 申请期限
     , a.over_time                                                              -- 办结时间
     , case
           when a.busi_mode_name = '津易担' then date_format(f.ai_start_datetime, '%Y%m%d')
           when a.busi_mode_name = '见贷即保' then date_format(f.contracr_start_date, '%Y%m%d')
           when a.busi_mode_name in ('津融担', '联合授信') then date_format(f.guar_letter_time, '%Y%m%d')
    end                                              as appr_dt                 -- 批复日期
     , a.cooperative_bank_first                                                 -- 合作银行一级
     , a.cooperative_bank_second                                                -- 合作银行二级
     , a.cooperative_bank_third                                                 -- 合作银行三级
     , a.cooperative_bank_fourth                                                -- 合作银行四级
     , a.full_bank_name                                                         -- 合作银行全称
     , a.product_grade                                                          -- 产品id
     , c.product_name                                                           -- 产品名称
     , a.product_labeling                                                       -- 产品标签
     , a.application_type                                                       -- 申请类型
     , a.guarantee_tate                                                         -- 担保费率
     , a.is_revolving_loan                                                      -- 是否循环贷
     , a.coop_org_id                                                            -- 合作机构id
     , a.coop_org_name                                                          -- 合作机构名称
     , a.coop_gov_id                                                            -- 合作政府id
     , a.coop_gov_name                                                          -- 合作政府名称
     , b.mainbody_type_corp                                                     -- 主体类型
     , b.customer_nature                                                        -- 客户性质
     , b.cust_type                                                              -- 客户类型
     , b.cust_source                                                            -- 客户来源
     , b.gender                                                                 -- 性别
     , b.address                                                                -- 户籍住址
     , b.MARRIAGE_STATUS                                                           -- 婚姻状况
     , b.tel                                                                    -- 联系电话
     , b.contacts_addr                                                          -- 联系地址
     , b.spouse_name                                                            -- 配偶姓名
     , b.spouse_id_no                                                           -- 配偶证件号码
     , b.spouse_tel                                                             -- 配偶联系电话
     , b.enterpise_type                                                         -- 企业划型
     , b.legal_representative                                                   -- 法定代表人
     , b.legal_representative_id                                                -- 法定代表人身份证号
     , b.leg_tel                                                                -- 法定代表人联系电话
     , b.industry_category_company                                              -- 所属行业
     , b.industry_category_nation                                               -- 行业分类（国标）
     , b.enterpri_scale                                                         -- 企业规模
     , b.unit                                                                   -- 经营规模-单位
     , b.business_revenue                                                       -- 经营收入
     , b.operation_loan                                                         -- 经营性贷款
     , b.office_address                                                         -- 经营地址
     , a.related_agreement_id                                                   -- 关联协议id
     , a.related_agreement                                                      -- 协议名称
     , d.agreement_type                                                         -- 协议类型
     , d.compensatory_rate_upper                                                -- 代偿上限率
     , d.bank_org_rate                                                          -- 银行分险比例
     , d.gov_org_rate                                                           -- 政府分险比例
     , d.coop_org_rate                                                          -- 合作机构分险比例
     , d.compensation_period                                                    -- 代偿宽限期
     , e.lend_reg_dt                                                            -- 计入在保日期
     , e.repayment_way                                                          -- 借款合同还款方式
     , f.approval_total                                                         -- 审批金额/担保金额
     , f.loan_contract_no                                                       -- 借款合同编号
     , f.loan_contract_amount                                                   -- 借款合同金额
     , f.contracr_start_date                                                    -- 合同起始日期
     , f.contracr_end_date                                                      -- 合同结束日期
     , f.guarantee_period                                                       -- 担保期限
     , f.year_loan_rate                                                         -- 年利率
     , f.guaranty_contract_no                                                   -- 保证合同编号
     , f.letter_of_guarante_no                                                  -- 保函编号/放款通知书编号
     , g.date_of_set                                                            -- 解保日期
     , if(h.id_cfbiz_underwriting is not null, 1, 0) as is_compt                -- 是否已代偿
     , h.total_compensation                                                     -- 代偿拨付金额
     , h.payment_date                                                           -- 代偿拨付日期
from (
         select id                      -- 业务主键
              , guarantee_code          -- 业务编号
              , id_approval             -- 核保id
              , id_customer             -- 客户id
              , customer_name           -- 客户名称
              , cert_type               -- 证件类型
              , id_number               -- 证件号码
              , area                    -- 区域代码
              , enter_code              -- 办事处代码
              , is_stock_customer       -- 是否存量客户（1-新增；2-存量）
              , is_first_loan           -- 是否首贷
              , gt_amount               -- 在保金额
              , busi_mode_name          -- 业务模式名称
              , gur_state               -- 业务状态
              , counter_gur_method      -- 反担保方式
              , created_time            -- 申请日期
              , application_amount      -- 申请金额
              , term                    -- 申请期限
              , over_time               -- 办结时间/批复时间
              , cooperative_bank_first  -- 合作银行一级
              , cooperative_bank_second -- 合作银行二级
              , cooperative_bank_third  -- 合作银行三级
              , cooperative_bank_fourth -- 合作银行四级
              , full_bank_name          -- 合作银行全称
              , product_grade           -- 产品id
              , product_labeling        -- 产品标签
              , application_type        -- 申请类型
              , guarantee_tate          -- 担保费率
              , is_revolving_loan       -- 是否循环贷
              , related_agreement_id    -- 关联协议id
              , related_agreement       -- 协议名称
              , coop_org_id             -- 合作机构id
              , coop_org_name           -- 合作机构名称
              , coop_gov_id             -- 合作政府id
              , coop_gov_name           -- 合作政府名称
         from dw_nd.ods_creditmid_v2_z_migrate_afg_business_infomation -- 申请表
     ) a
         left join
     (
         select a.id                        -- ??
              , a.id_base_customers         -- ？？
              , a.customer_no               -- 客户编号
              , a.customer_name             -- 客户姓名
              , a.id_number                 -- 证件号码
              , a.id_business_information   -- 业务主键
              , a.mainbody_type_corp        -- 主体类型
              , a.customer_nature           -- 客户性质
              , a.cust_type                 --
              , a.cust_source               -- 客户来源
              , a.cert_type                 -- 证件类型
              , a.gender                    -- 性别
              , a.address                   -- 户籍住址
              , a.MARRIAGE_STATUS              -- 婚姻状况
              , a.tel                       -- 联系电话
              , a.contacts_addr             -- 联系地址
              , a.spouse_name               -- 配偶姓名
              , a.spouse_id_no              -- 配偶证件号码
              , replace(b.tel,' ','') as spouse_tel         -- 配偶手机号码
              , a.enterpise_type            -- 企业划型
              , a.legal_representative      -- 法定代表人
              , a.legal_representative_id   -- 法定代表人身份证号
              , a.industry_category_company -- 所属行业
              , a.industry_category_nation  -- 行业分类（国标）
              , a.enterpri_scale            -- 企业规模
              , a.unit                      -- 经营规模-单位
              , a.business_revenue          -- 经营收入
              , a.operation_loan            -- 经营性贷款
              , a.office_address            -- 经营地址
	      , replace(a.tel,' ','') as leg_tel -- 法定代表人联系电话 
         from dw_nd.ods_creditmid_v2_z_migrate_base_customers_history a -- 客户表
                  left join dw_nd.ods_creditmid_v2_z_migrate_afg_counter_guarantor b -- 共同借款人表
                            on a.id_business_information = b.id_business_information
                                and a.spouse_id_no = b.id_number
     ) b on a.id = b.id_business_information -- ??
         left join
     (
         select id
              , product_no   -- 产品编号
              , product_name -- 产品名称
         from dw_nd.ods_tjnd_yw_base_product_management -- 产品表
     ) c on a.product_grade = c.product_no -- ??
         left join
     (
         select id
              , protocol_no             -- 协议编号d
              , protocol_name           -- 协议名称
              , agreement_type          -- 协议类型
              , compensatory_rate_upper -- 代偿上限率
              , bank_org_rate           -- 银行分险比例
              , gov_org_rate            -- 政府分险比例
              , coop_org_rate           -- 合作机构分险比例
              , compensation_period     -- 代偿宽限期
         from dw_nd.ods_tjnd_yw_base_cooperative_institution_agreement -- 合作机构表
     ) d on a.related_agreement_id = d.id
         left join
     (
         select id_business_information                                   -- 业务编号
              , min(date_format(created_time, '%Y%m%d')) as lend_reg_dt   -- 计入在保日期
              , min(repayment_way)                       as repayment_way -- 借款合同还款方式 ??
         from dw_nd.ods_creditmid_v2_z_migrate_afg_voucher_infomation -- 放款凭证表
        where delete_flag = 1 
	group by id_business_information
     ) e on a.id = e.id_business_information
         left join
     (
         select id_business_information -- 业务编号
              , approval_total          -- 审批金额/担保金额
              , loan_contract_no        -- 借款合同编号
              , loan_contract_amount    -- 借款合同金额
              , contracr_start_date     -- 合同起始日期
              , contracr_end_date       -- 合同结束日期
              , guarantee_period        -- 担保期限
              , year_loan_rate          -- 年利率
              , guarantee_tate          -- 担保费率
              , guaranty_contract_no    -- 保证合同编号
              , letter_of_guarante_no   -- 保函编号/放款通知书编号
              , id_intended_letter      -- 担保意向函id
              , b.ai_start_datetime     -- 补充合同时间
              , c.guar_letter_time      -- 出具意向函时间
         from dw_nd.ods_creditmid_v2_z_migrate_afg_business_approval a
                  left join
              (
                  select a.itemid
                       , b.ai_start_datetime
                  from dw_nd.ods_tjnd_yw_wf_process_business a -- 工作流引擎表
                           left join (select *, row_number() over (partition by BU_CODE order by AI_END_DATE desc) as rn
                                      from dw_nd.ods_tjnd_yw_wf_activity_instance
                                      where node_id = '407' -- 津易担没有批复的概念, 前面审批完直接就项目经理补充合同，407表示项目经理补充合同环节
                  ) b -- 工作流任务表
                                     on a.bucode = b.bu_code
                  where a.processcode = 'ywsp_pl'
                    and b.rn = 1 -- 取最新一条
              ) b on a.id_business_approval_pl = b.itemid
                  left join
              (
                  select id
                       , creat_time as guar_letter_time
                  from dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_letter -- 担保函表
              ) c on a.id_intended_letter = c.id
     ) f on a.id = f.id_business_information
         left join
     (
         select id_business_information
              , date_of_set -- 解保日期
         from dw_nd.ods_creditmid_v2_z_migrate_afg_guarantee_relieve -- 解保表
         where deleted_flag = 1
           and IF_RELIEVE_TYPE = 1
           and IS_RELIEVE_FLAG = 0
     ) g on a.id = g.id_business_information
         left join
     (
         select id_cfbiz_underwriting
              , total_compensation -- 代偿拨付金额
              , payment_date       -- 代偿拨付日期
         from dw_nd.ods_creditmid_v2_z_migrate_bh_compensatory -- 代偿表
         where over_tag = 'BJ'
           and status = 1
     ) h on a.id = h.id_cfbiz_underwriting
;
commit;
