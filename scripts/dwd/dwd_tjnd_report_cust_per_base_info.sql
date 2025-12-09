-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241216
-- 目标表   :dwd_tjnd_report_cust_per_base_info            -- 个人客户信息表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy        -- 迁移业务宽表
--            dw_base.dwd_nacga_report_guar_info_base_info -- 国农担上报范围表
-- 备注     ：
-- 变更记录 ：20250219 zhangruwen 表结构配偶国家地区
--          wangyj    20250513  合并新老客户信息，优先取新系统数据，保证客户唯一
--          20250915  补充缺失的配偶电话号码
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
select day_id
     , cert_type
     , mainbody_type_corp
     , customer_name
     , id_number
     , gender_cd
     , cert_valid_start_dt
     , cert_valid_end_dt
     , tel_no
     , educ_cd
     , mail_addr
     , MARRIAGE_STATUS
     , spouse_name
     , coup_cert_typ_cd
     , spouse_id_no
     , spouse_tel
     , dict_flag
from (
         select *
              , row_number() over (partition by id_number order by dict_flag desc) as rk
         from (
                  select '${v_sdate}' as day_id
                       , case
                             when cert_type = '1' then '10'
                             when cert_type = '2' then '29'
                      end             as cert_type           -- 证件类型
                       , mainbody_type_corp                  -- 客户主体类型代码
                       , customer_name                       -- 个人客户姓名
                       , id_number                           -- 证件号码
                       , case
                             when SEX = '0' then '1'
                             when SEX = '1' then '2'
                      end             as gender_cd           -- 性别代码
                       , null         as cert_valid_start_dt -- 证件有效期起始日期
                       , null         as cert_valid_end_dt   -- 证件有效期终止日期
                       , tel          as tel_no              -- 手机号码
                       , null         as educ_cd             -- 学历代码
                       , null         as mail_addr           -- 通讯地址
                       , case
                             when MARRIAGE_STATUS = '0' then '10'
                             when MARRIAGE_STATUS = '1' then '20'
                             when MARRIAGE_STATUS = '2' then '30'
                             when MARRIAGE_STATUS = '3' then '40'
                             else '99'
                      end             as MARRIAGE_STATUS     -- 婚姻状况代码
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
                                    inner join dw_nd.ods_creditmid_v2_z_migrate_base_customers_history c
                                               on a.id_business_information = c.ID_BUSINESS_INFORMATION
                           where a.day_id = '${v_sdate}'
                             and b.day_id = '${v_sdate}'
                             and a.customer_nature = 'person' -- 取自然人客户
                       ) a
                  where rk = 1
                  union all
                  select '${v_sdate}'                                       as day_id
                       , '10'                                               as cert_no_typ_cd   -- 证件类型代码 /*固定值为“身份证号”*/
                       , '01'                                               as cust_main_typ_cd -- 客户主体类型代码 /*固定值为“种养大户”*/
                       , regexp_replace(t1.cust_name, '\t|\n', '')          as cust_name        -- 个人客户姓名 /*剔除特殊字符*/
                       , t1.cert_no                                                             -- 证件号码
                       , coalesce(t3.sex, case
                                              when substr(t1.cert_no, 17, 1) in ('1', '3', '5', '7', '9') then '1'
                                              else '2' end)                 as gender_cd        -- 性别代码 /*从客户基本信息表出，取不到的根据证件号码判断*/
                       , t3.cert_valid_start_dt                                                 -- 证件有效期起始日期
                       , t3.cert_valid_end_dt                                                   -- 证件有效期终止日期
                       , case
                             when length(trim(t1.tel_no)) <> 11 then coalesce(t3.tel, trim(t1.tel_no))
                             else trim(t1.tel_no)
                      end                                                   as tel_no           -- 手机号码 /*手机号码不为11位的，从dwd个人个户信息表补充*/
                       , null                                               as educ_cd          -- 学历代码
                       , t2.mail_addr                                                           -- 通讯地址
                       , if(length(t2.mgr_stt_cd) = 0, '99', t2.mgr_stt_cd) as mgr_stt_cd       -- 婚姻状况代码 /*空值置成“99”*/
                       , t2.coup_name                                                           -- 配偶姓名
                       , case
                             when t2.coup_cert_no is not null then t2.coup_cert_typ_cd
                             else null
                      end                                                   as coup_cert_typ_cd -- 配偶证件类型代码
                       , t2.coup_cert_no                                                        -- 配偶证件号码
                       -- ,null as coup_area_cd	          -- 配偶国家/地区代码
                       , if(trim(t2.coup_tel_no) = 0 or length(trim(t2.coup_tel_no)) != 11, null,
                            trim(t2.coup_tel_no))                           as coup_tel_no      -- 配偶手机号码 /*配偶手机号码不符合校验规则的置空*/
                       , 1                                                  as dict_flag
                  from (
                           select t1.cert_no
                                , t1.cert_no_typ_cd
                                , t1.cust_name
                                , t1.tel_no
                           from (
                                    select t1.cert_no
                                         , '居民身份证' as                                                   cert_no_typ_cd
                                         , t1.cust_name
                                         , t1.tel_no
                                         , row_number()
                                            over (partition by t1.cert_no order by t1.loan_reg_dt desc) rk /*业务宽表里取证件号最新放款登记日期对应数据*/
                                    from dw_base.dwd_guar_info_all t1
                                             inner join dw_base.dwd_tjnd_report_biz_no_base t2
                                                        on t1.guar_id = t2.biz_no
                                                            and t2.day_id = '${v_sdate}'
                                    where t1.day_id = '${v_sdate}'
                                      and (t1.cust_type = '自然人'
                                        or (t1.cust_type is null and length(trim(t1.cust_name)) <= 4)
                                        or t1.cert_no regexp
                                           '^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$'
                                        ) /*筛选符合证件号码校验规则的数据*/
                                      and t1.item_stt in ('已放款', '已解保', '已代偿') /*筛选累保数据*/
                                ) t1
                           where rk = 1
                       ) t1
                           left join
                       (
                           select cert_no
                                , mail_addr
                                , mgr_stt_cd
                                , coup_name
                                , coup_cert_typ_cd
                                , case
                                      when char_length(replace(coup_cert_no, ' ', '')) <> 18 -- mysql端是字节长度,这里保持一致,采用字节长度
                                          or substr(coup_cert_no, 1, 17) not regexp '[0-9]' -- 身份证前17位不只有数字
                                          or date(substr(coup_cert_no, 7, 8)) is null -- 生日字段填写不正确
                                          or (substr(coup_cert_no, 1, 2) + 0 < 11 or
                                              substr(coup_cert_no, 1, 2) + 0 > 82) -- 身份证省份字段不在11-82之间
                                          or regexp_like(substr(coup_cert_no, 1, 17), '[^0-9]') -- 身份证前17位置包含非数字
                                          or
                                           mod(substr(coup_cert_no, 1, 1) * 7 +
                                               substr(coup_cert_no, 2, 1) * 9 +
                                               substr(coup_cert_no, 3, 1) * 10 +
                                               substr(coup_cert_no, 4, 1) * 5 +
                                               substr(coup_cert_no, 5, 1) * 8 +
                                               substr(coup_cert_no, 6, 1) * 4 +
                                               substr(coup_cert_no, 7, 1) * 2 +
                                               substr(coup_cert_no, 8, 1) * 1 +
                                               substr(coup_cert_no, 9, 1) * 6 +
                                               substr(coup_cert_no, 10, 1) * 3 +
                                               substr(coup_cert_no, 11, 1) * 7 +
                                               substr(coup_cert_no, 12, 1) * 9 +
                                               substr(coup_cert_no, 13, 1) * 10 +
                                               substr(coup_cert_no, 14, 1) * 5 +
                                               substr(coup_cert_no, 15, 1) * 8 +
                                               substr(coup_cert_no, 16, 1) * 4 +
                                               substr(coup_cert_no, 17, 1) * 2
                                               , 11) <>
                                           (case
                                                when substr(coup_cert_no, 18, 1) = '1' then '0'
                                                when substr(coup_cert_no, 18, 1) = '0' then '1'
                                                when substr(coup_cert_no, 18, 1) in ('X', 'x') then '2'
                                                when substr(coup_cert_no, 18, 1) = '9' then '3'
                                                when substr(coup_cert_no, 18, 1) = '8' then '4'
                                                when substr(coup_cert_no, 18, 1) = '7' then '5'
                                                when substr(coup_cert_no, 18, 1) = '6' then '6'
                                                when substr(coup_cert_no, 18, 1) = '5' then '7'
                                                when substr(coup_cert_no, 18, 1) = '4' then '8'
                                                when substr(coup_cert_no, 18, 1) = '3' then '9'
                                                when substr(coup_cert_no, 18, 1) = '2' then '10'
                                                else -99 end) then null
                                      else coup_cert_no end as coup_cert_no
                                , coup_tel_no
                           from (
                                    select t2.cert_no
                                         , coalesce(t3.cust_addr, t4.cust_address)                      as mail_addr    -- 通讯地址 /优先取业务系统，缺失的用业务大厅表单数据补充/
                                         , coalesce(trim(t3.marr_stt), trim(t4.mgr_stt), '99')          as mgr_stt_cd   -- 婚姻状况代码 /优先取业务系统，缺失的用业务大厅表单数据补充/
                                         , coalesce(t3.spouse_name, t4.spouse_name)                     as coup_name    -- 配偶姓名 /优先取业务系统，缺失的用业务大厅表单数据补充/
                                         , '10'                                                         as coup_cert_typ_cd
                                         , trim(coalesce(t3.spouse_cert_no, t4.spouse_cert_no))         as coup_cert_no -- 配偶证件号码 /优先取业务系统，缺失的用业务大厅表单数据补充/
                                         , coalesce(t3.spouse_tel_no, t4.spouse_tel_no,t5.spouse_tel)   as coup_tel_no  -- 配偶手机号 /优先取业务系统，缺失的用业务大厅表单数据补充/ 在保转进件缺失的用迁移台账补充
                                         , row_number()
                                            over (partition by t2.cert_no order by t2.loan_reg_dt desc) as rk /*业务宽表里取证件号最新放款登记日期对应数据*/
                                    from dw_base.dwd_guar_info_stat t1
                                             inner join dw_base.dwd_guar_info_all t2
                                                        on t1.guar_id = t2.guar_id
                                             left join
                                         (
                                             select t1.id
                                                  , t1.code           as project_no
                                                  , t1.cust_addr
                                                  , t1.marital_status as marr_stt
                                                  , t1.spouse_name
                                                  , t1.spouse_id_no   as spouse_cert_no
                                                  , t1.spouse_mobile  as spouse_tel_no
                                             from (
                                                      select t1.id
                                                           , t1.code
                                                           , t1.cust_addr
                                                           , t1.marital_status
                                                           , t1.spouse_name
                                                           , t1.spouse_id_no
                                                           , t1.spouse_mobile
                                                           , row_number()
                                                              over (partition by t1.id order by t1.db_update_time desc, t1.update_time desc) rn
                                                      from dw_nd.ods_t_biz_project_main t1 -- 主项目表（进件表）
                                                  ) t1
                                             where t1.rn = 1
                                         ) t3
                                         on t1.project_no = t3.project_no
                                             left join
                                         (
                                             select t1.busi_code
                                                  , replace(coalesce(
                                                                    json_extract(convert(json_val using utf8),
                                                                                 '$.custPerInfoDTO.liveAddress')
                                                                , json_extract(convert(json_val using utf8),
                                                                               '$.custPerInfoVO.custPerInfo.liveAddress')
                                                                ,
                                                                    json_extract(convert(json_val using utf8), '$.liveAddress')
                                                                ), 'undefined', '') as cust_address
                                                  , coalesce(
                                                     json_extract(convert(json_val using utf8),
                                                                  '$.custPerInfoDTO.marriageStatus')
                                                 , json_extract(convert(json_val using utf8),
                                                                '$.custPerInfoVO.custPerInfo.marriageStatus')
                                                 , json_extract(convert(json_val using utf8), '$.marriageStatus')
                                                 )                                  as mgr_stt
                                                  , coalesce(
                                                     json_extract(convert(json_val using utf8),
                                                                  '$.custPerInfoDTO.spouseName')
                                                 , json_extract(convert(json_val using utf8),
                                                                '$.custPerInfoVO.custPerInfo.spouseName')
                                                 , json_extract(convert(json_val using utf8), '$.spouseName')
                                                 )                                  as spouse_name
                                                  , coalesce(
                                                     json_extract(convert(json_val using utf8),
                                                                  '$.custPerInfoDTO.spouseIdNo')
                                                 , json_extract(convert(json_val using utf8),
                                                                '$.custPerInfoVO.custPerInfo.spouseIdNo')
                                                 , json_extract(convert(json_val using utf8), '$.spouseIdNo')
                                                 )                                  as spouse_cert_no
                                                  , coalesce(
                                                     json_extract(convert(json_val using utf8),
                                                                  '$.custPerInfoDTO.spouseMobileNo')
                                                 , regexp_replace(json_extract(convert(json_val using utf8),
                                                                               '$.adultChildrenList.spouseMobileNo'),
                                                                  '\\["|\\"]', '')
                                                 , json_extract(convert(json_val using utf8), '$.spouseMobileNo')
                                                 )                                  as spouse_tel_no
                                             from (
                                                      select t1.busi_code,
                                                             t1.json_val,
                                                             row_number()
                                                                     over (partition by t1.busi_code order by t1.update_time desc) rn
                                                      from dw_nd.ods_bizhall_form_entry t1
                                                  ) t1
                                             where t1.rn = 1
                                         ) t4
                                         on t1.guar_id = t4.busi_code
                                          	left join 
										(                                                                           -- [补充缺失的配偶电话号码] 20250915
										  select guarantee_code               -- 业务编号
										        ,if(length(spouse_tel) > 11, null, spouse_tel)                           as spouse_tel -- 配偶手机号码
										  from dw_base.dwd_tjnd_yw_guar_info_all_qy            -- [迁移台账]
										  where day_id = '${v_sdate}'
										) t5
										on t3.id = t5.guarantee_code
                                    where t2.day_id = '${v_sdate}'
                                ) t
                           where rk = 1
                       ) t2
                       on t1.cert_no = t2.cert_no
                           left join
                       (
                           select t1.cert_no
                                , t1.tel
                                , t1.sex
                                , t1.cert_valid_start_dt
                                , t1.cert_valid_end_dt
                           from (
                                    select t1.id_no                                                               as cert_no
                                         , case
                                               when length(trim(t3.tel)) = 11 then t3.tel
                                               else null
                                        end                                                                       as tel                 -- 手机号码
                                         , coalesce(t1.sex, t2.gender)                                            as sex
                                         , date(substring_index(t2.cert_expd, '-', 1))                            as cert_valid_start_dt -- 证件有效期起始日期
                                         , case
                                               when t2.cert_expd like '%长期%' then '2099-12-31'
                                               else date(substring_index(t2.cert_expd, '-', -1))
                                        end                                                                       as cert_valid_end_dt   -- 证件有效期终止日期
                                         , row_number() over (partition by t1.id_no order by t3.create_time desc) as rk
                                    from (
                                             select t1.id_no
                                                  , t1.sex
                                                  , t1.cust_code
                                             from (
                                                      select t1.id_no
                                                           , t1.sex
                                                           , t1.cust_code
                                                           , row_number() over (partition by t1.id order by t1.update_time desc) rn
                                                      from dw_nd.ods_crm_cust_per_info t1 -- 个人客户基本信息表
                                                  ) t1
                                             where t1.rn = 1
                                         ) t1
                                             left join
                                         (
                                             select t1.cust_code -- '客户编号'
                                                  , t1.id_no     -- '证件号码'
                                                  , t1.gender    -- '性别'
                                                  , t1.cert_expd
                                             from (
                                                      select t1.cust_code                                                                  -- '客户编号'
                                                           , t1.id_no                                                                      -- '证件号码'
                                                           , t1.gender                                                                     -- '性别'
                                                           , t1.id_card_validity as                                              cert_expd -- '身份证有效期' -- 20240913 mdy wyx
                                                           , row_number() over (partition by t1.id order by t1.update_time desc) rn
                                                      from dw_nd.ods_crm_cust_certification_info t1 -- 客户认证信息
                                                      where t1.cust_type = '01' -- 个人客户
                                                  ) t1
                                             where t1.rn = 1
                                         ) t2 -- 客户认证信息补充部分客户信息
                                         on t1.cust_code = t2.cust_code -- 业务系统客户号关联

                                             left join
                                         (
                                             select t1.main_id_no as cert_no -- 证件号码
                                                  , t1.login_no   as tel     -- 电话号码
                                                  , t1.create_time
                                             from (
                                                      select t1.main_id_no
                                                           , t1.login_no
                                                           , t1.create_time
                                                           , row_number()
                                                              over (partition by t1.main_id_no order by t1.create_time desc, t1.update_time desc) as rn
                                                      from dw_nd.ods_wxapp_cust_login_info t1 -- 客户注册信息
                                                      where t1.login_type = '1' -- 个人客户
                                                  ) t1
                                             where rn = 1
                                         ) t3 -- 用户注册信息表取客户最新手机号
                                         on t1.id_no = t3.cert_no
                                ) t1
                           where t1.rk = 1
                       ) t3
                       on t1.cert_no = t3.cert_no
              ) a
     ) a
where rk = 1
;
commit;
