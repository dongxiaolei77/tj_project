-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241216
-- 目标表   :dwd_tjnd_report_cust_per_base_info            -- 个人客户信息表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy        -- 迁移业务宽表
--            dw_base.dwd_nacga_report_guar_info_base_info -- 国农担上报范围表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------

delete
from dw_base.dwd_tjnd_report_cust_per_base_info
where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_cust_per_base_info
( day_id
, cert_no_typ_cd -- 证件类型代码
, cust_main_typ_cd -- 客户主体类型代码
, cust_name -- 个人客户姓名
, cert_no -- 证件号码
, gender_cd -- 性别代码
, cert_valid_start_dt -- 证件有效期起始日期
, cert_valid_end_dt -- 证件有效期终止日期
, tel_no -- 手机号码
, educ_cd -- 学历代码
, mail_addr -- 通讯地址
, mgr_stt_cd -- 婚姻状况代码
, coup_name -- 配偶姓名
, coup_cert_typ_cd -- 配偶证件类型代码
, coup_cert_no -- 配偶证件号码
, coup_tel_no -- 配偶手机号码
, dict_flag)
select '${v_sdate}' as day_id
     , cert_type                           -- 证件类型
     , mainbody_type_corp                  -- 客户主体类型代码
     , customer_name                       -- 个人客户姓名
     , id_number                           -- 证件号码
     , SEX          as gender_cd           -- 性别代码
     , null         as cert_valid_start_dt -- 证件有效期起始日期
     , null         as cert_valid_end_dt   -- 证件有效期终止日期
     , tel          as tel_no              -- 手机号码
     , null         as educ_cd             -- 学历代码
     , null         as mail_addr           -- 通讯地址
     , MARRIAGE_STATUS                     -- 婚姻状况代码
     , spouse_name                         -- 配偶姓名
     , case
           when spouse_id_no is not null then '10'
           else null
    end             as coup_cert_typ_cd    -- 配偶证件类型代码
     , spouse_id_no                        -- 配偶证件号码
     , spouse_tel                          -- 配偶手机号码
     , 0            as dict_flag
from (
         select a.cert_type                                                                           -- 证件类型
              , a.mainbody_type_corp                                                                  -- 客户主体类型代码
              , a.customer_name                                                                       -- 个人客户姓名
              , a.id_number                                                                           -- 证件号码
              , a.tel
              , a.marriage_sta                                                                        -- 婚姻状况代码
              , a.spouse_name                                                                         -- 配偶姓名
              , a.spouse_id_no                                                                        -- 配偶证件号码
              , if(length(a.spouse_tel) > 11, null, a.spouse_tel)                       as spouse_tel -- 配偶手机号码
              , row_number() over (partition by a.id_number order by lend_reg_dt desc ) as rk
              , c.SEX                                                                                 -- 性别代码
              , c.MARRIAGE_STATUS                                                                     -- 婚姻状况代码
         from dw_base.dwd_tjnd_yw_guar_info_all_qy a
                  inner join dw_base.dwd_nacga_report_guar_info_base_info b
                             on a.id_business_information = b.biz_id
                  inner join dw_nd.ods_tjnd_yw_z_report_base_customers_history c
                             on a.id_business_information = c.ID_BUSINESS_INFORMATION
         where a.day_id = '${v_sdate}'
           and b.day_id = '${v_sdate}'
           and a.customer_nature = 'person' -- 取自然人客户
     ) a
where rk = 1
;
commit;
