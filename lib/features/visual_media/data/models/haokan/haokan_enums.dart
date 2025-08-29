/// 所有榜单的枚举
/// 将 API 返回值构建为枚举 https://apis.netstart.cn/haokan/top/index
/// [{"id": "1","name": "人气榜"},
/// {"id": "4","name": "男生榜"},
/// {"id": "5","name": "女生榜"},
/// {"id": "2","name": "新作榜"},
/// {"id": "6","name": "催更榜"}]
enum ComicTop {
  popular(1, '人气榜'),
  male(4, '男生榜'),
  female(5, '女生榜'),
  latest(2, '新作榜'),
  urged(6, '催更榜');

  final int id;
  final String title;

  const ComicTop(this.id, this.title);
}

/// 所有分类的枚举
/// 将 API 返回值构建为枚举 https://apis.netstart.cn/haokan/category/list
enum ComicCategory {
  all(99, '全部'), // 这个在接口数据中没有，但查询时实测在不传分类时可能查询所有
  urban(1, '都市'),
  romance(2, '恋爱'),
  hilarious(3, '爆笑'),
  hotBlooded(4, '热血'),
  suspense(5, '悬疑'),
  ancient(6, '古风'),
  campus(7, '校园'),
  funny(9, '搞笑'),
  fantasy(10, '玄幻'),
  inspiring(11, '励志'),
  horror(13, '恐怖'),
  adventure(14, '冒险'),
  children(15, '儿童');

  final int id;
  final String title;

  const ComicCategory(this.id, this.title);

  static ComicCategory fromId(int id) {
    return ComicCategory.values.firstWhere(
      (category) => category.id == id,
      orElse: () => ComicCategory.urban,
    );
  }

  static ComicCategory fromTitle(String title) {
    return ComicCategory.values.firstWhere(
      (category) => category.title == title,
      orElse: () => ComicCategory.urban,
    );
  }
}

/// 所有状态的枚举
/// 将 API 返回值构建为枚举 https://apis.netstart.cn/haokan/comic/status
enum ComicEndStatus {
  all(0, '全部'),
  ongoing(1, '连载'),
  completed(2, '完结');

  final int id;
  final String title;

  const ComicEndStatus(this.id, this.title);

  static ComicEndStatus fromId(int id) {
    return ComicEndStatus.values.firstWhere(
      (status) => status.id == id,
      orElse: () => ComicEndStatus.all,
    );
  }
}

enum ComicFreeStatus {
  all(0, '全部'),
  free(1, '免费'),
  vip(2, '付费');

  final int id;
  final String title;

  const ComicFreeStatus(this.id, this.title);

  static ComicFreeStatus fromId(int id) {
    return ComicFreeStatus.values.firstWhere(
      (status) => status.id == id,
      orElse: () => ComicFreeStatus.all,
    );
  }
}

enum ComicSortType {
  latest(0, '最新'),
  hottest(1, '最热');

  final int id;
  final String title;

  const ComicSortType(this.id, this.title);

  static ComicSortType fromId(int id) {
    return ComicSortType.values.firstWhere(
      (sort) => sort.id == id,
      orElse: () => ComicSortType.latest,
    );
  }
}
