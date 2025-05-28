// 用户自定义输入的平台的密钥的相关key枚举，
// 在表单验证、保存到缓存、读取时都使用的关键字，避免过多魔法值出错
// SelfKeyName
import '../storage/cus_get_storage.dart';

// 从缓存中获取用户自定义的密钥,没取到就用预设的
String getStoredUserKey(String key, String defaultValue) {
  return CusGetStorage().getUserAKMap()[key] != null &&
          CusGetStorage().getUserAKMap()[key]!.isNotEmpty
      ? CusGetStorage().getUserAKMap()[key]!
      : defaultValue;
}
