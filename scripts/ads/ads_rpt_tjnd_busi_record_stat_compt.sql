-- ---------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250417
-- 目标表   ：dw_base.ads_rpt_tjnd_busi_record_stat_loan 业务状况-放款
-- 源表     ：
--          旧业务系统
--          dw_nd.ods_tjnd_yw_afg_business_infomation                   业务申请表
--          dw_nd.ods_tjnd_yw_base_customers_history                    BO,客户信息历史表,NEW
--          dw_nd.ods_tjnd_yw_base_product_management                   BO,产品管理,NEW
--          dw_nd.ods_tjnd_yw_bh_compensatory                           代偿表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking                      追偿跟踪表
--          dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail               追偿跟踪详情表
--          新业务系统
--
-- 备注     ：
-- 变更记录 ：
-- ---------------------------------------
-- 重跑逻辑
delete
from dw_base.ads_rpt_tjnd_busi_record_stat_compt
where day_id = '${v_sdate}';
commit;

-- 创建临时表存储
drop table if exists dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt;
create table dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(
    day_id           varchar(8) comment '数据日期',
    group_type       varchar(50) comment '统计类型',
    group_name       varchar(100) comment '分组名称',
    start_balance    decimal(36, 6) comment '期初余额(万元)',
    start_cnt        int comment '期初笔数',
    now_compt_amt    decimal(36, 6) comment '当期代偿金额(万元)',
    now_compt_cnt    int comment '当期代偿笔数',
    now_recovery_amt decimal(36, 6) comment '当期收回金额(万元)',
    now_recovery_cnt int comment '当期收回笔数',
    end_balance      decimal(36, 6) comment '期末余额(万元)',
    end_cnt          int comment '期末笔数'
) comment '临时-业务部-业务状况-代偿' collate = utf8mb4_bin;
commit;

-- 旧系统逻辑
-- 按银行
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '银行'                                                                                      as group_type,
       bank_name                                                                                 as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t4.ID_CFBIZ_UNDERWRITING)                                                           as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select id,                    -- 业务id
                COOPERATIVE_BANK_FIRST -- 银行对应编码
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                   -- 业务id
                TOTAL_COMPENSATION / 10000 as compt_amt, -- 代偿金额
                PAYMENT_DATE               as compt_date -- 代偿日期
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                  -- 业务id
                sum(CUR_RECOVERY) / 10000 as recovery_amt, -- 追偿金额
                max(t2.CREATED_TIME)      as recovery_date -- 追偿登记日期
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                      -- 业务id 当期代偿笔数
                TOTAL_COMPENSATION / 10000 as now_compt_amt -- 当期代偿金额
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
           and date_format(PAYMENT_DATE, '%Y%m%d') = '${v_sdate}'
     ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                     -- 业务id
                sum(CUR_RECOVERY) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         where date_format(t2.CREATED_TIME, '%Y%m%d') = '${v_sdate}'
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.ID = t5.ID_CFBIZ_UNDERWRITING
         left join
     (
         select fieldcode,                 -- 银行对应编码
                enterfullname as bank_name -- 银行名称
         from dw_nd.ods_tjnd_yw_base_enterprise
         where parentid = 200
     ) t6 on t1.COOPERATIVE_BANK_FIRST = t6.fieldcode
;
commit;

-- 按产品
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '产品'                                                                                      as group_type,
       PRODUCT_NAME                                                                              as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t4.ID_CFBIZ_UNDERWRITING)                                                           as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select id,           -- 业务id
                PRODUCT_GRADE -- 产品对应编码
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                   -- 业务id
                TOTAL_COMPENSATION / 10000 as compt_amt, -- 代偿金额
                PAYMENT_DATE               as compt_date -- 代偿日期
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                  -- 业务id
                sum(CUR_RECOVERY) / 10000 as recovery_amt, -- 追偿金额
                max(t2.CREATED_TIME)      as recovery_date -- 追偿登记日期
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                      -- 业务id 当期代偿笔数
                TOTAL_COMPENSATION / 10000 as now_compt_amt -- 当期代偿金额
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
           and date_format(PAYMENT_DATE, '%Y%m%d') = '${v_sdate}'
     ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                     -- 业务id
                sum(CUR_RECOVERY) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         where date_format(t2.CREATED_TIME, '%Y%m%d') = '${v_sdate}'
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.ID = t5.ID_CFBIZ_UNDERWRITING
         left join
     (
         select fieldcode,   -- 产品编码
                PRODUCT_NAME -- 产品名称
         from dw_nd.ods_tjnd_yw_base_product_management
     ) t6 on t1.PRODUCT_GRADE = t6.fieldcode
