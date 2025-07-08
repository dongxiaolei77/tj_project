-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250409
-- 目标表   ：dw_base.ads_rpt_tjnd_busi_record_stat_loan 业务状况-放款
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation                   业务申请表
--          dw_nd.ods_tjnd_yw_base_customers_history                    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_afg_voucher_infomation                    放款凭证信息
--          dw_nd.ods_tjnd_yw_afg_voucher_repayment                     还款凭证信息
--          dw_nd.ods_tjnd_yw_base_product_management                   BO,产品管理,NEW
--          新业务系统
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
delete
from dw_base.ads_rpt_tjnd_busi_record_stat_loan
where day_id = '${v_sdate}';
commit;

-- 创建临时表存储
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan;
create table if not exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(
    day_id            varchar(8)     null comment '数据日期',
    report_type       varchar(50)    null comment '报表类型',
    group_type        varchar(50)    null comment '统计类型',
    group_name        varchar(100)   null comment '分组名称',
    start_balance     decimal(36, 6) null comment '期初余额(万元)',
    start_cnt         int            null comment '期初笔数',
    now_guar_amt      decimal(36, 6) null comment '当期放款金额(万元)',
    now_guar_cnt      int            null comment '当期放款笔数',
    now_repayment_amt decimal(36, 6) null comment '当期还款金额(万元)',
    now_repayment_cnt int            null comment '当期还款笔数',
    end_balance       decimal(36, 6) null comment '期末余额(万元)',
    end_cnt           int            null comment '期末笔数'
) comment '临时-业务部-业务状况-放款' collate = utf8mb4_bin;

