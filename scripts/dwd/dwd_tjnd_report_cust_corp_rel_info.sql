-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241216
-- 目标表   :dwd_tjnd_report_cust_corp_rel_info            -- 个人客户名下企业信息表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy        -- 迁移业务宽表
--            dw_base.dwd_nacga_report_guar_info_base_info -- 国农担上报范围表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------

delete
from dw_base.dwd_tjnd_report_cust_corp_rel_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_cust_corp_rel_info
( day_id
, cust_corp_cd -- 个人企业省担编码
, cert_no -- 个人证件号码
, own_comp_name -- 个人名下企业名称
, own_comp_cert_no_typ_cd -- 个人名下企业证件类型代码
, own_comp_cert_no -- 个人名下企业证件号码
, dict_flag)
select '${v_sdate}'                    as day_id
     , concat(id_number, corp_cert_no) as cust_corp_cd -- 个人企业省担编码
     , id_number                                       -- 个人证件号码
     , customer_name                                   -- 个人名下企业名称
     , own_comp_cert_no_typ_cd                         -- 个人名下企业证件类型代码
     , corp_cert_no                                    -- 个人名下企业证件号码
     , 0                               as dict_flag
from (
         select distinct a.id_number                 -- 个人证件号码
                       , c.customer_name             -- 个人名下企业名称
                       , c.own_comp_cert_no_typ_cd   -- 个人名下企业证件类型代码
                       , c.id_number as corp_cert_no -- 个人名下企业证件号码
         from dw_base.dwd_tjnd_yw_guar_info_all_qy a
                  inner join dw_base.dwd_nacga_report_guar_info_base_info b
                             on a.id_business_information = b.biz_id
                  inner join
              (
                  select customer_name                                                                                                      -- 企业名称
                       , id_number                                                                                                          -- 企业证件号码
                       , legal_representative                                                                                               -- 法定代表人
                       , '29'                                                                                    as own_comp_cert_no_typ_cd -- 个人名下企业证件类型代码
                       , legal_representative_id                                                                                            -- 法定代表人证件号码
                       , row_number() over (partition by id_number,legal_representative_id order by lend_reg_dt) as rk
                  from dw_base.dwd_tjnd_yw_guar_info_all_qy a
                  where day_id = '${v_sdate}'
                    and customer_nature = 'enterprise'
              ) c on a.id_number = c.legal_representative_id
         where a.day_id = '${v_sdate}'
           and b.day_id = '${v_sdate}'
           and a.customer_nature = 'person' -- 取自然人客户
           and c.rk = 1
     ) a
;
commit;