group by PRODUCT_NAME
;
commit;

-- 行业归类
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '行业归类'                                                                                    as group_type,
       case
           when INDUSTRY_CATEGORY_COMPANY = '0' then '农产品初加工'
           when INDUSTRY_CATEGORY_COMPANY = '1' then '粮食种植'
           when INDUSTRY_CATEGORY_COMPANY = '2' then '重要、特色农产品种植'
           when INDUSTRY_CATEGORY_COMPANY = '3' then '其他畜牧业'
           when INDUSTRY_CATEGORY_COMPANY = '4' then '生猪养殖'
           when INDUSTRY_CATEGORY_COMPANY = '5' then '农产品流通'
           when INDUSTRY_CATEGORY_COMPANY = '6' then '渔业生产'
           when INDUSTRY_CATEGORY_COMPANY = '7' then '农资、农机、农技等农业社会化服务'
           when INDUSTRY_CATEGORY_COMPANY = '8' then '农业新业态'
           when INDUSTRY_CATEGORY_COMPANY = '9' then '农田建设'
           when INDUSTRY_CATEGORY_COMPANY = '10' then '其他农业项目'
           end                                                                                   as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t4.ID_CFBIZ_UNDERWRITING)                                                           as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select id,         -- 业务id
                ID_CUSTOMER -- 客户id
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                   -- 业务id
                TOTAL_COMPENSATION / 10000 as compt_amt, -- 代偿金额
                PAYMENT_DATE               as compt_date -- 代偿日期
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                  -- 业务id
                sum(CUR_RECOVERY) / 10000 as recovery_amt, -- 追偿金额
                max(t2.CREATED_TIME)      as recovery_date -- 追偿登记日期
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                      -- 业务id 当期代偿笔数
                TOTAL_COMPENSATION / 10000 as now_compt_amt -- 当期代偿金额
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
           and date_format(PAYMENT_DATE, '%Y%m%d') = '${v_sdate}'
     ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                     -- 业务id
                sum(CUR_RECOVERY) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         where date_format(t2.CREATED_TIME, '%Y%m%d') = '${v_sdate}'
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.ID = t5.ID_CFBIZ_UNDERWRITING
         left join
     (
         select id,                       -- 客户id
                INDUSTRY_CATEGORY_COMPANY -- 行业分类（公司）
         from dw_nd.ods_tjnd_yw_base_customers_history
     ) t6 on t1.ID_CUSTOMER = t6.ID
group by INDUSTRY_CATEGORY_COMPANY
;
commit;

-- 按办事处
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '办事处'                                                                                     as group_type,
       case
           when branch_off = 'YW_NHDLBSC' then '宁河东丽办事处'
           when branch_off = 'YW_JNBHXQBSC' then '津南滨海新区办事处'
           when branch_off = 'YW_WQBCBSC' then '武清北辰办事处'
           when branch_off = 'YW_XQJHBSC' then '西青静海办事处'
           when branch_off = 'YW_JZBSC' then '蓟州办事处'
           when branch_off = 'YW_BDBSC' then '宝坻办事处'
           end                                                                                   as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t4.ID_CFBIZ_UNDERWRITING)                                                           as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select id,                      -- 业务id
                enter_code as branch_off -- 办事处编码
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                   -- 业务id
                TOTAL_COMPENSATION / 10000 as compt_amt, -- 代偿金额
                PAYMENT_DATE               as compt_date -- 代偿日期
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                  -- 业务id
                sum(CUR_RECOVERY) / 10000 as recovery_amt, -- 追偿金额
                max(t2.CREATED_TIME)      as recovery_date -- 追偿登记日期
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                      -- 业务id 当期代偿笔数
                TOTAL_COMPENSATION / 10000 as now_compt_amt -- 当期代偿金额
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
           and date_format(PAYMENT_DATE, '%Y%m%d') = '${v_sdate}'
     ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                     -- 业务id
                sum(CUR_RECOVERY) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         where date_format(t2.CREATED_TIME, '%Y%m%d') = '${v_sdate}'
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.ID = t5.ID_CFBIZ_UNDERWRITING
group by branch_off
;
commit;