# -- 旧系统逻辑
# -- 按银行
# insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
# (day_id, -- 数据日期
#  group_type, -- 统计类型
#  group_name, -- 分组名称
#  start_balance, -- 期初余额(万元)
#  start_cnt, -- 期初笔数
#  now_guar_amt, -- 当期放款金额(万元)
#  now_guar_cnt, -- 当期放款笔数
#  now_repayment_amt, -- 当期还款金额(万元)
#  now_repayment_cnt, -- 当期还款笔数
#  end_balance, -- 期末余额(万元)
#  end_cnt -- 期末笔数
# )
# select '${v_sdate}'                                                                                as day_id,
#        '银行'                                                                                        as group_type,
#        bank_name,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)            as start_cnt,
#        sum(if(now_guar_amt is null,0,now_guar_amt))                                                                           as now_guar_amt,
#        count(t4.ID_BUSINESS_INFORMATION)                                                           as now_guar_cnt,
#        sum(if(now_repayment_amt is null,0,now_repayment_amt))                                                                      as now_repayment_amt,
#        count(t6.ID_BUSINESS_INFORMATION)                                                           as now_repayment_cnt,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)           as end_cnt
# from (
#          select ID,                    -- 业务id
#                 COOPERATIVE_BANK_FIRST -- 银行对应编码
#          from dw_nd.ods_tjnd_yw_afg_business_infomation
#          where GUR_STATE in ('GT', 'ED')
#      ) t1
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                 -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as guar_amt, -- 放款金额
#                 max(CREATED_TIME)           as guar_date -- 放款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                           -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as repayment_amt, -- 还款金额
#                 max(CREATED_TIME)                as repayment_date -- 还款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t3 on t1.ID = t3.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                    -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as now_guar_amt -- 当期放款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t4 on t1.ID = t4.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                              -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as now_repayment_amt -- 当期还款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t5 on t1.ID = t5.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION -- 业务id  解保日期为当天的业务
#          from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
#          where DELETED_FLAG = '1'
#            and IS_RELIEVE_FLAG = '0'
#            and date_format(DATE_OF_SET, '%Y%m%d') = '${v_sdate}'
#      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select fieldcode,                 -- 银行对应编码
#                 enterfullname as bank_name -- 银行名称
#          from dw_nd.ods_tjnd_yw_base_enterprise
#          where parentid = 200
#      ) t7 on t1.COOPERATIVE_BANK_FIRST = t7.fieldcode
# group by bank_name;
# commit;
#
#
# -- 按产品
# insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
# (day_id, -- 数据日期
#  group_type, -- 统计类型
#  group_name, -- 分组名称
#  start_balance, -- 期初余额(万元)
#  start_cnt, -- 期初笔数
#  now_guar_amt, -- 当期放款金额(万元)
#  now_guar_cnt, -- 当期放款笔数
#  now_repayment_amt, -- 当期还款金额
#  now_repayment_cnt, -- 当期还款笔数
#  end_balance, -- 期末余额(万元)
#  end_cnt -- 期末笔数
# )
# select '${v_sdate}'                                                                                as day_id,
#        '产品'                                                                                        as group_type,
#        PRODUCT_NAME,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)            as start_cnt,
#        sum(if(now_guar_amt is null,0,now_guar_amt))                                                                           as now_guar_amt,
#        count(t4.ID_BUSINESS_INFORMATION)                                                           as now_guar_cnt,
#        sum(if(now_repayment_amt is null,0,now_repayment_amt))                                                                      as now_repayment_amt,
#        count(t6.ID_BUSINESS_INFORMATION)                                                           as now_repayment_cnt,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)           as end_cnt
# from (
#          select ID,           -- 业务id
#                 PRODUCT_GRADE -- 产品对应编码
#          from dw_nd.ods_tjnd_yw_afg_business_infomation
#          where GUR_STATE in ('GT', 'ED')
#      ) t1
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                 -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as guar_amt, -- 放款金额
#                 max(CREATED_TIME)           as guar_date -- 放款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                           -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as repayment_amt, -- 还款金额
#                 max(CREATED_TIME)                as repayment_date -- 还款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t3 on t1.ID = t3.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                    -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as now_guar_amt -- 当期放款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t4 on t1.ID = t4.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                              -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as now_repayment_amt -- 当期还款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t5 on t1.ID = t5.ID_BUSINESS_INFORMATION
#          left join
#
#      (
#          select ID_BUSINESS_INFORMATION -- 业务id  解保日期为当天的业务
#          from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
#          where DELETED_FLAG = '1'
#            and IS_RELIEVE_FLAG = '0'
#            and date_format(DATE_OF_SET, '%Y%m%d') = '${v_sdate}'
#      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select fieldcode,   -- 产品编码
#                 PRODUCT_NAME -- 产品名称
#          from dw_nd.ods_tjnd_yw_base_product_management
#      ) t7 on t1.PRODUCT_GRADE = t7.fieldcode
# group by PRODUCT_NAME;
# commit;
#
# -- 按行业归类
# insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
# (day_id, -- 数据日期
#  group_type, -- 统计类型
#  group_name, -- 分组名称
#  start_balance, -- 期初余额(万元)
#  start_cnt, -- 期初笔数
#  now_guar_amt, -- 当期放款金额(万元)
#  now_guar_cnt, -- 当期放款笔数
#  now_repayment_amt, -- 当期还款金额
#  now_repayment_cnt, -- 当期还款笔数
#  end_balance, -- 期末余额(万元)
#  end_cnt -- 期末笔数
# )
# select '${v_sdate}'                                                                                as day_id,
#        '行业归类'                                                                                      as group_type,
#        case
#            when INDUSTRY_CATEGORY_COMPANY = '0' then '农产品初加工'
#            when INDUSTRY_CATEGORY_COMPANY = '1' then '粮食种植'
#            when INDUSTRY_CATEGORY_COMPANY = '2' then '重要、特色农产品种植'
#            when INDUSTRY_CATEGORY_COMPANY = '3' then '其他畜牧业'
#            when INDUSTRY_CATEGORY_COMPANY = '4' then '生猪养殖'
#            when INDUSTRY_CATEGORY_COMPANY = '5' then '农产品流通'
#            when INDUSTRY_CATEGORY_COMPANY = '6' then '渔业生产'
#            when INDUSTRY_CATEGORY_COMPANY = '7' then '农资、农机、农技等农业社会化服务'
#            when INDUSTRY_CATEGORY_COMPANY = '8' then '农业新业态'
#            when INDUSTRY_CATEGORY_COMPANY = '9' then '农田建设'
#            when INDUSTRY_CATEGORY_COMPANY = '10' then '其他农业项目'
#            end                                                                                     as INDUSTRY_CATEGORY_COMPANY,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)            as start_cnt,
#        sum(if(now_guar_amt is null,0,now_guar_amt))                                                                           as now_guar_amt,
#        count(t4.ID_BUSINESS_INFORMATION)                                                           as now_guar_cnt,
#        sum(if(now_repayment_amt is null,0,now_repayment_amt))                                                                      as now_repayment_amt,
#        count(t6.ID_BUSINESS_INFORMATION)                                                           as now_repayment_cnt,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)           as end_cnt
# from (
#          select ID,         -- 业务id
#                 ID_CUSTOMER -- 客户对应id
#          from dw_nd.ods_tjnd_yw_afg_business_infomation
#          where GUR_STATE in ('GT', 'ED')
#      ) t1
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                 -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as guar_amt, -- 放款金额
#                 max(CREATED_TIME)           as guar_date -- 放款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                           -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as repayment_amt, -- 还款金额
#                 max(CREATED_TIME)                as repayment_date -- 还款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t3 on t1.ID = t3.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                    -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as now_guar_amt -- 当期放款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t4 on t1.ID = t4.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                              -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as now_repayment_amt -- 当期还款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t5 on t1.ID = t5.ID_BUSINESS_INFORMATION
#          left join
#
#      (
#          select ID_BUSINESS_INFORMATION -- 业务id  解保日期为当天的业务
#          from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
#          where DELETED_FLAG = '1'
#            and IS_RELIEVE_FLAG = '0'
#            and date_format(DATE_OF_SET, '%Y%m%d') = '${v_sdate}'
#      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select id,                       -- 客户id
#                 INDUSTRY_CATEGORY_COMPANY -- 行业分类（公司）
#          from dw_nd.ods_tjnd_yw_base_customers_history
#      ) t7 on t1.ID_CUSTOMER = t7.ID
# group by INDUSTRY_CATEGORY_COMPANY;
# commit;
#
#
# -- 按办事处
# insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
# (day_id, -- 数据日期
#  group_type, -- 统计类型
#  group_name, -- 分组名称
#  start_balance, -- 期初余额(万元)
#  start_cnt, -- 期初笔数
#  now_guar_amt, -- 当期放款金额(万元)
#  now_guar_cnt, -- 当期放款笔数
#  now_repayment_amt, -- 当期还款金额
#  now_repayment_cnt, -- 当期还款笔数
#  end_balance, -- 期末余额(万元)
#  end_cnt -- 期末笔数
# )
# select '${v_sdate}'                                                                                as day_id,
#        '办事处'                                                                                       as group_type,
#        case
#            when branch_off = 'YW_NHDLBSC' then '宁河东丽办事处'
#            when branch_off = 'YW_JNBHXQBSC' then '津南滨海新区办事处'
#            when branch_off = 'YW_WQBCBSC' then '武清北辰办事处'
#            when branch_off = 'YW_XQJHBSC' then '西青静海办事处'
#            when branch_off = 'YW_JZBSC' then '蓟州办事处'
#            when branch_off = 'YW_BDBSC' then '宝坻办事处'
#            end                                                                                     as branch_off,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)            as start_cnt,
#        sum(if(now_guar_amt is null,0,now_guar_amt))                                                                           as now_guar_amt,
#        count(t4.ID_BUSINESS_INFORMATION)                                                           as now_guar_cnt,
#        sum(if(now_repayment_amt is null,0,now_repayment_amt))                                                                      as now_repayment_amt,
#        count(t6.ID_BUSINESS_INFORMATION)                                                           as now_repayment_cnt,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)           as end_cnt
# from (
#          select ID,                      -- 业务id
#                 enter_code as branch_off -- 部门编码
#          from dw_nd.ods_tjnd_yw_afg_business_infomation
#          where GUR_STATE in ('GT', 'ED')
#      ) t1
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                 -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as guar_amt, -- 放款金额
#                 max(CREATED_TIME)           as guar_date -- 放款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                           -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as repayment_amt, -- 还款金额
#                 max(CREATED_TIME)                as repayment_date -- 还款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t3 on t1.ID = t3.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                    -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as now_guar_amt -- 当期放款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t4 on t1.ID = t4.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                              -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as now_repayment_amt -- 当期还款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t5 on t1.ID = t5.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION -- 业务id  解保日期为当天的业务
#          from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
#          where DELETED_FLAG = '1'
#            and IS_RELIEVE_FLAG = '0'
#            and date_format(DATE_OF_SET, '%Y%m%d') = '${v_sdate}'
#      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
# group by branch_off;
# commit;
#
#
# -- 按区域
# insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
# (day_id, -- 数据日期
#  group_type, -- 统计类型
#  group_name, -- 分组名称
#  start_balance, -- 期初余额(万元)
#  start_cnt, -- 期初笔数
#  now_guar_amt, -- 当期放款金额(万元)
#  now_guar_cnt, -- 当期放款笔数
#  now_repayment_amt, -- 当期还款金额
#  now_repayment_cnt, -- 当期还款笔数
#  end_balance, -- 期末余额(万元)
#  end_cnt -- 期末笔数
# )
# select '${v_sdate}'                                                                                as day_id,
#        '区域'                                                                                        as group_type,
#        area_name,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)            as start_cnt,
#        sum(if(now_guar_amt is null,0,now_guar_amt))                                                                           as now_guar_amt,
#        count(t4.ID_BUSINESS_INFORMATION)                                                           as now_guar_cnt,
#        sum(if(now_repayment_amt is null,0,now_repayment_amt))                                                                      as now_repayment_amt,
#        count(t6.ID_BUSINESS_INFORMATION)                                                           as now_repayment_cnt,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)           as end_cnt
# from (
#          select ID,                                              -- 业务id
#                 JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]')) as area -- 转换为区县
#          from dw_nd.ods_tjnd_yw_afg_business_infomation
#          where GUR_STATE in ('GT', 'ED')
#      ) t1
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                 -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as guar_amt, -- 放款金额
#                 max(CREATED_TIME)           as guar_date -- 放款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                           -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as repayment_amt, -- 还款金额
#                 max(CREATED_TIME)                as repayment_date -- 还款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t3 on t1.ID = t3.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                    -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as now_guar_amt -- 当期放款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t4 on t1.ID = t4.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                              -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as now_repayment_amt -- 当期还款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t5 on t1.ID = t5.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION -- 业务id  解保日期为当天的业务
#          from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
#          where DELETED_FLAG = '1'
#            and IS_RELIEVE_FLAG = '0'
#            and date_format(DATE_OF_SET, '%Y%m%d') = '${v_sdate}'
#      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
#          left join
#      dw_base.dim_area_info t7 on t1.area = t7.area_cd
# group by area_name;
# commit;
#
# -- 按一级支行
# insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
# (day_id, -- 数据日期
#  group_type, -- 统计类型
#  group_name, -- 分组名称
#  start_balance, -- 期初余额(万元)
#  start_cnt, -- 期初笔数
#  now_guar_amt, -- 当期放款金额(万元)
#  now_guar_cnt, -- 当期放款笔数
#  now_repayment_amt, -- 当期还款金额
#  now_repayment_cnt, -- 当期还款笔数
#  end_balance, -- 期末余额(万元)
#  end_cnt -- 期末笔数
# )
# select '${v_sdate}'                                                                                as day_id,
#        '银行一级支行'                                                                                    as group_type,
#        bank_name,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)            as start_cnt,
#        sum(if(now_guar_amt is null,0,now_guar_amt))                                                                           as now_guar_amt,
#        count(t4.ID_BUSINESS_INFORMATION)                                                           as now_guar_cnt,
#        sum(if(now_repayment_amt is null,0,now_repayment_amt))                                                                      as now_repayment_amt,
#        count(t6.ID_BUSINESS_INFORMATION)                                                           as now_repayment_cnt,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)           as end_cnt
# from (
#          select ID,                     -- 业务id
#                 COOPERATIVE_BANK_SECOND -- 二级支行编码
#          from dw_nd.ods_tjnd_yw_afg_business_infomation
#          where GUR_STATE in ('GT', 'ED')
#      ) t1
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                 -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as guar_amt, -- 放款金额
#                 max(CREATED_TIME)           as guar_date -- 放款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                           -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as repayment_amt, -- 还款金额
#                 max(CREATED_TIME)                as repayment_date -- 还款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t3 on t1.ID = t3.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                    -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as now_guar_amt -- 当期放款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t4 on t1.ID = t4.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                              -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as now_repayment_amt -- 当期还款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t5 on t1.ID = t5.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION -- 业务id  解保日期为当天的业务
#          from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
#          where DELETED_FLAG = '1'
#            and IS_RELIEVE_FLAG = '0'
#            and date_format(DATE_OF_SET, '%Y%m%d') = '${v_sdate}'
#      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select t1.fieldcode,
#                 concat(t2.enterfullname, t1.enterfullname) as bank_name
#          from dw_nd.ods_tjnd_yw_base_enterprise t1
#                   left join dw_nd.ods_tjnd_yw_base_enterprise t2 on t1.parentid = t2.enterid
#      ) t7 on t1.COOPERATIVE_BANK_SECOND = t7.fieldcode
# group by bank_name;
# commit;
#
#
# -- 按项目经理核算
# insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
# (day_id, -- 数据日期
#  group_type, -- 统计类型
#  group_name, -- 分组名称
#  start_balance, -- 期初余额(万元)
#  start_cnt, -- 期初笔数
#  now_guar_amt, -- 当期放款金额(万元)
#  now_guar_cnt, -- 当期放款笔数
#  now_repayment_amt, -- 当期还款金额
#  now_repayment_cnt, -- 当期还款笔数
#  end_balance, -- 期末余额(万元)
#  end_cnt -- 期末笔数
# )
# select '${v_sdate}'                                                                                as day_id,
#        '项目经理'                                                                                      as group_type,
#        BUSINESS_SP_USER_NAME,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt else 0 end)  as start_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)            as start_cnt,
#        sum(if(now_guar_amt is null,0,now_guar_amt))                                                                           as now_guar_amt,
#        count(t4.ID_BUSINESS_INFORMATION)                                                           as now_guar_cnt,
#        sum(if(now_repayment_amt is null,0,now_repayment_amt))                                                                      as now_repayment_amt,
#        count(t6.ID_BUSINESS_INFORMATION)                                                           as now_repayment_cnt,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0  end) -
#        sum(case when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt else 0 end) as end_balance,
#        sum(case when date_format(guar_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)           as end_cnt
# from (
#          select ID,                   -- 业务id
#                 BUSINESS_SP_USER_NAME -- 项目经理
#          from dw_nd.ods_tjnd_yw_afg_business_infomation
#          where GUR_STATE in ('GT', 'ED')
#      ) t1
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                 -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as guar_amt, -- 放款金额
#                 max(CREATED_TIME)           as guar_date -- 放款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t2 on t1.ID = t2.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                           -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as repayment_amt, -- 还款金额
#                 max(CREATED_TIME)                as repayment_date -- 还款日期(取最近一天)
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#          group by ID_BUSINESS_INFORMATION
#      ) t3 on t1.ID = t3.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                    -- 业务id
#                 sum(RECEIPT_AMOUNT) / 10000 as now_guar_amt -- 当期放款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_infomation
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t4 on t1.ID = t4.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION,                              -- 业务id
#                 sum(REPAYMENT_PRINCIPAL) / 10000 as now_repayment_amt -- 当期还款金额
#          from dw_nd.ods_tjnd_yw_afg_voucher_repayment
#          where DELETE_FLAG = 1
#            and date_format(CREATED_TIME, '%Y%m%d') = '${v_sdate}'
#          group by ID_BUSINESS_INFORMATION
#      ) t5 on t1.ID = t5.ID_BUSINESS_INFORMATION
#          left join
#      (
#          select ID_BUSINESS_INFORMATION -- 业务id  解保日期为当天的业务
#          from dw_nd.ods_tjnd_yw_afg_guarantee_relieve
#          where DELETED_FLAG = '1'
#            and IS_RELIEVE_FLAG = '0'
#            and date_format(DATE_OF_SET, '%Y%m%d') = '${v_sdate}'
#      ) t6 on t1.ID = t6.ID_BUSINESS_INFORMATION
# group by BUSINESS_SP_USER_NAME;
# commit;

