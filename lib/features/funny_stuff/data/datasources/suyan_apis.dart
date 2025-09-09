// 来源与素颜API聚合站点的一下API

class SuyanAPIs {
  // 私有构造函数防止实例化
  SuyanAPIs._();

  /// 图片接口
  // 美女图片(响应是图片)
  static List<String> beautyImages = [
    // 美女图片
    "https://api.suyanw.cn/api/meinv.php",
    // 黑丝图片
    "https://api.suyanw.cn/api/hs.php",
    // jk制服图
    "https://api.suyanw.cn/api/jk.php",
    // 淘宝随机买家秀图片
    "https://api.suyanw.cn/api/tbmjx.php",
    // 随机小姐姐美女图片
    "https://api.suyanw.cn/api/ksxjj.php",
    // 每次刷新都是不同的PC美女图片
    "https://api.suyanw.cn/api/pcmv.php",
    // 每次刷新都是不同的PE美女图片
    "https://api.suyanw.cn/api/sjmv.php",
    // 随机妹子
    "https://api.suyanw.cn/api/meizi.php",
    // 百度搜图
    "https://api.suyanw.cn/api/baidu_image_search.php?msg=美女",
    // 随机壁纸(参数都必填)
    // method ：【mobiel(手机端),pc(电脑端)】
    // lx ：【dongman（动漫）,meizi（美女）,fengjing（风景）,suiji（动漫和美女随机）】
    "https://api.suyanw.cn/api/sjbz.php?method=mobiel&lx=meizi",
    // 堆糖搜图
    // form	是	壁纸类型(精选，风景，星空，爱情，插画，科技，创意，汽车，美食，潮流)
    // type	否	返回格式，默认json，可选text/image/jump
    "https://api.suyanw.cn/api/duitang.php?msg=美女&type=image",

    // 360壁纸接口
    // n	int	否	壁纸类型，1为4K专区，2为美女模特，3为爱情美图，4为风景，5为小清新，6为动漫，
    // 7为明星，8为萌宠，9为游戏，10为汽车，11为炫酷，12为军事，13为劲爆，14为纹理，15为文字，16为限时。默认为动漫
    // type	string	否	返回格式，默认json可选text、image
    "https://api.suyanw.cn/api/360bizhi.php?n=2&type=image",
  ];

  // 其他图片(响应是图片)
  static List<String> otherImages = [
    // 你的名字图片
    "https://api.suyanw.cn/api/Yourname.php",
    // 原神图片
    "https://api.suyanw.cn/api/ys.php",
    // 朋友圈背景图
    "https://api.suyanw.cn/api/pyqbj.php",
    // 猫羽雫图片
    "https://api.suyanw.cn/api/mao.php",
    // 二次元随机动漫图片PC版
    "https://api.suyanw.cn/api/comic.php",
    // 二次元随机动漫图片PE版
    "https://api.suyanw.cn/api/comic2.php",
    // 二次元随机动漫图片自动适应版
    "https://api.suyanw.cn/api/comic3.php",
    // 随机mc酱动漫图片
    "https://api.suyanw.cn/api/mcapi.php",
    // 随机头像
    "https://api.suyanw.cn/api/sjtx.php",
    // 随机高清风景壁纸
    "https://api.suyanw.cn/api/scenery.php",
    // Bing每日图(这个每次刷新都是当日的图片)
    // "https://api.suyanw.cn/api/bing.php",
    // 舔狗日记图文版
    "https://api.suyanw.cn/api/tgbj.php",
    // 小米壁纸
    // form	是	壁纸类型(精选，风景，星空，爱情，插画，科技，创意，汽车，美食，潮流)
    // type	否	返回格式，默认json，可选text/image/jump
    "https://api.suyanw.cn/api/xiaomi_bz.php?form=精选&type=image",
  ];

  // 响应是json图片
  static List<String> jsonImages = [
    // // https://api.suyanw.cn/doc/loveanimer.php
    // // 随机壁纸：这个json，地址在 data-> url 中
    // // 但不是随机，始终只有一张，所以不用
    // // "https://api.suyanw.cn/api/loveanimer.php",

    // 这个直接图片地址文本
    "https://api.suyanw.cn/api/picture.php?msg=美女",
    // B站APP随机开屏壁纸： 直接图片地址
    "https://api.suyanw.cn/api/bilibili_start_image.php",
    // 高清壁纸： 这个返回地址文本，但被标记包裹: `±img=<图片地址>±`
    "https://api.suyanw.cn/api/bizhi.php?msg=1",
    //cos图： 这个json，地址在 text 中
    "https://api.suyanw.cn/api/cos.php?type=json",
    // 随机美腿小姐姐： 这个json，地址在 text 中
    "https://api.suyanw.cn/api/meitui.php?type=json",
  ];

  /// 直接响应文字的文案接口
  static List<String> textUrlList = [
    // 随机一言
    "https://api.suyanw.cn/api/yiyan.php",
    // 我在人间凑数的日子
    "https://api.suyanw.cn/api/renjian.php",
    // 朋友圈文案
    "https://api.suyanw.cn/api/pyq.php",
    // 网易云热评
    "https://api.suyanw.cn/api/wyyrp.php",
    // 随机情话
    "https://api.suyanw.cn/api/love.php",
    // 随机污话骚话
    "https://api.suyanw.cn/api/saohua.php",
    // 安慰文案
    "https://api.suyanw.cn/api/anwei.php",
    // 趣味笑话
    "https://api.suyanw.cn/api/qwxh.php",
    // 疯狂星期四文案
    "https://api.suyanw.cn/api/kfcyl.php",
    // 人生话语
    "https://api.suyanw.cn/api/rshy.php",
    // 搞笑语录
    "https://api.suyanw.cn/api/gaoxiao.php",
    // 爱情语录
    "https://api.suyanw.cn/api/qhyl.php",
    // 情感一言
    "https://api.suyanw.cn/api/qg.php",
    // 经典语录
    "https://api.suyanw.cn/api/jdyl.php",
    // 随机唯美文案
    "https://api.suyanw.cn/api/weimei.php",
    // 随机美句摘抄文案
    "https://api.suyanw.cn/api/meiju",
    // 随机输出诗词佳句，筛选自《诗经》、《名诗》等
    "https://api.suyanw.cn/api/gushi.php",
    // 随机皮皮的话文案
    "https://api.suyanw.cn/api/pp.php",
    // 随机输出一条毒鸡汤
    "https://api.suyanw.cn/api/djt.php",
    // 每日一份毒鸡汤，清醒你的人生
    "https://api.suyanw.cn/api/djt2.php",
    "https://api.suyanw.cn/api/djt3.php",
    // 历史上的今天（文字太多了）
    // "https://api.suyanw.cn/api/lishi.php",
    // 口吐芬芳(都是粗鄙的脏话)
    // msg	否	输数字(1=滚刀/2=殴打/3=散扣/4=嘲讽/5=口吐)(默认1=滚刀)
    // type	否	返回格式，默认text可选json、js
    // "https://api.suyanw.cn/api/Ridicule.php?msg=4&type=text",
  ];
}
