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
)
-- 反担保
select '${v_sdate}'                        as day_id
     , GRLD_NO                             as cntr_cont_no            -- 反担保合同编号
     , b.GUARANTEE_CODE                    as proj_no_prov            -- 项目编号
     , COUNTER_GUARANTEE_CONTRACT_CATEGORY as cntr_cont_typ_cd        -- 反担保合同种类，需补充
     , NAME                                as main_signer_name        -- 反担保合同签署人
     , case
           when LENGTH(trim(a.ID_NUMBER)) = 18 and
                trim(a.ID_NUMBER) regexp '^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$'
               then '10'
           when LENGTH(trim(a.ID_NUMBER)) = 18 and trim(a.ID_NUMBER) regexp '^[0-9A-Z]{18}$' then '29' -- 18位统一社会信用代码，假设只包含数字和字母
           else null end                   as main_signer_cert_typ_cd -- 反担保合同签署人证件类型代码，需补充
     , trim(a.ID_NUMBER)                   as main_signer_cert_no     -- 反担保合同签署人证件号
     , null                                as cntr_cont_begin_dt      -- 反担保合同签署日期，非必填
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
                trim(a.ID_NUMBER) regexp '^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$'
               then '10'
           when LENGTH(trim(a.ID_NUMBER)) = 18 and trim(a.ID_NUMBER) regexp '^[0-9A-Z]{18}$' then '29' -- 18位统一社会信用代码，假设只包含数字和字母
           else null end                   as main_signer_cert_typ_cd -- 抵押合同签署人证件类型代码，需补充
     , trim(a.ID_NUMBER)                   as main_signer_cert_no     -- 抵押合同签署人证件号，需补充
     , null                                as cntr_cont_begin_dt      -- 抵押合同签署日期，非必填
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
                trim(a.ID_NUMBER) regexp '^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$'
               then '10'
           when LENGTH(trim(a.ID_NUMBER)) = 18 and trim(a.ID_NUMBER) regexp '^[0-9A-Z]{18}$' then '29' -- 18位统一社会信用代码，假设只包含数字和字母
           else null end                   as main_signer_cert_typ_cd -- 质押合同签署人证件类型代码，需补充
     , trim(a.ID_NUMBER)                   as main_signer_cert_no     -- 质押合同签署人证件号，需补充
     , null                                as cntr_cont_begin_dt      -- 质押合同签署日期，非必填
from dw_nd.ods_tjnd_yw_z_report_afg_pledgeand_information a
         left join dw_base.dwd_tjnd_yw_guar_info_all_qy b
                   on a.ID_BUSINESS_INFORMATION = b.ID_BUSINESS_INFORMATION
         inner join dw_base.dwd_nacga_report_guar_info_base_info c
                    on a.ID_BUSINESS_INFORMATION = c.biz_id
where b.day_id = '${v_sdate}'
  and c.day_id = '${v_sdate}'
  and a.delete_flag is null;

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
)
select distinct     '${v_sdate}'                        as day_id
      t1.cntr_cont_no                 -- 省担反担保合同编号
     ,t1.proj_no                      -- 省农担担保项目编号
     ,t1.cntr_cont_typ_cd              -- 反担保合同种类
     ,t1.main_signer_name              -- 反担保合同签署人
     ,t1.main_signer_cert_typ_cd        -- 反担保合同签署人证件类型代码
     ,trim(t1.main_signer_cert_no)  -- 反担保合同签署人证件号码
     ,null as cntr_cont_begin_dt        -- 反担保合同签署日期