-- -----------------------------------------------
-- 新业务系统逻辑
-- 按银行
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                        as day_id,
		'日报'																				as report_type,
       '银行'                                                                                as group_type,
       gnd_dept_name,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt
               else 0 end)                                                                 as start_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
       count(t4.guar_id)                                                                   as now_guar_cnt,
       sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
       count(t6.guar_id)                                                                   as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
               else 0 end)                                                                 as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') = '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t7 on t1.guar_id = t7.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                        as day_id,
		'旬报'																				as report_type,
		'银行'                                                                                as group_type,
		gnd_dept_name,
		-- 旬:判断参数日期如果在每月1号到10号则期初为1号；如果10号到20号则起初为10号；否则为20号
		sum(case 
			when date_format(loan_reg_dt, '%Y%m%d') 
				< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
			then guar_amt else 0 end) 
		-
		sum(case
			when date_format(repayment_date, '%Y%m%d') 
				< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
			then repayment_amt else 0 end)                                                 as start_balance,
		sum(case 
			when date_format(loan_reg_dt, '%Y%m%d') 
				< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
			then 1 else 0 end)  as start_cnt,
		sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
		count(t4.guar_id)                                                                   as now_guar_cnt,
		sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
		count(t6.guar_id)                                                                   as now_repayment_cnt,
		sum(case 
			when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) 
		-
		sum(case
			when date_format(repayment_date, '%Y%m%d') 
				<= '${v_sdate}' then repayment_amt else 0 end)                                                                 as end_balance,
		sum(case 
			when date_format(loan_reg_dt, '%Y%m%d') 
				<= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),loan_reg_dt between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),loan_reg_dt between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,loan_reg_dt between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
		   and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t7 on t1.guar_id = t7.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                        as day_id,
		'月报'																				as report_type,
       '银行'                                                                                as group_type,
       gnd_dept_name,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then guar_amt else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then repayment_amt
               else 0 end)                                                                 as start_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then 1 else 0 end)  as start_cnt,
       sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
       count(t4.guar_id)                                                                   as now_guar_cnt,
       sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
       count(t6.guar_id)                                                                   as now_repayment_cnt,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
       sum(case
               when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
               else 0 end)                                                                 as end_balance,
       sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
		   and loan_reg_dt between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
		   and date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t7 on t1.guar_id = t7.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                        as day_id,
	'季报'																				as report_type,
	'银行'                                                                                as group_type,
	gnd_dept_name,
	sum(case 
		when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case 
		when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
	when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
	else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
			and if(quarter('${v_sdate}') = 1,loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,loan_reg_dt between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,loan_reg_dt between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if(quarter('${v_sdate}') = 1,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t7 on t1.guar_id = t7.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                        as day_id,
	'半年报'																				as report_type,
	'银行'                                                                                as group_type,
	gnd_dept_name,
	sum(case 
		when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') ) 
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
		< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') ) 
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case 
		when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') ) 
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
	when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
	else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
			and data_source = '担保业务管理系统新'
			and item_stt in ('已放款', '已代偿', '已解保')
			and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t7 on t1.guar_id = t7.biz_no
group by gnd_dept_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                        as day_id,
	'年报'																				as report_type,
	'银行'                                                                                as group_type,
	gnd_dept_name,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额(万元)
                loan_reg_dt, -- 放款登记日期
                loan_bank    -- 合作银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt,4) = left('${v_sdate}',4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date,4) = left('${v_sdate}',4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and left(unguar_dt,4) = left('${v_sdate}',4)
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '${v_sdate}'
     ) t7 on t1.guar_id = t7.biz_no
group by gnd_dept_name;
commit;

-- 按产品
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'日报' as report_type,
	'产品' as group_type,
	guar_prod,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额
                loan_reg_dt, -- 放款登记日期
                guar_prod
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') = '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
group by guar_prod;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'旬报' as report_type,
	'产品' as group_type,
	guar_prod,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
						,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
					) 
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				) 
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额
                loan_reg_dt, -- 放款登记日期
                guar_prod
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),loan_reg_dt between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),loan_reg_dt between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,loan_reg_dt between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t6 on t1.guar_id = t6.guar_id
group by guar_prod;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'月报' as report_type,
	'产品' as group_type,
	guar_prod,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额
                loan_reg_dt, -- 放款登记日期
                guar_prod
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
group by guar_prod;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'季报' as report_type,
	'产品' as group_type,
	guar_prod,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
		< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
	then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额
                loan_reg_dt, -- 放款登记日期
                guar_prod
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1,loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,loan_reg_dt between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,loan_reg_dt between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if(quarter('${v_sdate}') = 1,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t6 on t1.guar_id = t6.guar_id
group by guar_prod;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'半年报' as report_type,
	'产品' as group_type,
	guar_prod,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') ) 
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') ) 
		then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') ) 
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额
                loan_reg_dt, -- 放款登记日期
                guar_prod
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t6 on t1.guar_id = t6.guar_id
group by guar_prod;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'年报' as report_type,
	'产品' as group_type,
	guar_prod,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,     -- 业务id
                guar_amt,    -- 放款金额
                loan_reg_dt, -- 放款登记日期
                guar_prod
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt,4) = left('${v_sdate}',4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date,4) = left('${v_sdate}',4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and left(unguar_dt,4) = left('${v_sdate}',4)
     ) t6 on t1.guar_id = t6.guar_id
