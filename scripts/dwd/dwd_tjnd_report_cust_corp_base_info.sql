-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241216
-- 目标表   :dwd_tjnd_report_cust_corp_base_info           -- 企业客户信息表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy        -- 迁移业务宽表
--            dw_base.dwd_nacga_report_guar_info_base_info -- 国农担上报范围表
-- 备注     ：
-- 变更记录 ：zhangruwen 20250219
--          wangyj    20250513  合并新老客户信息，优先取新系统数据，保证客户唯一
-- ----------------------------------------

delete
from dw_base.dwd_tjnd_report_cust_corp_base_info
where day_id = '${v_sdate}';
commit;

-- 创建临时表村--法人代表信息
drop table if exists dw_tmp.tmp_dwd_tjnd_report_cust_corp_legal_info;
create table if not exists dw_tmp.tmp_dwd_tjnd_report_cust_corp_legal_info
(
    scr_cust_id   varchar(60) comment '业务系统客户号',
    cust_name     varchar(255) comment '客户姓名',
    cert_no       varchar(20) comment '身份证号剔除空格/回车/单引号特殊字符',
    create_dt     varchar(8) comment '创建日期',
    legal_name    varchar(255) comment '法人姓名',
    legal_cert_no varchar(20) comment '法人身份证号',
    legal_tel     varchar(20) comment '法人联系方式',
    index ind_tmp_dwd_tjnd_rcc_legal_info_certno (cert_no)
) engine = InnoDB
  default charset = utf8mb4
  collate = utf8mb4_bin comment = '创建临时表村--法人代表信息';

insert into dw_tmp.tmp_dwd_tjnd_report_cust_corp_legal_info
( scr_cust_id -- '业务系统客户号'
, cust_name -- '客户姓名'
, cert_no -- '身份证号剔除空格/回车/单引号特殊字符'
, create_dt -- '创建日期'
, legal_name -- '法人姓名'
, legal_cert_no -- '法人身份证号'
, legal_tel -- '法人联系方式'
)
select t1.customer_id                                                     as scr_cust_id   -- 业务系统客户号
     , t1.main_name                                                       as cust_name     -- 客户姓名
     , regexp_replace(coalesce(t3.id_no, t1.main_id_no), ' |\r\n|\'', '') as cert_no       -- 身份证号剔除空格/回车/单引号特殊字符
     , date_format(t2.create_time, '%Y%m%d')                              as create_dt     -- 创建日期
     , t4.legal_person_name                                               as legal_name    -- 法人姓名
     , t4.legal_person_id_no                                              as legal_cert_no -- 法人身份证号
     , t4.legal_person_mobile                                             as legal_tel     -- 法人联系方式
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
;
commit;

insert into dw_base.dwd_tjnd_report_cust_corp_base_info
( day_id
, cert_no_typ_cd -- 证件类型代码
, cust_main_typ_cd -- 客户主体类型代码
, corp_name -- 企业客户名称
, corp_cert_no -- 企业证件号码
, corp_typ_cd -- 企业划型代码
, lgpr_name -- 法定代表人
, lgpr_cert_typ_cd -- 法定代表人证件类型代码
, lgpr_cert_no -- 法定代表人证件号码
, lgpr_tel_no -- 法定代表人联系电话
, dict_flag)
select day_id
	,cert_type
	,mainbody_type_corp
	,customer_name
	,id_number
	,enterpise_type
	,legal_representative
	,lgpr_cert_typ_cd
	,legal_representative_id
	,leg_tel
	,dict_flag
