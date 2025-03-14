
CREATE TABLE dw_nd.`ods_common_identify_t_face_auth_log` (
  `log_id` varchar(30) NOT NULL COMMENT '主键',
  `id_no` varchar(20) DEFAULT NULL COMMENT '身份证号码',
  `name` varchar(50) DEFAULT NULL COMMENT '姓名，个人实名认证的姓名，企业认证的法人姓名',
  `status` char(1) DEFAULT NULL COMMENT '业务状态0-失败，1-成功，2-处理中',
  `biz_id` varchar(50) DEFAULT NULL COMMENT '业务id',
  `leasee_id` varchar(50) DEFAULT NULL COMMENT '租户',
  `auth_org` char(2) DEFAULT NULL COMMENT '认证机构 1-face++',
  `create_time` bigint(20) DEFAULT NULL COMMENT '创建时间',
  `update_time` bigint(20) DEFAULT NULL COMMENT '修改时间',
  `error_desc` varchar(200) DEFAULT NULL COMMENT '错误描述',
  `biz_token` varchar(100) DEFAULT NULL COMMENT 'biz_token',
  `auth_content` varchar(1000) DEFAULT NULL COMMENT '认证机构返回认证信息',
  `notify_url` varchar(200) DEFAULT NULL COMMENT '回调地址',
  `video_file_name` varchar(100) DEFAULT NULL COMMENT '视频文件名',
   KEY idx_ods_common_identify_t_face_auth_log_id (`log_id`) USING BTREE,
   KEY `idx_ods_common_identify_t_face_auth_log_biz_id` (`biz_id`) USING BTREE
)  ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT ='活体检测日志表'
;commit;



CREATE TABLE dw_nd.`ods_common_identify_t_real_name_auth_log` (
  `log_id` varchar(30) NOT NULL COMMENT '主键',
  `id_no` varchar(20) DEFAULT NULL COMMENT '身份证号码',
  `name` varchar(50) DEFAULT NULL COMMENT '姓名，个人实名认证的姓名，企业认证的法人姓名',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机号',
  `company_name` varchar(500) DEFAULT NULL COMMENT '企业名',
  `company_no` varchar(100) DEFAULT NULL COMMENT '企业机构代码',
  `create_time` bigint(20) DEFAULT NULL COMMENT '创建时间',
  `type` varchar(5) DEFAULT NULL COMMENT '业务类别1-个人认证，2-企业认证，3-身份证OCR',
  `status` char(1) DEFAULT NULL COMMENT '业务状态0-失败，1-成功',
  `error_desc` varchar(1000) DEFAULT NULL COMMENT '错误描述',
  `biz_id` varchar(50) DEFAULT NULL COMMENT '业务id',
  `tenant_code` varchar(50) DEFAULT NULL COMMENT '租户',
  `auth_org` char(2) DEFAULT NULL COMMENT '认证机构 1-众签',
  `id_img` varchar(100) DEFAULT NULL COMMENT '身份证图片',
   KEY idx_ods_common_identify_t_real_name_auth_log_id (`log_id`) USING BTREE
)  ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin COMMENT ='实名认证日志日志表'
;commit;