-- 按区域
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '区域'                                                                                      as group_type,
       area_name                                                                                 as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t4.ID_CFBIZ_UNDERWRITING)                                                           as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select id,                                              -- 业务id
                JSON_UNQUOTE(JSON_EXTRACT(area, '$[1]')) as area -- 转换为区县
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                   -- 业务id
                TOTAL_COMPENSATION / 10000 as compt_amt, -- 代偿金额
                PAYMENT_DATE               as compt_date -- 代偿日期
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                  -- 业务id
                sum(CUR_RECOVERY) / 10000 as recovery_amt, -- 追偿金额
                max(t2.CREATED_TIME)      as recovery_date -- 追偿登记日期
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                      -- 业务id 当期代偿笔数
                TOTAL_COMPENSATION / 10000 as now_compt_amt -- 当期代偿金额
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
           and date_format(PAYMENT_DATE, '%Y%m%d') = '${v_sdate}'
     ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                     -- 业务id
                sum(CUR_RECOVERY) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         where date_format(t2.CREATED_TIME, '%Y%m%d') = '${v_sdate}'
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.ID = t5.ID_CFBIZ_UNDERWRITING
         left join
     dw_base.dim_area_info t6 on t1.area = t6.area_cd
group by area_name
;
commit;

-- 按一级支行
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '银行一级支行'                                                                                  as group_type,
       bank_name                                                                                 as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t4.ID_CFBIZ_UNDERWRITING)                                                           as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select id,                     -- 业务id
                COOPERATIVE_BANK_SECOND -- 二级支行编码
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                   -- 业务id
                TOTAL_COMPENSATION / 10000 as compt_amt, -- 代偿金额
                PAYMENT_DATE               as compt_date -- 代偿日期
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                  -- 业务id
                sum(CUR_RECOVERY) / 10000 as recovery_amt, -- 追偿金额
                max(t2.CREATED_TIME)      as recovery_date -- 追偿登记日期
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                      -- 业务id 当期代偿笔数
                TOTAL_COMPENSATION / 10000 as now_compt_amt -- 当期代偿金额
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
           and date_format(PAYMENT_DATE, '%Y%m%d') = '${v_sdate}'
     ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                     -- 业务id
                sum(CUR_RECOVERY) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         where date_format(t2.CREATED_TIME, '%Y%m%d') = '${v_sdate}'
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.ID = t5.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.fieldcode,
                concat(t2.enterfullname, t1.enterfullname) as bank_name
         from dw_nd.ods_tjnd_yw_base_enterprise t1
                  left join dw_nd.ods_tjnd_yw_base_enterprise t2 on t1.parentid = t2.enterid
     ) t6 on t1.COOPERATIVE_BANK_SECOND = t6.fieldcode
group by bank_name
;
commit;

-- 按项目经理核算
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '项目经理'                                                                                    as group_type,
       BUSINESS_SP_USER_NAME                                                                     as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t4.ID_CFBIZ_UNDERWRITING)                                                           as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select id,                   -- 业务id
                BUSINESS_SP_USER_NAME -- 农担项目经理
         from dw_nd.ods_tjnd_yw_afg_business_infomation
     ) t1
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                   -- 业务id
                TOTAL_COMPENSATION / 10000 as compt_amt, -- 代偿金额
                PAYMENT_DATE               as compt_date -- 代偿日期
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
     ) t2 on t1.id = t2.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                  -- 业务id
                sum(CUR_RECOVERY) / 10000 as recovery_amt, -- 追偿金额
                max(t2.CREATED_TIME)      as recovery_date -- 追偿登记日期
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t3 on t1.id = t3.ID_CFBIZ_UNDERWRITING
         left join
     (
         select ID_CFBIZ_UNDERWRITING,                      -- 业务id 当期代偿笔数
                TOTAL_COMPENSATION / 10000 as now_compt_amt -- 当期代偿金额
         from dw_nd.ods_tjnd_yw_bh_compensatory
         where status = 1
           and over_tag = 'BJ'
           and DELETED_BY is null
           and date_format(PAYMENT_DATE, '%Y%m%d') = '${v_sdate}'
     ) t4 on t1.ID = t4.ID_CFBIZ_UNDERWRITING
         left join
     (
         select t1.ID_CFBIZ_UNDERWRITING,                     -- 业务id
                sum(CUR_RECOVERY) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_tjnd_yw_bh_recovery_tracking t1
                  left join dw_nd.ods_tjnd_yw_bh_recovery_tracking_detail t2
                            on t1.id = t2.ID_RECOVERY_TRACKING and t1.STATUS = 1 and t2.STATUS = 1
         where date_format(t2.CREATED_TIME, '%Y%m%d') = '${v_sdate}'
         group by t1.ID_CFBIZ_UNDERWRITING
     ) t5 on t1.ID = t5.ID_CFBIZ_UNDERWRITING