group by guar_prod;
commit;


-- 按行业归类
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'日报' as report_type,
	'行业归类' as group_type,
	guar_class,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') = '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'旬报' as report_type,
	'行业归类' as group_type,
	guar_class,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),loan_reg_dt between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),loan_reg_dt between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,loan_reg_dt between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t6 on t1.guar_id = t6.guar_id
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'月报' as report_type,
	'行业归类' as group_type,
	guar_class,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'季报' as report_type,
	'行业归类' as group_type,
	guar_class,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1,loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,loan_reg_dt between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,loan_reg_dt between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if(quarter('${v_sdate}') = 1,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t6 on t1.guar_id = t6.guar_id
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'半年报' as report_type,
	'行业归类' as group_type,
	guar_class,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t6 on t1.guar_id = t6.guar_id
group by guar_class;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'年报' as report_type,
	'行业归类' as group_type,
	guar_class,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                guar_class
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt,4) = left('${v_sdate}',4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date,4) = left('${v_sdate}',4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and left(unguar_dt,4) = left('${v_sdate}',4)
     ) t6 on t1.guar_id = t6.guar_id
group by guar_class;
commit;


-- 按办事处
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'日报' as report_type,
	'办事处' as group_type,
	case
		when branch_off = 'NHDLBranch' then '宁河东丽办事处'
		when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
		when branch_off = 'BCWQBranch' then '武清北辰办事处'
		when branch_off = 'XQJHBranch' then '西青静海办事处'
		when branch_off = 'JZBranch' then '蓟州办事处'
		when branch_off = 'BDBranch' then '宝坻办事处'
		end                                                                             as branch_off,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,                  -- 业务id
                guar_amt,                 -- 放款金额
                loan_reg_dt,              -- 放款登记日期
                country_code as area_code -- 区县编码
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') = '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select CITY_CODE_,              -- 区县名称
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t7 on t1.area_code = t7.CITY_CODE_
group by branch_off;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'旬报' as report_type,
	'办事处' as group_type,
	case
		when branch_off = 'NHDLBranch' then '宁河东丽办事处'
		when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
		when branch_off = 'BCWQBranch' then '武清北辰办事处'
		when branch_off = 'XQJHBranch' then '西青静海办事处'
		when branch_off = 'JZBranch' then '蓟州办事处'
		when branch_off = 'BDBranch' then '宝坻办事处'
		end                                                                             as branch_off,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,                  -- 业务id
                guar_amt,                 -- 放款金额
                loan_reg_dt,              -- 放款登记日期
                country_code as area_code -- 区县编码
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),loan_reg_dt between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),loan_reg_dt between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,loan_reg_dt between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select CITY_CODE_,              -- 区县名称
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t7 on t1.area_code = t7.CITY_CODE_
group by branch_off;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'月报' as report_type,
	'办事处' as group_type,
	case
		when branch_off = 'NHDLBranch' then '宁河东丽办事处'
		when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
		when branch_off = 'BCWQBranch' then '武清北辰办事处'
		when branch_off = 'XQJHBranch' then '西青静海办事处'
		when branch_off = 'JZBranch' then '蓟州办事处'
		when branch_off = 'BDBranch' then '宝坻办事处'
		end                                                                             as branch_off,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,                  -- 业务id
                guar_amt,                 -- 放款金额
                loan_reg_dt,              -- 放款登记日期
                country_code as area_code -- 区县编码
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select CITY_CODE_,              -- 区县名称
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t7 on t1.area_code = t7.CITY_CODE_
group by branch_off;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'季报' as report_type,
	'办事处' as group_type,
	case
		when branch_off = 'NHDLBranch' then '宁河东丽办事处'
		when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
		when branch_off = 'BCWQBranch' then '武清北辰办事处'
		when branch_off = 'XQJHBranch' then '西青静海办事处'
		when branch_off = 'JZBranch' then '蓟州办事处'
		when branch_off = 'BDBranch' then '宝坻办事处'
		end                                                                             as branch_off,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,                  -- 业务id
                guar_amt,                 -- 放款金额
                loan_reg_dt,              -- 放款登记日期
                country_code as area_code -- 区县编码
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1,loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,loan_reg_dt between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,loan_reg_dt between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if(quarter('${v_sdate}') = 1,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select CITY_CODE_,              -- 区县名称
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t7 on t1.area_code = t7.CITY_CODE_
group by branch_off;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'半年报' as report_type,
	'办事处' as group_type,
	case
		when branch_off = 'NHDLBranch' then '宁河东丽办事处'
		when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
		when branch_off = 'BCWQBranch' then '武清北辰办事处'
		when branch_off = 'XQJHBranch' then '西青静海办事处'
		when branch_off = 'JZBranch' then '蓟州办事处'
		when branch_off = 'BDBranch' then '宝坻办事处'
		end                                                                             as branch_off,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,                  -- 业务id
                guar_amt,                 -- 放款金额
                loan_reg_dt,              -- 放款登记日期
                country_code as area_code -- 区县编码
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select CITY_CODE_,              -- 区县名称
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t7 on t1.area_code = t7.CITY_CODE_
group by branch_off;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'年报' as report_type,
	'办事处' as group_type,
	case
		when branch_off = 'NHDLBranch' then '宁河东丽办事处'
		when branch_off = 'JNBHBranch' then '津南滨海新区办事处'
		when branch_off = 'BCWQBranch' then '武清北辰办事处'
		when branch_off = 'XQJHBranch' then '西青静海办事处'
		when branch_off = 'JZBranch' then '蓟州办事处'
		when branch_off = 'BDBranch' then '宝坻办事处'
		end                                                                             as branch_off,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,                  -- 业务id
                guar_amt,                 -- 放款金额
                loan_reg_dt,              -- 放款登记日期
                country_code as area_code -- 区县编码
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt,4) = left('${v_sdate}',4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date,4) = left('${v_sdate}',4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and left(unguar_dt,4) = left('${v_sdate}',4)
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select CITY_CODE_,              -- 区县名称
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t7 on t1.area_code = t7.CITY_CODE_
group by branch_off;
commit;


-- 按区域
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'日报' as report_type,
	'区域' as group_type,
	area,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,            -- 业务id
                guar_amt,           -- 放款金额
                loan_reg_dt,        -- 放款登记日期
                county_name as area -- 区县
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') = '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
group by area;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'旬报' as report_type,
	'区域' as group_type,
	area,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,            -- 业务id
                guar_amt,           -- 放款金额
                loan_reg_dt,        -- 放款登记日期
                county_name as area -- 区县
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),loan_reg_dt between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),loan_reg_dt between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,loan_reg_dt between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t6 on t1.guar_id = t6.guar_id
group by area;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'月报' as report_type,
	'区域' as group_type,
	area,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,            -- 业务id
                guar_amt,           -- 放款金额
                loan_reg_dt,        -- 放款登记日期
                county_name as area -- 区县
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
group by area;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'季报' as report_type,
	'区域' as group_type,
	area,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,            -- 业务id
                guar_amt,           -- 放款金额
                loan_reg_dt,        -- 放款登记日期
                county_name as area -- 区县
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1,loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,loan_reg_dt between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,loan_reg_dt between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if(quarter('${v_sdate}') = 1,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t6 on t1.guar_id = t6.guar_id
group by area;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'半年报' as report_type,
	'区域' as group_type,
	area,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') ) 
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') ) 
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') ) 
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,            -- 业务id
                guar_amt,           -- 放款金额
                loan_reg_dt,        -- 放款登记日期
                county_name as area -- 区县
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t6 on t1.guar_id = t6.guar_id
group by area;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'年报' as report_type,
	'区域' as group_type,
	area,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,            -- 业务id
                guar_amt,           -- 放款金额
                loan_reg_dt,        -- 放款登记日期
                county_name as area -- 区县
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt,4) = left('${v_sdate}',4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date,4) = left('${v_sdate}',4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and left(unguar_dt,4) = left('${v_sdate}',4)
     ) t6 on t1.guar_id = t6.guar_id
