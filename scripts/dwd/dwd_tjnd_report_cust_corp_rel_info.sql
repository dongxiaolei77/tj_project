-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241216
-- 目标表   :dwd_tjnd_report_cust_corp_rel_info            -- 个人客户名下企业信息表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy        -- 迁移业务宽表
--            dw_base.dwd_nacga_report_guar_info_base_info -- 国农担上报范围表
-- 备注     ：
-- 变更记录 ：zhangruwen 20250219
--           20250911  新老逻辑合并去重
--          20250917  法人信息在保转进件的数据取不到的从老系统取
-- ----------------------------------------

delete
from dw_base.dwd_tjnd_report_cust_corp_rel_info
where day_id = '${v_sdate}';
commit;


drop table if exists dw_tmp.tmp_dwd_tjnd_report_cust_corp_rel_info;
create table if not exists dw_tmp.tmp_dwd_tjnd_report_cust_corp_rel_info
(
    scr_cust_id   varchar(60) comment '业务系统客户号',
    cust_name     varchar(255) comment '客户姓名',
    cert_no       varchar(20) comment '身份证号剔除空格/回车/单引号特殊字符',
    create_dt     varchar(8) comment '创建日期',
    legal_name    varchar(255) comment '法人姓名',
    legal_cert_no varchar(20) comment '法人身份证号',
    legal_tel     varchar(20) comment '法人联系方式',
    index ind_tmp_dwd_tjnd_rcc_rel_info_certno (cert_no)
) engine = InnoDB
  default charset = utf8mb4
  collate = utf8mb4_bin comment = '创建临时表村--个人客户名下企业信息';

insert into dw_tmp.tmp_dwd_tjnd_report_cust_corp_rel_info
( scr_cust_id -- '业务系统客户号'
, cust_name -- '客户姓名'
, cert_no -- '身份证号剔除空格/回车/单引号特殊字符'
, create_dt -- '创建日期'
, legal_name -- '法人姓名'
, legal_cert_no -- '法人身份证号'
, legal_tel -- '法人联系方式'
)
select  t_all.scr_cust_id    -- '业务系统客户号'
      , t_all.cust_name      -- '客户姓名'
      , t_all.cert_no        -- '身份证号剔除空格/回车/单引号特殊字符'
      , t_all.create_dt      -- '创建日期'
      , t_all.legal_name     -- '法人姓名'
      , t_all.legal_cert_no  -- '法人身份证号'
      , t_all.legal_tel      -- '法人联系方式'
from 
(
select  t4.scr_cust_id    -- '业务系统客户号'
      , t4.cust_name      -- '客户姓名'
      , t4.cert_no        -- '身份证号剔除空格/回车/单引号特殊字符'
      , t4.create_dt      -- '创建日期'
      , t4.legal_name     -- '法人姓名'
      , t4.legal_cert_no  -- '法人身份证号'
      , t4.legal_tel      -- '法人联系方式'
      , row_number() over(partition by t4.cert_no order by dict_flag desc) as rn
from (                                                                                              -- 【原老系统逻辑，迁移台账业务】               20250917
        select  '1'                                  as  scr_cust_id   -- '业务系统客户号'
              , a.customer_name                      as  cust_name     -- '客户姓名'
              , a.id_number                          as  cert_no       -- '身份证号剔除空格/回车/单引号特殊字符'
			  , '20000101'                           as  create_dt     -- '创建日期'               [老系统的逻辑给定一个很晚的日期]
              , a.legal_representative               as  legal_name    -- '法人姓名'
              , a.legal_representative_id            as  legal_cert_no -- '法人身份证号'
              , a.leg_tel                            as  legal_tel     -- '法人联系方式'
              , 0              as dict_flag
        from (
                  select cert_type               -- 证件类型代码
                       , mainbody_type_corp      -- 客户主体类型代码
                       , customer_name           -- 企业客户名称
                       , id_number               -- 企业证件号码
                       , enterpise_type          -- 企业划型代码
                       , legal_representative    -- 法定代表人
                       , legal_representative_id -- 法定代表人证件号码
	                   , replace(a.tel,' ','') as leg_tel -- 法定代表人联系电话
                       , row_number() over (partition by id_number,legal_representative_id order by lend_reg_dt) as rk
                  from dw_nd.ods_tjnd_yw_z_report_base_customers_history a -- 客户表       -- [有部分数据没迁移过来，需要用到老表]
				  left join
                		   ( 
							 select id_business_information                                   -- 业务编号
                                  , min(date_format(created_time, '%Y%m%d')) as lend_reg_dt   -- 计入在保日期
                                  , min(repayment_way)                       as repayment_way -- 借款合同还款方式 ??
                             from dw_nd.ods_tjnd_yw_z_report_afg_voucher_infomation -- 放款凭证表
                             where delete_flag = 1 
                	          group by id_business_information
                           ) e on a.id_business_information = e.id_business_information
                  where customer_nature = 'enterprise' -- 取企业客户
              ) a
        where a.rk = 1 
		
		union all 
                                                                                                    -- 【新系统逻辑】 
        select t1.customer_id                                                     as scr_cust_id   -- 业务系统客户号
             , t1.main_name                                                       as cust_name     -- 客户姓名
             , regexp_replace(coalesce(t3.id_no, t1.main_id_no), ' |\r\n|\'', '') as cert_no       -- 身份证号剔除空格/回车/单引号特殊字符
             , date_format(t2.create_time, '%Y%m%d')                              as create_dt     -- 创建日期
             , t4.legal_person_name                                               as legal_name    -- 法人姓名
             , t4.legal_person_id_no                                              as legal_cert_no -- 法人身份证号
             , t4.legal_person_mobile                                             as legal_tel     -- 法人联系方式
			 , 1              as dict_flag
        from (
                 select customer_id
                      , login_type
                      , main_name
                      , main_id_no
                      , status
                 from (
                          select customer_id
                               , login_type
                               , main_name
                               , main_id_no
                               , status
                               , row_number() over (partition by customer_id order by update_time desc) as rn
                          from dw_nd.ods_wxapp_cust_login_info -- 用户注册信息
                      ) t1
                 where rn = 1
                   and status = '10' -- 注册成功
             ) t1
                 left join
             (
                 select customer_id
                      , create_time
                 from (
                          select customer_id
                               , create_time
                               , row_number() over (partition by customer_id order by create_time asc) as rn
                          from dw_nd.ods_wxapp_cust_login_info -- 用户注册信息
                      ) t1
                 where rn = 1
             ) t2
             on t1.customer_id = t2.customer_id
                 left join dw_nd.ods_crm_cust_certification_info t3 -- 客户认证信息表
                           on t1.customer_id = t3.cust_code
                 left join dw_nd.ods_crm_cust_comp_info t4 -- CRM--企业客户信息表
                           on t1.customer_id = t4.cust_code
        where t1.login_type = '2' -- 企业客户
	 ) t4
) t_all
where t_all.rn = 1
;
commit;