group by BUSINESS_SP_USER_NAME
;
commit;

-- --------------------------------------
-- 新系统逻辑
-- 按银行
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '银行'                                                                                      as group_type,
       gnd_dept_name                                                                             as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t5.guar_id)                                                                         as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select guar_id -- 业务id
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
         select guar_id,
                compt_amt  as compt_amt, -- 代偿金额
                compt_time as compt_date -- 代偿拨付日期
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as recovery_amt, -- 追偿金额
                max(real_repay_date)          as recovery_date -- 追偿实际还款时间
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select guar_id,                   -- 当期代偿笔数
                compt_amt as now_compt_amt -- 当期代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           and date_format(compt_time, '%Y%m%d') = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         where date_format(real_repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t6 on t2.project_id = t6.project_id
         left join
     (
         select biz_no,
                gnd_dept_name
         from dw_base.dwd_tjnd_report_biz_loan_bank
         where day_id = '{v_sdate}'
     ) t7 on t1.guar_id = t7.biz_no
group by gnd_dept_name;
commit;

-- 按产品
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '产品'                                                                                      as group_type,
       guar_prod                                                                                 as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t5.guar_id)                                                                         as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select guar_id,  -- 业务id
                guar_prod -- 担保产品
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
         select guar_id,
                compt_amt  as compt_amt, -- 代偿金额
                compt_time as compt_date -- 代偿拨付日期
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as recovery_amt, -- 追偿金额
                max(real_repay_date)          as recovery_date -- 追偿实际还款时间
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select guar_id,                   -- 当期代偿笔数
                compt_amt as now_compt_amt -- 当期代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           and date_format(compt_time, '%Y%m%d') = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         where date_format(real_repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t6 on t2.project_id = t6.project_id
group by guar_prod;
commit;

-- 按行业归类
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '行业归类'                                                                                    as group_type,
       guar_class                                                                                as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t5.guar_id)                                                                         as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select guar_id,   -- 业务id
                guar_class -- 国担分类
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
         select guar_id,
                compt_amt  as compt_amt, -- 代偿金额
                compt_time as compt_date -- 代偿拨付日期
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as recovery_amt, -- 追偿金额
                max(real_repay_date)          as recovery_date -- 追偿实际还款时间
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select guar_id,                   -- 当期代偿笔数
                compt_amt as now_compt_amt -- 当期代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           and date_format(compt_time, '%Y%m%d') = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         where date_format(real_repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t6 on t2.project_id = t6.project_id
group by guar_class;
commit;

-- 按办事处
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '办事处'                                                                                     as group_type,
       case
           when branch_off = 'NHDLBranch' then '宁河东丽办事处'
           when branch_off = 'JNBHXQBranch' then '津南滨海新区办事处'
           when branch_off = 'WQBCBranch' then '武清北辰办事处'
           when branch_off = 'XQJHBranch' then '西青静海办事处'
           when branch_off = 'JZBranch' then '蓟州办事处'
           when branch_off = 'BDBranch' then '宝坻办事处'
           end                                                                                   as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t5.guar_id)                                                                         as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select guar_id,            -- 业务id
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
         select guar_id,
                compt_amt  as compt_amt, -- 代偿金额
                compt_time as compt_date -- 代偿拨付日期
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as recovery_amt, -- 追偿金额
                max(real_repay_date)          as recovery_date -- 追偿实际还款时间
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select guar_id,                   -- 当期代偿笔数
                compt_amt as now_compt_amt -- 当期代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           and date_format(compt_time, '%Y%m%d') = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         where date_format(real_repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t6 on t2.project_id = t6.project_id
         left join
     (
         select CITY_NAME_,              -- 区县名称
                ROLE_CODE_ as branch_off -- 办事处编码
         from dw_base.dwd_imp_area_branch
     ) t7 on t1.area = t7.CITY_NAME_
group by branch_off;
commit;

-- 按区域
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '区域'                                                                                      as group_type,
       area                                                                                      as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t5.guar_id)                                                                         as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select guar_id,            -- 业务id
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
         select guar_id,
                compt_amt  as compt_amt, -- 代偿金额
                compt_time as compt_date -- 代偿拨付日期
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as recovery_amt, -- 追偿金额
                max(real_repay_date)          as recovery_date -- 追偿实际还款时间
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select guar_id,                   -- 当期代偿笔数
                compt_amt as now_compt_amt -- 当期代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           and date_format(compt_time, '%Y%m%d') = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         where date_format(real_repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t6 on t2.project_id = t6.project_id
group by area;
commit;

-- 按银行一级支行
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '银行一级支行'                                                                                  as group_type,
       loan_bank                                                                                 as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t5.guar_id)                                                                         as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select guar_id,  -- 业务id
                loan_bank -- 贷款银行
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
         select guar_id,
                compt_amt  as compt_amt, -- 代偿金额
                compt_time as compt_date -- 代偿拨付日期
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as recovery_amt, -- 追偿金额
                max(real_repay_date)          as recovery_date -- 追偿实际还款时间
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select guar_id,                   -- 当期代偿笔数
                compt_amt as now_compt_amt -- 当期代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           and date_format(compt_time, '%Y%m%d') = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         where date_format(real_repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t6 on t2.project_id = t6.project_id
group by loan_bank;
commit;

-- 按项目经理
insert into dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}'                                                                              as day_id,
       '项目经理'                                                                                    as group_type,
       nd_proj_mgr_name                                                                          as group_name,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') < '${v_sdate}' then recovery_amt end)  as start_balance,
       sum(case when date_format(compt_date, '%Y%m%d') < '${v_sdate}' then 1 else 0 end)         as start_cnt,
       sum(now_compt_amt)                                                                        as now_compt_amt,
       count(t5.guar_id)                                                                         as now_compt_cnt,
       sum(now_recovery_amt)                                                                     as now_recovery_amt,
       sum(if(compt_amt -
              (case when date_format(recovery_date, '%Y%m%d') = '${v_sdate}' then recovery_amt else 0 end)
                  <= 0, 1, 0))                                                                   as now_recovery_cnt,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then compt_amt end) -
       sum(case when date_format(recovery_date, '%Y%m%d') <= '${v_sdate}' then recovery_amt end) as end_balance,
       sum(case when date_format(compt_date, '%Y%m%d') <= '${v_sdate}' then 1 else 0 end)        as end_cnt
