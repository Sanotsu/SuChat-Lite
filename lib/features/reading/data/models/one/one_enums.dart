// 文章列表

// 在one 原版app的分类页面顶部分类为: 阅读、日签、专题、问答、长篇、小记、热榜、书影、音乐、作者
//
// 其中：
// 专题、小记、热榜(榜单)、长篇(连载)、作者 是各自单独的API，返回的结构完全不同
// 图文(日签)、阅读、问答、音乐、书影(影视)、【电台，单独的收音机模块】是同一个API，返回的结构稍微不同
//    https://apis.netstart.cn/one/find/bymonth/:category/:month
//    长篇两个接口都可以查询(使用单独的):
//        https://apis.netstart.cn/one/find/serial/byyear/2022
//        https://apis.netstart.cn/one/find/bymonth/2/2022-12
enum OneCategory {
  hp(0, '图文', 'hp'), // 日签
  essay(1, '阅读', 'essay'),
  question(3, '问答', 'question'),
  music(4, '音乐', 'music'), // 最近几年没有
  movie(5, '影视', 'movie'), // 最近纪念没有，内容不多
  radio(8, '电台', 'radio'),
  // 在查询列表时没有9这个歌单分类；但查询用户收藏文章列表时，有9这个歌单分类
  playlist(9, '歌单', 'playlist'),
  // 没有这个分类编号，但查询文章详情时，需要这个字符串
  topic(777, '专题', 'topic'),
  serialcontent(2, '连载', 'serialcontent'), // 长篇(最近几年没有了)

  /// 查询文章列表没有作者栏位，但搜索接口有这个关键字
  /// https://apis.netstart.cn/one/search/:categoryName/:keyword/:page
  /// categoryName	分类名	string	√	图文hp、阅读reading、音乐 music、影视 movie、ONE电台 radio、作者/音乐人 author
  author(10, '作者', 'author');

  final int id;
  final String title;
  final String apiName;

  const OneCategory(this.id, this.title, this.apiName);

  /// 根据数字ID获取分类
  static OneCategory? fromId(int id) {
    for (var category in OneCategory.values) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// 根据API名称获取分类
  static OneCategory? fromApiName(String apiName) {
    for (var category in OneCategory.values) {
      if (category.apiName == apiName) return category;
    }
    return null;
  }

  /// 根据字符串分类获取API名称
  static String getApiName(String? category) {
    if (category == null) return 'essay';

    // 如果是数字字符串，转换为数字再查找
    final id = int.tryParse(category);
    if (id != null) {
      final cat = fromId(id);
      return cat?.apiName ?? 'essay';
    }

    // 如果是字符串，直接查找
    final cat = fromApiName(category);
    return cat?.apiName ?? category;
  }
}