group by area;
commit;

-- 按银行一级支行
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'日报' as report_type,
	'银行一级支行' as group_type,
	loan_bank,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                loan_bank             -- 贷款银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') = '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
group by loan_bank;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'旬报' as report_type,
	'银行一级支行' as group_type,
	loan_bank,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then repayment_amt else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                loan_bank             -- 贷款银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),loan_reg_dt between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),loan_reg_dt between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,loan_reg_dt between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t6 on t1.guar_id = t6.guar_id
group by loan_bank;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'月报' as report_type,
	'银行一级支行' as group_type,
	loan_bank,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                loan_bank             -- 贷款银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
group by loan_bank;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'季报' as report_type,
	'银行一级支行' as group_type,
	loan_bank,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                loan_bank             -- 贷款银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1,loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,loan_reg_dt between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,loan_reg_dt between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if(quarter('${v_sdate}') = 1,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t6 on t1.guar_id = t6.guar_id
group by loan_bank;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'半年报' as report_type,
	'银行一级支行' as group_type,
	loan_bank,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                loan_bank             -- 贷款银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t6 on t1.guar_id = t6.guar_id
group by loan_bank;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'年报' as report_type,
	'银行一级支行' as group_type,
	loan_bank,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,              -- 业务id
                guar_amt as guar_amt, -- 放款金额
                loan_reg_dt,          -- 放款登记日期
                loan_bank             -- 贷款银行
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt,4) = left('${v_sdate}',4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date,4) = left('${v_sdate}',4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and left(unguar_dt,4) = left('${v_sdate}',4)
     ) t6 on t1.guar_id = t6.guar_id