from (
         select guar_id -- 业务id
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
         select guar_id,
                compt_amt  as compt_amt, -- 代偿金额
                compt_time as compt_date -- 代偿拨付日期
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
     ) t3 on t1.guar_id = t3.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as recovery_amt, -- 追偿金额
                max(real_repay_date)          as recovery_date -- 追偿实际还款时间
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         group by project_id
     ) t4 on t2.project_id = t4.project_id
         left join
     (
         select guar_id,                   -- 当期代偿笔数
                compt_amt as now_compt_amt -- 当期代偿金额
         from dw_base.dwd_guar_compt_info
         where day_id = '${v_sdate}'
           and date_format(compt_time, '%Y%m%d') = '${v_sdate}'
     ) t5 on t1.guar_id = t5.guar_id
         left join
     (
         select t1.project_id,
                sum(t2.shou_comp_amt) / 10000 as now_recovery_amt -- 当期追偿金额
         from dw_nd.ods_t_biz_proj_recovery_record t1
                  left join dw_nd.ods_t_biz_proj_recovery_repay_detail_record t2 on t1.reco_id = t2.record_id
         where date_format(real_repay_date, '%Y%m%d') = '${v_sdate}'
         group by project_id
     ) t6 on t2.project_id = t6.project_id
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


-- 新旧系统数据合并
insert into dw_base.ads_rpt_tjnd_busi_record_stat_compt
(day_id, -- 数据日期
 group_type, -- 统计类型
 group_name, -- 分组名称
 start_balance, -- 期初余额(万元)
 start_cnt, -- 期初笔数
 now_compt_amt, -- 当期代偿金额(万元)
 now_compt_cnt, -- 当期代偿笔数
 now_recovery_amt, -- 当期收回金额(万元)
 now_recovery_cnt, -- 当期收回笔数
 end_balance, -- 期末余额(万元)
 end_cnt -- 期末笔数
)
select '${v_sdate}' as day_id,
       group_type,
       group_name,
       sum(start_balance),
       sum(start_cnt),
       sum(now_compt_amt),
       sum(now_compt_cnt),
       sum(now_recovery_amt),
       sum(now_recovery_cnt),
       sum(end_balance),
       sum(end_cnt)
from dw_base.tmp_ads_rpt_tjnd_busi_record_stat_compt
where day_id = '${v_sdate}'
group by group_type, group_name;
commit;