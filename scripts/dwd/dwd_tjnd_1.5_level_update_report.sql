-- ----------------------------------------
-- 开发人   : dxl
-- 开发时间 ：20250708
-- 目标表   :  dwd_tjnd_report_cust_per_base_info 个人客户基础信息
--            dwd_tjnd_report_cust_corp_rel_info 个人客户名下企业
--            dwd_tjnd_report_cust_corp_base_info 企业客户基础信息
--            dwd_tjnd_report_proj_cntr_agmt_info 反担保签约记录
-- 源表     ： dwd_tjnd_cust_auth_info     中间表-信息查询授权
-- 备注     ：
-- 变更记录 ：
-- ----------------------------------------
-- 1.更新个人客户基础信息
-- 更新个人客户信息
update dw_base.dwd_tjnd_report_cust_per_base_info t1 left join
    (
        select *
        from dw_base.dwd_tjnd_cust_auth_info
        where day_id = '${v_sdate}'
    ) t2 on t1.cert_no = t2.cert_no
set t1.IS_INFO_AUTH      = if(t2.cert_no is null, 0, 1),             -- 是否取得信息查询授权
    t1.info_auth_start_dt= if(t2.cert_no is null, null, t2.sign_dt), -- 取得信息查询授权日期
    t1.info_auth_end_dt  = if(t2.cert_no is null, null, t2.end_dt)   -- 信息查询授权终止日期
where t1.day_id = '${v_sdate}';
commit;

-- 更新个人客户配偶信息
update dw_base.dwd_tjnd_report_cust_per_base_info t1 left join
    (
        select *
        from dw_base.dwd_tjnd_cust_auth_info
        where day_id = '${v_sdate}'
    ) t2 on t1.coup_cert_no = t2.cert_no
set t1.is_info_auth_coup      = if(t2.cert_no is null, 0, 1),             -- 是否取得信息查询授权（配偶）
    t1.info_auth_start_dt_coup= if(t2.cert_no is null, null, t2.sign_dt), -- 取得信息查询授权日期（配偶）
    t1.info_auth_end_dt_coup  = if(t2.cert_no is null, null, t2.end_dt)   -- 信息查询授权终止日期（配偶）
where t1.day_id = '${v_sdate}';
commit;

-- 2.更新个人客户名下企业
-- 更新个人客户名下企业信息
update dw_base.dwd_tjnd_report_cust_corp_rel_info t1 left join
    (
        select *
        from dw_base.dwd_tjnd_cust_auth_info
        where day_id = '${v_sdate}'
    ) t2 on t1.own_comp_cert_no = t2.cert_no
set t1.is_info_auth_own_comp       = if(t2.cert_no is null, 0, 1),             -- 是否取得信息查询授权（名下企业）
    t1.info_auth_start_dt_own_comp = if(t2.cert_no is null, null, t2.sign_dt), -- 取得信息查询授权日期（名下企业）
    t1.info_auth_end_dt_own_comp   = if(t2.cert_no is null, null, t2.end_dt)   -- 信息查询授权终止日期（名下企业）
where t1.day_id = '${v_sdate}';
commit;

-- 3.更新企业客户信息
-- 更新企业客户信息
update dw_base.dwd_tjnd_report_cust_corp_base_info t1 left join
    (
        select *
        from dw_base.dwd_tjnd_cust_auth_info
        where day_id = '${v_sdate}'
    ) t2 on t1.corp_cert_no = t2.cert_no
set t1.is_info_auth       = if(t2.cert_no is null, 0, 1),             -- 是否取得信息查询授权
    t1.info_auth_start_dt = if(t2.cert_no is null, null, t2.sign_dt), -- 取得信息查询授权日期
    t1.info_auth_end_dt   = if(t2.cert_no is null, null, t2.end_dt)   -- 信息查询授权终止日期
where t1.day_id = '${v_sdate}';
commit;
-- 更新企业客户法人信息
update dw_base.dwd_tjnd_report_cust_corp_base_info t1 left join
    (
        select *
        from dw_base.dwd_tjnd_cust_auth_info
        where day_id = '${v_sdate}'
    ) t2 on t1.lgpr_cert_no = t2.cert_no
set t1.is_info_auth_lgpr       = if(t2.cert_no is null, 0, 1),             -- 是否取得信息查询授权（法人）
    t1.info_auth_start_dt_lgpr = if(t2.cert_no is null, null, t2.sign_dt), -- 取得信息查询授权日期（法人）
    t1.info_auth_end_dt_lgpr   = if(t2.cert_no is null, null, t2.end_dt)   -- 信息查询授权终止日期（法人）
where t1.day_id = '${v_sdate}';
commit;

-- 4.更新反担保签约记录
-- 更新反担保人信息
update dw_base.dwd_tjnd_report_proj_cntr_agmt_info t1 left join
    (
        select *
        from dw_base.dwd_tjnd_cust_auth_info
        where day_id = '${v_sdate}'
    ) t2 on t1.main_signer_cert_no = t2.cert_no
set t1.is_info_auth_cntr      = if(t2.cert_no is null, 0, 1),             -- 是否取得信息查询授权（反担保人）
    t1.info_auth_start_dt_cntr= if(t2.cert_no is null, null, t2.sign_dt), -- 取得信息查询授权日期（反担保人）
    t1.info_auth_end_dt_cntr  = if(t2.cert_no is null, null, t2.end_dt)   -- 信息查询授权终止日期（反担保人）
where t1.day_id = '${v_sdate}';
commit;