group by loan_bank;
commit;

-- 按项目经理
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'日报' as report_type,
	'项目经理' as group_type,
	nd_proj_mgr_name,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt = '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') = '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select code,                            -- 项目id
                create_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t7 on t1.guar_id = t7.code
group by nd_proj_mgr_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'旬报' as report_type,
	'项目经理' as group_type,
	nd_proj_mgr_name,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format('${v_sdate}','%Y%m01') 
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format('${v_sdate}','%Y%m10') ,date_format('${v_sdate}','%Y%m20'))
				)
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),loan_reg_dt between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),loan_reg_dt between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,loan_reg_dt between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' <= date_format('${v_sdate}','%Y%m10'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and date_format('${v_sdate}','%Y%m10')
					,if('${v_sdate}' <= date_format('${v_sdate}','%Y%m20'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m10') and date_format('${v_sdate}','%Y%m20') 
						,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m20') and '${v_sdate}')
				)
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select code,                            -- 项目id
                create_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t7 on t1.guar_id = t7.code
group by nd_proj_mgr_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'月报' as report_type,
	'项目经理' as group_type,
	nd_proj_mgr_name,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y%m01') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and loan_reg_dt between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y%m01') and '${v_sdate}'
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select code,                            -- 项目id
                create_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t7 on t1.guar_id = t7.code