from 
(
     select a.count_cont_code           as cntr_cont_no
          ,'10000'                           as cntr_cont_typ_cd /*保证*/
          ,a.ct_guar_person_name             as main_signer_name
          ,a.ct_guar_person_main_type   as main_signer_cert_typ_cd
          ,a.ct_guar_person_id_no            as main_signer_cert_no
          ,b.code                            as proj_no
     from
     (
          select project_id
               ,ct_guar_person_name           -- 反担保人名称
               ,ct_guar_person_main_type      -- 反担保人主体类型
               ,ct_guar_person_id_no          -- 反担保人证件号码
               ,count_cont_code               -- 反担保合同号(系统生成)
          from 
          (
               select project_id
                    ,ct_guar_person_name           -- 反担保人名称
                    ,ct_guar_person_main_type      -- 反担保人主体类型
                    ,ct_guar_person_id_no          -- 反担保人证件号码
                    ,count_cont_code               -- 反担保合同号(系统生成)
                    ,is_delete
                    ,row_number()over(partition by id order by db_update_time desc) as rk
               from dw_nd.ods_t_ct_guar_person
          )a
          where rk =1 and is_delete = 0 and count_cont_code is not null
     )a
     inner join 
     (
          select id 
               ,code 
          from 
          (
               select id
                    ,code
                    ,row_number()over(partition by id order by db_update_time desc) as rk 
               from dw_nd.ods_t_biz_project_main
          )a
          where rk = 1
     )b on a.project_id = b.id
     
     
     union all 
     select distinct 
          mort_con_code                      as cntr_cont_no                                            -- 省担反担保合同编号
          ,case when pawn_movable_type = '01' OR pawn_name regexp '设备|渔船' THEN '20002' -- 抵押-农业设备
               WHEN pawn_movable_type = '02' THEN '20008' -- 抵押-房地产
               WHEN pawn_movable_type = '03' OR pawn_name regexp '生物资产' THEN '20007'-- 抵押-生物资产
               WHEN pawn_name regexp '集体建设用地使用权|土地' THEN '20010' -- 抵押-集体土地建设用地使用权
               WHEN pawn_name regexp '海域使用权' THEN '20011' -- 抵押-海域使用权
               WHEN pawn_name regexp '车辆' THEN '20001' -- 抵押-车辆
               WHEN pawn_name regexp '设施' THEN '20004' -- 抵押-农业设施
               WHEN pawn_name regexp '存货' THEN '20006' -- 抵押-存货
               WHEN pawn_name regexp '海域' THEN '20011' -- 抵押-海域使用权
               WHEN pawn_name regexp'房|不动产|区|住房|楼|公寓|商铺|住宅|路|单元|室|宅基地|府邸|棚|舍|厂房|仓库|车间|库' THEN '20008'
               else '20008' /*与业务部室确认后映射成上报标准*/
               end as cntr_cont_typ_cd                                                                             -- 抵押合同种类
          ,t1.mortgagor                      as main_signer_name                                                        -- 抵押合同签署人
          ,mortgagor_main_type               as main_signer_cert_typ_cd                                              -- 抵押合同签署人证件类型代码
          ,t1.mortgagor_id_no                as main_signer_cert_no                                                     -- 抵押合同签署人证件号码
          ,t1.proj_no
     from 
     (
          select a.mort_con_code
               ,a.pawn_movable_type
               ,a.pawn_name
               ,a.mortgagor
               ,a.mortgagor_main_type
               ,a.mortgagor_id_no
               ,b.code                            as proj_no
          from 
          (
               select id
                    ,project_id
                    ,pawn_movable_type
                    ,pawn_name
                    ,mortgagor
                    ,mortgagor_main_type
                    ,mortgagor_id_no
                    ,mort_con_code
                    ,is_delete
                    ,row_number()over(partition by id order by db_update_time desc) as rk
               from dw_nd.ods_t_ct_guar_mortgage 
          )a 
          inner join 
          (
               select id 
                    ,code 
               from 
               (
                    select id
                         ,code
                         ,row_number()over(partition by id order by db_update_time desc) as rk 
                    from dw_nd.ods_t_biz_project_main
               )a
               where rk = 1
          )b on a.project_id = b.id     
          where a.rk =1 and a.is_delete = 0 and a.mort_con_code is not null
     )t1 -- 抵押合同信息表--协议域
)t1
inner join dw_base.dwd_tjnd_report_biz_no_base t2 
on t1.proj_no = t2.biz_no and t2.day_id = '${v_sdate}'