-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241216
-- 目标表   :  dwd_nacga_report_guar_info_base_info        -- 国农担上报范围表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy        -- 迁移业务宽表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------

delete
from dw_base.dwd_nacga_report_guar_info_base_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_nacga_report_guar_info_base_info
( day_id
, biz_no
, biz_id
, proj_no
, proj_id
, source)
select distinct '${v_sdate}'              as day_id
              , a.guarantee_code          as biz_no
              , a.id_business_information as biz_id
              , a.guarantee_code          as proj_no
              , a.id_business_information as proj_id
              , 'old'                     as source -- 数据来源 老业务系统
from dw_base.dwd_tjnd_yw_guar_info_all_qy a
         left join dw_nd.ods_tjnd_yw_afg_business_infomation b
                   on a.id_business_information = b.id
         left join dw_nd.ods_tjnd_yw_z_report_afg_guarantee_relieve c
                   on a.id_business_information = c.id_business_information
where day_id = '${v_sdate}'
  and -- 保证责任失效日期不准确
    (((b.GUR_STATE = 'GT' and lend_reg_dt <= 20241231) or
      date_format(c.created_time, '%Y%m%d') >= 20250101) -- 2025年1月1日在保  GT(在保)、ED（解保）、DFK（待放款）、ZZ（终止）
        or lend_reg_dt >= 20250101 -- 2025年1月1日以来纳入在保
        or (is_compt = 1 and payment_date >= 20250101)) -- 2025年1月1日新增已代偿业务
;
commit;