group by nd_proj_mgr_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'季报' as report_type,
	'项目经理' as group_type,
	nd_proj_mgr_name,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if(quarter('${v_sdate}') = 1,date_format('${v_sdate}','%Y0101')
				,if(quarter('${v_sdate}') = 2,date_format('${v_sdate}','%Y0401')
					,if(quarter('${v_sdate}') = 3,date_format('${v_sdate}','%Y0701')
						,if(quarter('${v_sdate}') = 4,date_format('${v_sdate}','%Y1001'),'')
					) ) )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if(quarter('${v_sdate}') = 1,loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,loan_reg_dt between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,loan_reg_dt between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if(quarter('${v_sdate}') = 1,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if(quarter('${v_sdate}') = 1,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,if(quarter('${v_sdate}') = 2,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0401') and '${v_sdate}'
					,if(quarter('${v_sdate}') = 3,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}'
						,if(quarter('${v_sdate}') = 4,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y1001') and '${v_sdate}','')
					) ) )
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select code,                            -- 项目id
                create_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t7 on t1.guar_id = t7.code
group by nd_proj_mgr_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'半年报' as report_type,
	'项目经理' as group_type,
	nd_proj_mgr_name,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') 
			< if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format('${v_sdate}','%Y0101'),date_format('${v_sdate}','%Y0701') )
		then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),loan_reg_dt between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,loan_reg_dt between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(repay_date, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and if('${v_sdate}' < date_format('${v_sdate}','%Y0701'),date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0101') and '${v_sdate}'
				,date_format(unguar_dt, '%Y%m%d') between date_format('${v_sdate}','%Y0701') and '${v_sdate}' )
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select code,                            -- 项目id
                create_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t7 on t1.guar_id = t7.code
group by nd_proj_mgr_name;
commit;

insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
	'年报' as report_type,
	'项目经理' as group_type,
	nd_proj_mgr_name,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then repayment_amt
		else 0 end)                                                                 as start_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') < date_format('${v_sdate}','%Y0101') then 1 else 0 end)  as start_cnt,
	sum(if(now_guar_amt is null, 0, now_guar_amt))                                      as now_guar_amt,
	count(t4.guar_id)                                                                   as now_guar_cnt,
	sum(if(now_repayment_amt is null, 0, now_repayment_amt))                            as now_repayment_amt,
	count(t6.guar_id)                                                                   as now_repayment_cnt,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then guar_amt else 0 end) -
	sum(case
		when date_format(repayment_date, '%Y%m%d') <= '${v_sdate}' then repayment_amt
		else 0 end)                                                                 as end_balance,
	sum(case when date_format(loan_reg_dt, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end) as end_cnt
from (
         select guar_id,    -- 业务id
                guar_amt,   -- 放款金额
                loan_reg_dt -- 放款登记日期
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
     ) t1
         left join
     (
         select guar_id,   -- 业务编号
                project_id -- 项目id
         from dw_base.dwd_guar_info_stat
         where day_id = '${v_sdate}'
     ) t2 on t1.guar_id = t2.guar_id
         left join
     (
         select project_id,                                            -- 项目id
                sum(actual_repayment_amount) / 10000 as repayment_amt, -- 还款金额
                max(repay_date)                      as repayment_date -- 还款日期
         from dw_nd.ods_t_biz_proj_repayment_detail
         group by project_id
     ) t3 on t2.project_id = t3.project_id
         left join
     (
         select guar_id,                 -- 业务id
                guar_amt as now_guar_amt -- 放款金额
         from dw_base.dwd_guar_info_all
         where day_id = '${v_sdate}'
           and data_source = '担保业务管理系统新'
           and item_stt in ('已放款', '已代偿', '已解保')
           and left(loan_reg_dt,4) = left('${v_sdate}',4)
     ) t4 on t1.guar_id = t4.guar_id
         left join
     (
         select project_id,                                               -- 项目id
                sum(actual_repayment_amount) / 10000 as now_repayment_amt -- 当期还款金额
         from dw_nd.ods_t_biz_proj_repayment_detail
         where left(repay_date,4) = left('${v_sdate}',4)
         group by project_id
     ) t5 on t2.project_id = t5.project_id
         left join
     (
         select guar_id -- 业务编号
         from dw_base.dwd_guar_info_stat -- 取解保日期计算当期还款笔数
         where day_id = '${v_sdate}'
           and left(unguar_dt,4) = left('${v_sdate}',4)
     ) t6 on t1.guar_id = t6.guar_id
         left join
     (
         select code,                            -- 项目id
                create_name as nd_proj_mgr_name, -- 创建者
                rn
         from (
                  select *, row_number() over (partition by code order by db_update_time desc) as rn
                  from dw_nd.ods_t_biz_project_main) t1
         where rn = 1
     ) t7 on t1.guar_id = t7.code
group by nd_proj_mgr_name;
commit;

-- 新旧业务系统合并
insert into dw_base.ads_rpt_tjnd_busi_record_stat_loan
(day_id, -- 数据日期
 report_type,-- 报表类型 (旬报、月报、季报、半年报、年报)
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_guar_amt, -- 当期放款金额(万元)
 now_guar_cnt, -- 当期放款笔数
 now_repayment_amt, -- 当期还款金额
 now_repayment_cnt, -- 当期还款笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
		report_type,
       group_type,
       group_name,
       sum(start_balance),
       sum(start_cnt),
       sum(if(now_guar_amt is null, 0, now_guar_amt)),
       sum(now_guar_cnt),
       sum(if(now_repayment_amt is null, 0, now_repayment_amt)),
       sum(now_repayment_cnt),
       sum(end_balance),
       sum(end_cnt)
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_loan
where day_id = '${v_sdate}'
group by report_type,group_type, group_name;
commit;