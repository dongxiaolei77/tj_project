-- ----------------------------------------
-- 开发人   : wangyj
-- 开发时间 ：20241216
-- 目标表   :dwd_tjnd_report_cust_corp_base_info           -- 企业客户信息表
-- 源表     ： dw_base.dwd_tjnd_yw_guar_info_all_qy        -- 迁移业务宽表
--            dw_base.dwd_nacga_report_guar_info_base_info -- 国农担上报范围表
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------

delete from dw_base.dwd_tjnd_report_cust_corp_base_info where day_id = '${v_sdate}';
commit;

insert into dw_base.dwd_tjnd_report_cust_corp_base_info
(
 day_id
,cert_no_typ_cd     -- 证件类型代码
,cust_main_typ_cd   -- 客户主体类型代码
,corp_name          -- 企业客户名称
,corp_cert_no       -- 企业证件号码
,corp_typ_cd        -- 企业划型代码
,lgpr_name          -- 法定代表人
,lgpr_cert_typ_cd   -- 法定代表人证件类型代码
,lgpr_cert_no       -- 法定代表人证件号码
,lgpr_tel_no        -- 法定代表人联系电话
)
select '${v_sdate}'    as day_id
    ,cert_type                  -- 证件类型代码 
    ,mainbody_type_corp         -- 客户主体类型代码
    ,customer_name              -- 企业客户名称
    ,id_number                  -- 企业证件号码
    ,enterpise_type             -- 企业划型代码
    ,legal_representative       -- 法定代表人
    ,'10'                       -- 法定代表人证件类型代码
    ,legal_representative_id    -- 法定代表人证件号码
    ,leg_tel                    -- 法定代表人联系电话
from
(
    select cert_type                  -- 证件类型代码 
        ,mainbody_type_corp         -- 客户主体类型代码
        ,customer_name              -- 企业客户名称
        ,id_number                  -- 企业证件号码
        ,enterpise_type             -- 企业划型代码
        ,legal_representative       -- 法定代表人
        ,legal_representative_id    -- 法定代表人证件号码
        ,leg_tel                    -- 法定代表人联系电话
        ,row_number()over(partition by id_number order by lend_reg_dt desc ) as rk 
    from dw_base.dwd_tjnd_yw_guar_info_all_qy a 
    inner join dw_base.dwd_nacga_report_guar_info_base_info b 
    on a.id_business_information = b.biz_id
    where a.day_id = '${v_sdate}'and b.day_id = '${v_sdate}'
    and customer_nature = 'enterprise'          -- 取企业客户
)a
where rk = 1
;
commit;