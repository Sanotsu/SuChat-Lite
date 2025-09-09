// 来源 韩小韩WebAPI接口
// https://api.vvhan.com/
// 实测接口很不稳定
class VVhanAPIs {
  VVhanAPIs._();

  /// 默认直接输出文本(加type参数可输出json、js等)
  static List<String> textUrlList = [
    // 一言句子
    "https://api.vvhan.com/api/ian/rand",
    // 骚话
    "https://api.vvhan.com/api/text/sexy",
    // 情话
    "https://api.vvhan.com/api/text/love",
    // 笑话
    "https://api.vvhan.com/api/text/joke",
    // 舔狗日记
    "https://api.vvhan.com/api/text/dog",
  ];

  /// 图片
  // 美女图片(响应是图片)
  static List<String> beautyImages = [
    // 电脑分辨率美图:随机输出电脑分辨率cosplay或福利姬等美图
    "https://api.vvhan.com/api/wallpaper/pcGirl",
    // 手机分辨率美图:随机输出手机分辨率cosplay或福利姬等美图
    "https://api.vvhan.com/api/wallpaper/mobileGirl",
  ];

  // 其他图片(响应是图片)
  static List<String> otherImages = [
    // 摸鱼人日历(今天周几，多久放假)
    "https://api.vvhan.com/api/moyu",
    // 风景图片:随机输出一张超清风景图片
    "https://api.vvhan.com/api/wallpaper/views",
    //  二次元图片:随机输出一张超清动漫图片
    "https://api.vvhan.com/api/wallpaper/acg",
    // 推荐头像:随机输出一张推荐头像图片
    "https://api.vvhan.com/api/avatar/recommend",
    // 精选头像:随机输出一张精选头像图片
    "https://api.vvhan.com/api/avatar/rand",
    // 动漫头像:随机输出一张动漫头像图片
    "https://api.vvhan.com/api/avatar/dm",
    // 男生头像:随机输出一张男生头像图片
    "https://api.vvhan.com/api/avatar/boy",
    // 女生头像:随机输出一张女生头像图片
    "https://api.vvhan.com/api/avatar/girl",
    // 小众头像:随机输出一张小众头像图片
    "https://api.vvhan.com/api/avatar/niche",
  ];
}