from
(
	select *
		,row_number()over(partition by id_number order by dict_flag desc) as rk
	from
	(
		select '${v_sdate}' as day_id
			 , cert_type               -- 证件类型代码
			 , mainbody_type_corp      -- 客户主体类型代码
			 , customer_name           -- 企业客户名称
			 , id_number               -- 企业证件号码
			 , enterpise_type          -- 企业划型代码
			 , legal_representative    -- 法定代表人
			 , '10'  as lgpr_cert_typ_cd                  -- 法定代表人证件类型代码
			 , legal_representative_id -- 法定代表人证件号码
			 , leg_tel                 -- 法定代表人联系电话
			 , 0            as dict_flag
		from (
				 select cert_type               -- 证件类型代码
					  , mainbody_type_corp      -- 客户主体类型代码
					  , customer_name           -- 企业客户名称
					  , id_number               -- 企业证件号码
					  , enterpise_type          -- 企业划型代码
					  , legal_representative    -- 法定代表人
					  , legal_representative_id -- 法定代表人证件号码
					  , leg_tel                 -- 法定代表人联系电话
					  , row_number() over (partition by id_number order by lend_reg_dt desc ) as rk
				 from dw_base.dwd_tjnd_yw_guar_info_all_qy a
						  inner join dw_base.dwd_nacga_report_guar_info_base_info b
									 on a.id_business_information = b.biz_id
				 where a.day_id = '${v_sdate}'
				   and b.day_id = '${v_sdate}'
				   and customer_nature = 'enterprise' -- 取企业客户
			 ) a
		where rk = 1

		union all
		select '${v_sdate}' as day_id
			 , t1.cert_no_typ_cd            -- 证件类型代码
			 , t1.cust_main_typ_cd          -- 客户主体类型代码
			 , t1.corp_name                 -- 企业客户名称
			 , t1.cert_no   as corp_cert_no -- 企业证件号码
			 , '01'            corp_typ_cd  -- 企业划型代码
			 , t2.lgpr_name                 -- 法定代表人
			 , t2.lgpr_cert_typ_cd          -- 法定代表人证件类型代码
			 , t2.lgpr_cert_no              -- 法定代表人证件号码
			 , t2.lgpr_tel_no               -- 法定代表人联系电话
			 , 1            as dict_flag
		from (
				 select t1.cert_no
					  , t1.cert_no_typ_cd
					  , t1.cust_main_typ_cd
					  , t1.corp_name
				 from (
						  select t1.cert_no                                                                       -- 企业证件号码
							   , '29'                                                         as cert_no_typ_cd /*固定值为“统一社会信用代码”*/
							   , case
							       	 when t1.cust_class = '家庭农场（种养大户）' then '01'
									 when t1.cust_class = '家庭农场' then '02'
									 when t1.cust_class = '农民专业合作社' then '04'
									 when t1.cust_class =  '农业企业' then '03'
								end                                                             as cust_main_typ_cd -- 项目主体类型代码
							   , t1.cust_type
							   , regexp_replace(t1.cust_name, '\t|\n', '')                    as corp_name /*剔除特殊字符*/
							   , row_number()
								  over (partition by t1.cert_no order by t1.loan_reg_dt desc) as rk /*同一笔证件号取放款登记日期最晚业务的信息*/
						  from dw_base.dwd_guar_info_all t1 -- 业务信息宽表--项目域
								   inner join dw_base.dwd_tjnd_report_biz_no_base t2 -- 国担上报范围表
											  on t1.guar_id = t2.biz_no
												  and t2.day_id = '${v_sdate}'
						  where t1.day_id = '${v_sdate}'
							and (t1.cust_type = '法人或其他组织' or
								 (t1.cust_type is null and char_length(trim(t1.cust_name)) > 4)) /*筛选符合企业校验规则的数据*/
							and t1.cert_no not regexp
								'^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$' /*剔除不符合证件号码校验规则的数据*/
					  ) t1
				 where rk = 1
			 ) t1
			left join /*取法人信息*/
			(
				select t1.cert_no
					 , t1.lgpr_name
					 , t1.lgpr_cert_typ_cd
					 , t1.lgpr_cert_no
					 , t1.lgpr_tel_no
				from (
						 select cert_no
							  , legal_name                                                                                       as lgpr_name        -- 法定代表人姓名
							  , '10'                                                                                             as lgpr_cert_typ_cd -- 法定代表人证件类型代码
							  , legal_cert_no                                                                                    as lgpr_cert_no     -- 法定代表人证件号码
							  , first_value(legal_tel)
											over (partition by cert_no order by if(legal_tel is null, 0, 1) desc,create_dt desc) as lgpr_tel_no /*法定代表人联系电话优先取非空*/
							  , row_number() over (partition by cert_no order by create_dt desc)                                 as rk /*法人信息按照create_dt排序取最新*/
						 from dw_tmp.tmp_dwd_tjnd_report_cust_corp_legal_info
					 ) t1
				where rk = 1
			) t2
			on t1.cert_no = t2.cert_no
	)a
)a
where rk = 1;
commit;