insert into dw_base.dwd_tjnd_report_cust_corp_rel_info
( day_id
, cust_corp_cd -- 个人企业省担编码
, cert_no -- 个人证件号码
, own_comp_name -- 个人名下企业名称
, own_comp_cert_no_typ_cd -- 个人名下企业证件类型代码
, own_comp_cert_no -- 个人名下企业证件号码
, dict_flag)
select  t_all.day_id
      , t_all.cust_corp_cd            -- 个人企业省担编码
      , t_all.cert_no                 -- 个人证件号码
      , t_all.own_comp_name           -- 个人名下企业名称
      , t_all.own_comp_cert_no_typ_cd -- 个人名下企业证件类型代码
      , t_all.own_comp_cert_no        -- 个人名下企业证件号码
      , t_all.dict_flag
from 
(
select  t3.day_id
      , t3.cust_corp_cd                                -- 个人企业省担编码
      , t3.id_number        as cert_no                 -- 个人证件号码
      , t3.customer_name    as own_comp_name           -- 个人名下企业名称
      , t3.own_comp_cert_no_typ_cd                     -- 个人名下企业证件类型代码
      , t3.corp_cert_no     as own_comp_cert_no        -- 个人名下企业证件号码
      , t3.dict_flag
	  , row_number() over(partition by t3.cust_corp_cd order by t3.dict_flag desc) as rn
from (
       select '${v_sdate}'                     as day_id
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
              inner join(
                          select  customer_name                                                                                                      -- 企业名称
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
			
    union all 
	
       select '${v_sdate}'                            as day_id
            , concat(t1.cert_no, t2.own_comp_cert_no) as cust_corp_cd -- 个人企业省担编码
            , t1.cert_no                                              -- 个人证件号码
            , t2.own_comp_name                                        -- 个人名下企业名称
            , t2.own_comp_cert_no_typ_cd                              -- 个人名下企业证件类型代码
            , t2.own_comp_cert_no                                     -- 个人名下企业证件号码
            , 1                                       as dict_flag
       from (
                select t1.cert_no
                from (
                         select t1.cert_no
                              , row_number() over (partition by t1.cert_no order by t1.loan_reg_dt desc) rk
                         from dw_base.dwd_guar_info_all t1
                                  inner join dw_base.dwd_tjnd_report_biz_no_base t2
                                             on t1.guar_id = t2.biz_no
                                                 and t2.day_id = '${v_sdate}'
                         where t1.day_id = '${v_sdate}'
                           and ( /*筛选出自然人*/
                                 t1.cust_type = '自然人'
                                 or (t1.cust_type is null and char_length(trim(t1.cust_name)) <= 4)
                                 or t1.cert_no regexp
                                    '^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$'
                             )
                           and t1.item_stt in ('已放款', '已解保', '已代偿')
                     ) t1
                where t1.rk = 1
            ) t1
                inner join /*通过证件号关联企业法人，取出名下企业信息*/
           (
               select t1.legal_cert_no
                    , t1.own_comp_name
                    , t1.own_comp_cert_no_typ_cd
                    , t1.own_comp_cert_no
               from (
                        select legal_cert_no                                                                               -- 企业法人证件号
                             , cust_name                                                        as own_comp_name           -- 企业名称
                             , '29'                                                             as own_comp_cert_no_typ_cd -- 企业证件代码类型
                             , cert_no                                                          as own_comp_cert_no        -- 企业证件号码
                             , row_number() over (partition by cert_no order by create_dt desc) as rk
                        from dw_tmp.tmp_dwd_tjnd_report_cust_corp_rel_info
                    ) t1
               where t1.rk = 1
           ) t2
                           on t1.cert_no = t2.legal_cert_no
	 ) t3
) t_all
where t_all.rn = 1
;
commit;