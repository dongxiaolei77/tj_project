-- ----------------------------------------
-- 开发人   : WangYX
-- 开发时间 ：20240831
-- 目标表   ：dw_base.dwd_sdnd_report_cust_corp_rel_info 个人客户名下企业
-- 源表     ： dw_base.dwd_guar_info_all               业务信息宽表--项目域
--            dw_base.dwd_sdnd_report_biz_no_base     国担上报范围表
--            dw_nd.ods_wxapp_cust_login_info          -- 用户注册信息
--            dw_nd.ods_crm_cust_certification_info    -- 客户认证信息表
--            dw_nd.ods_crm_cust_comp_info             -- CRM--企业客户信息表
-- 备注     ：
-- 变更记录 ：20241201 脚本的统一变更，TDS转MySQL8.0 zhangfl
-- ----------------------------------------
-- 创建临时表村--法人代表信息
drop table if exists dw_tmp.tmp_dwd_sdnd_report_cust_corp_rel_info;
create table if not exists dw_tmp.tmp_dwd_sdnd_report_cust_corp_rel_info(
scr_cust_id        varchar(60)    comment '业务系统客户号'
,cust_name         varchar(255)   comment '客户姓名'
,cert_no           varchar(20)    comment '身份证号剔除空格/回车/单引号特殊字符'
,create_dt         varchar(8)     comment '创建日期'
,legal_name        varchar(255)   comment '法人姓名'
,legal_cert_no     varchar(20)    comment '法人身份证号'
,legal_tel         varchar(20)    comment '法人联系方式'
  
,index ind_tmp_dwd_sdnd_rcc_rel_info_certno(cert_no)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin comment= '创建临时表村--个人客户名下企业信息';

insert into dw_tmp.tmp_dwd_sdnd_report_cust_corp_rel_info
(
scr_cust_id       -- '业务系统客户号'
,cust_name         -- '客户姓名'
,cert_no           -- '身份证号剔除空格/回车/单引号特殊字符'
,create_dt         -- '创建日期'
,legal_name        -- '法人姓名'
,legal_cert_no     -- '法人身份证号'
,legal_tel         -- '法人联系方式'
)
select  t1.customer_id                                                      as scr_cust_id       -- 业务系统客户号
        ,t1.main_name                                                       as cust_name         -- 客户姓名
        ,regexp_replace(coalesce(t3.id_no,t1.main_id_no), ' |\r\n|\'', '')  as cert_no           -- 身份证号剔除空格/回车/单引号特殊字符             
        ,date_format(t2.create_time,'%Y%m%d')                               as create_dt         -- 创建日期
		,t4.legal_person_name                                               as legal_name        -- 法人姓名
		,t4.legal_person_id_no                                              as legal_cert_no     -- 法人身份证号
		,t4.legal_person_mobile                                             as legal_tel         -- 法人联系方式
from 
(
    select  customer_id
            ,login_type
            ,main_name
            ,main_id_no
            ,status
    from 
    (
        select  customer_id
                ,login_type
                ,main_name
                ,main_id_no
                ,status
                ,row_number()over(partition by customer_id order by update_time desc) as rn 
        from dw_nd.ods_wxapp_cust_login_info           -- 用户注册信息
    )t1                                                 
    where rn = 1                                        
    and status = '10'                                  -- 注册成功  
)t1
left join 
(
    select  customer_id
            ,create_time
    from 
    (
        select  customer_id
                ,create_time
                ,row_number()over(partition by customer_id order by create_time asc) as rn 
        from dw_nd.ods_wxapp_cust_login_info           -- 用户注册信息
    )t1
    where rn = 1
)t2
on t1.customer_id = t2.customer_id
left join dw_nd.ods_crm_cust_certification_info t3     -- 客户认证信息表
on t1.customer_id = t3.cust_code
left join dw_nd.ods_crm_cust_comp_info t4              -- CRM--企业客户信息表
on t1.customer_id = t4.cust_code
where t1.login_type = '2' -- 企业客户
;
commit;

-- 日增量加载
delete from dw_base.dwd_sdnd_report_cust_corp_rel_info where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_sdnd_report_cust_corp_rel_info
(
 day_id
,cust_corp_cd	           -- 个人企业省担编码
,cert_no	               -- 个人证件号码
,own_comp_name	           -- 个人名下企业名称
,own_comp_cert_no_typ_cd   -- 个人名下企业证件类型代码
,own_comp_cert_no	       -- 个人名下企业证件号码
)
select '${v_sdate}' as day_id
	,concat(t1.cert_no,t2.own_comp_cert_no) as cust_corp_cd -- 个人企业省担编码
	,t1.cert_no                        -- 个人证件号码
	,t2.own_comp_name	               -- 个人名下企业名称
	,t2.own_comp_cert_no_typ_cd        -- 个人名下企业证件类型代码
	,t2.own_comp_cert_no	           -- 个人名下企业证件号码
from
(
	select t1.cert_no
	from (
		select t1.cert_no
			,row_number() over(partition by t1.cert_no order by t1.loan_reg_dt desc) rk
		from dw_base.dwd_guar_info_all t1
		inner join dw_base.dwd_sdnd_report_biz_no_base t2
		on t1.guar_id = t2.biz_no
		and t2.day_id = '${v_sdate}'
		where t1.day_id = '${v_sdate}'
		and ( /*筛选出自然人*/
		t1.cust_type = '自然人'
		or (t1.cust_type is null and char_length(trim(t1.cust_name)) <= 4)
		or t1.cert_no regexp'^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[1-2]\\d|3[0-1])\\d{3}([0-9Xx])$'
		)
		and t1.item_stt IN ('已放款','已解保','已代偿')
	) t1
	where t1.rk = 1
) t1
inner join /*通过证件号关联企业法人，取出名下企业信息*/
(
	select	t1.legal_cert_no
			,t1.own_comp_name
			,t1.own_comp_cert_no_typ_cd
			,t1.own_comp_cert_no
	from(
		select legal_cert_no                   -- 企业法人证件号
			,cust_name as own_comp_name        -- 企业名称
			,'29' as own_comp_cert_no_typ_cd   -- 企业证件代码类型
			,cert_no as own_comp_cert_no       -- 企业证件号码
			,row_number() over(partition by cert_no order by create_dt desc) as rk
		from dw_tmp.tmp_dwd_sdnd_report_cust_corp_rel_info
	) t1
	where t1.rk = 1
) t2
on t1.cert_no = t2.legal_cert_no

;
commit;