-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241218
-- 目标表   :dwd_tjnd_report_proj_base_info                     -- 项目基础信息表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy             -- 迁移业务宽表
--            dw_base.dwd_nacga_report_guar_info_base_info      -- 国农担上报业务范围表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------
delete
from dw_base.dwd_tjnd_report_proj_cntr_agmt_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_proj_cntr_agmt_info
( day_id
, cntr_cont_no -- 反担保合同编号
, proj_no_prov -- 反担保项目编号
, cntr_cont_typ_cd -- 反担保合同种类
, main_signer_name -- 反担保合同签署人
, main_signer_cert_typ_cd -- 反担保合同签署人证件类型代码
, main_signer_cert_no -- 反担保合同签署人证件号
, cntr_cont_begin_dt -- 反担保合同签署日期
, dict_flag)
-- 反担保
select '${v_sdate}'                        as day_id
     , GRLD_NO                             as cntr_cont_no            -- 反担保合同编号
     , b.GUARANTEE_CODE                    as proj_no_prov            -- 项目编号
     , COUNTER_GUARANTEE_CONTRACT_CATEGORY as cntr_cont_typ_cd        -- 反担保合同种类，需补充
     , NAME                                as main_signer_name        -- 反担保合同签署人
     , case
           when LENGTH(trim(a.ID_NUMBER)) = 18 and
                trim(a.ID_NUMBER) regexp
                '^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$'
               then '10'
           when LENGTH(trim(a.ID_NUMBER)) = 18 and trim(a.ID_NUMBER) regexp '^[0-9A-Z]{18}$'
               then '29' -- 18位统一社会信用代码，假设只包含数字和字母
           else null end                   as main_signer_cert_typ_cd -- 反担保合同签署人证件类型代码，需补充
     , trim(a.ID_NUMBER)                   as main_signer_cert_no     -- 反担保合同签署人证件号
     , null                                as cntr_cont_begin_dt      -- 反担保合同签署日期，非必填
     , 0                                   as dict_flag
from dw_nd.ods_tjnd_yw_z_report_afg_counter_guarantor a
         left join dw_base.dwd_tjnd_yw_guar_info_all_qy b
                   on a.ID_BUSINESS_INFORMATION = b.ID_BUSINESS_INFORMATION
         inner join dw_base.dwd_nacga_report_guar_info_base_info c
                    on a.ID_BUSINESS_INFORMATION = c.biz_id
where b.day_id = '${v_sdate}'
  and c.day_id = '${v_sdate}'
  and a.delete_flag is null
-- 抵押
union
select '${v_sdate}'                        as day_id
     , MORT_NO                             as cntr_cont_no            -- 抵押合同编号
     , b.GUARANTEE_CODE                    as proj_no_prov            -- 项目编号
     , COUNTER_GUARANTEE_CONTRACT_CATEGORY as cntr_cont_typ_cd        -- 抵押合同种类，需补充
     , owner                               as main_signer_name        -- 抵押合同签署人
     , case
           when LENGTH(trim(a.ID_NUMBER)) = 18 and
                trim(a.ID_NUMBER) regexp
                '^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$'
               then '10'
           when LENGTH(trim(a.ID_NUMBER)) = 18 and trim(a.ID_NUMBER) regexp '^[0-9A-Z]{18}$'
               then '29' -- 18位统一社会信用代码，假设只包含数字和字母
           else null end                   as main_signer_cert_typ_cd -- 抵押合同签署人证件类型代码，需补充
     , trim(a.ID_NUMBER)                   as main_signer_cert_no     -- 抵押合同签署人证件号，需补充
     , null                                as cntr_cont_begin_dt      -- 抵押合同签署日期，非必填
     , 0                                   as dict_flag
from dw_nd.ods_tjnd_yw_z_report_afg_mortgage_information a
         left join dw_base.dwd_tjnd_yw_guar_info_all_qy b
                   on a.ID_BUSINESS_INFORMATION = b.ID_BUSINESS_INFORMATION
         inner join dw_base.dwd_nacga_report_guar_info_base_info c
                    on a.ID_BUSINESS_INFORMATION = c.biz_id
where b.day_id = '${v_sdate}'
  and c.day_id = '${v_sdate}'
  and a.delete_flag is null
-- 质押
union
select '${v_sdate}'                        as day_id
     , PLED_NO                             as cntr_cont_no            -- 质押合同编号
     , b.GUARANTEE_CODE                    as proj_no_prov            -- 项目编号
     , COUNTER_GUARANTEE_CONTRACT_CATEGORY as cntr_cont_typ_cd        -- 质押合同种类，需补充
     , owner                               as main_signer_name        -- 质押合同签署人
     , case
           when LENGTH(trim(a.ID_NUMBER)) = 18 and
                trim(a.ID_NUMBER) regexp
                '^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$'
               then '10'
           when LENGTH(trim(a.ID_NUMBER)) = 18 and trim(a.ID_NUMBER) regexp '^[0-9A-Z]{18}$'
               then '29' -- 18位统一社会信用代码，假设只包含数字和字母
           else null end                   as main_signer_cert_typ_cd -- 质押合同签署人证件类型代码，需补充
     , trim(a.ID_NUMBER)                   as main_signer_cert_no     -- 质押合同签署人证件号，需补充
     , null                                as cntr_cont_begin_dt      -- 质押合同签署日期，非必填
     , 0                                   as dict_flag
from dw_nd.ods_tjnd_yw_z_report_afg_pledgeand_information a
         left join dw_base.dwd_tjnd_yw_guar_info_all_qy b
                   on a.ID_BUSINESS_INFORMATION = b.ID_BUSINESS_INFORMATION
         inner join dw_base.dwd_nacga_report_guar_info_base_info c
                    on a.ID_BUSINESS_INFORMATION = c.biz_id
where b.day_id = '${v_sdate}'
  and c.day_id = '${v_sdate}'
  and a.delete_flag is null;

commit;
