// 数据库的配置

// 数据库导出备份、db操作等相关关键字
// db_helper、备份恢复页面能用到

/// 数据库中一下基本内容
class DBInitConfig {
  // db名称
  static const String databaseName = "embedded_suchat.db";
  // 表名前缀
  static const String tablePerfix = "suchat_";
  // 导出表文件临时存放的文件夹
  static const String exportDir = "db_export";
}
