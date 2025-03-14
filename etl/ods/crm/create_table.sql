

CREATE TABLE dw_nd.`ods_crm_ztc_express_log` (
  `id` varchar(40)  COMMENT '主键',
  `status` varchar(10)  COMMENT '状态（成功/失败）',
  `license_code` varchar(20)  COMMENT '统一信用代码',
  `id_no` varchar(20)  COMMENT '身份证',
  `folio` varchar(64)  COMMENT '农业农村部业务编号',
  `gsz_flag` varchar(2)  COMMENT '是否高素质农民：1-是/true，0-否/false',
  `check_flag` varchar(2)  COMMENT '家庭名录/工商信息是否核验通过：1-是/true，0-否/false',
  `farm_flag` varchar(2)  COMMENT '家庭农场检测结果：1正常/0异常',
  `cooperative_flag` varchar(2)  COMMENT '合作社检测结果：1正常/0异常',
  `request_info` varchar(1000)  COMMENT '请求信息（失败时）',
  `res_info` varchar(1000)  COMMENT '反馈信息（失败时）',
  `create_time` datetime  COMMENT '创建时间',
  `update_time` datetime  COMMENT '更新时间',
  `create_name` varchar(50)  COMMENT '创建人姓名',
  `update_name` varchar(50)  COMMENT '更新人姓名',
  `creator` varchar(36)  COMMENT '创建人',
  `updator` varchar(36)  COMMENT '更新人',
  `is_del` tinyint(1) COMMENT '删除逻辑',
  `db_update_time` datetime ,
   KEY `idx_ods_crm_ztc_express_log_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT='客户直通申请信息推送反馈记录表'
;commit;


CREATE TABLE dw_nd.`ods_crm_comp_nc_hzs` (
  `credit_code` varchar(18)  COMMENT '信用代码',
  `ent_name` varchar(150)  COMMENT '组织名称',
  `fr_name` varchar(30)  COMMENT '法人代表姓名',
  `fz_date` date  COMMENT '发证日期',
  `fz_org` varchar(100)  COMMENT '发证机关',
  `fr_mobile` varchar(20)  COMMENT '手机号',
  `create_time` datetime ,
  KEY `idx_ods_crm_comp_nc_hzs_ent_name` (`ent_name`),
  KEY `idx_ods_crm_comp_nc_hzs_credit_code` (`credit_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin
;commit;
