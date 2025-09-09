import 'dart:convert';

import 'package:tmdb_api/tmdb_api.dart';

import '../../../../../core/network/dio_client/cus_http_client.dart';

class CustomDiscover {
  String accessToken;

  CustomDiscover(this.accessToken);

  // 2025-08-18 和官方文档显示的顺序一致(除了有默认值集中在上方)
  // https://developer.themoviedb.org/reference/discover-movie
  Future<Map> getMovies({
    String? language = 'en-US',
    CustomSortMoviesBy sortBy = CustomSortMoviesBy.popularityDesc,
    int page = 1,
    bool includeAdult = false,
    bool includeVideo = false,
    String? certification,
    String? certificationGreaterThan,
    String? certificationLessThan,
    String? certificationCountry,
    int? primaryReleaseYear,
    String? primaryReleaseDateGreaterThan,
    String? primaryReleaseDateLessThan,
    String? region,
    String? releaseDateGreaterThan,
    String? releaseDateLessThan,
    int? voteAverageGreaterThan,
    int? voteAverageLessThan,
    int? voteCountGreaterThan,
    int? voteCountLessThan,
    String? watchRegion,
    String? withCast,
    String? withCompanies,
    String? withCrew,
    String? withGenres,
    String? withKeywords,
    String? withOriginCountry,
    String? withOrginalLanguage,
    String? withPeople,
    String? withReleaseType,
    int? withRunTimeGreaterThan,
    int? withRuntimeLessThan,
    String? withWatchMonetizationTypes,
    String? withWatchProviders,
    String? withoutCompanies,
    String? withoutGenres,
    String? withoutKeywords,
    String? withoutWatchProviders,
    int? year,
  }) {
    //all the default values
    final queries = <String>[
      'language=$language',
      'sort_by=${_getSortMovieBy(sortBy)}',
      'page=$page',
      'includeAdult=$includeAdult',
      'includeVideo=$includeVideo',
    ];

    if (certification != null && certificationCountry != null) {
      queries.add('certification=$certification');
    }

    if (certificationGreaterThan != null && certificationCountry != null) {
      queries.add('certification.gte=$certificationGreaterThan');
    }

    if (certificationLessThan != null && certificationCountry != null) {
      queries.add('certification.lte=$certificationLessThan');
    }

    if (certificationCountry != null) {
      queries.add('certification_country=$certificationCountry');
    }

    if (primaryReleaseYear != null) {
      queries.add('primary_release_year=$primaryReleaseYear');
    }

    if (primaryReleaseDateGreaterThan != null) {
      queries.add('primary_release_date.gte=$primaryReleaseDateGreaterThan');
    }

    if (primaryReleaseDateLessThan != null) {
      queries.add('primary_release_date.lte=$primaryReleaseDateLessThan');
    }

    if (region != null) {
      queries.add('region=$region');
    }

    if (releaseDateGreaterThan != null) {
      queries.add('release_date.gte=$releaseDateGreaterThan');
    }

    if (releaseDateLessThan != null) {
      queries.add('release_date.lte=$releaseDateLessThan');
    }

    if (voteAverageGreaterThan != null) {
      queries.add('vote_average.gte=$voteAverageGreaterThan');
    }

    if (voteAverageLessThan != null) {
      queries.add('vote_average.lte=$voteAverageLessThan');
    }

    if (voteCountGreaterThan != null) {
      queries.add('vote_count.gte=$voteCountGreaterThan');
    }

    if (voteCountLessThan != null) {
      queries.add('vote_count.lte=$voteCountLessThan');
    }

    if (watchRegion != null) {
      queries.add('watch_region=$watchRegion');
    }

    if (withCast != null) {
      queries.add('with_cast=$withCast');
    }

    if (withCompanies != null) {
      queries.add('with_companies=$withCompanies');
    }

    if (withCrew != null) {
      queries.add('with_crew=$withCrew');
    }

    if (withGenres != null) {
      queries.add('with_genres=$withGenres');
    }

    if (withKeywords != null) {
      queries.add('with_keywords=$withKeywords');
    }

    // 原方法缺少 with_origin_country
    if (withOriginCountry != null) {
      queries.add('with_origin_country=$withOriginCountry');
    }

    if (withOrginalLanguage != null) {
      queries.add('with_original_language=$withOrginalLanguage');
    }

    if (withPeople != null) {
      queries.add('with_people=$withPeople');
    }

    if (withReleaseType != null) {
      queries.add('with_release_type=$withReleaseType');
    }

    if (withRunTimeGreaterThan != null) {
      queries.add('with_runtime.gte=$withRunTimeGreaterThan');
    }

    if (withRuntimeLessThan != null) {
      queries.add('with_runtime.lte=$withRuntimeLessThan');
    }

    if (withWatchMonetizationTypes != null) {
      queries.add('with_watch_monetization_types=$withWatchMonetizationTypes');
    }

    if (withWatchProviders != null) {
      queries.add('with_watch_providers=$withWatchProviders');
    }

    if (withoutCompanies != null) {
      queries.add('without_companies=$withoutCompanies');
    }

    if (withoutGenres != null) {
      queries.add('without_genres=$withoutGenres');
    }

    if (withoutKeywords != null) {
      queries.add('without_keywords=$withoutKeywords');
    }

    // 原方法缺少 without_watch_providers
    if (withoutWatchProviders != null) {
      queries.add('without_watch_providers=$withoutWatchProviders');
    }

    if (year != null) {
      queries.add('year=$year');
    }

    return _query('movie', queries);
  }

  // 使用自己的http client来构建 _query 方法
  Future<Map> _query(String type, List<String> queries) async {
    var respData = await HttpUtils.get(
      path: "https://api.themoviedb.org/3/discover/$type?${queries.join('&')}",
      headers: {
        'Authorization': 'Bearer $accessToken',
        'accept': 'application/json',
      },
      showLoading: false,
      showErrorMessage: false,
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    return respData;
  }

  String _getSortMovieBy(CustomSortMoviesBy sortBy) {
    switch (sortBy) {
      case CustomSortMoviesBy.orginalTitleAsc:
        return 'orginal_title.asc';
      case CustomSortMoviesBy.orginalTitleDesc:
        return 'orginal_title.desc';
      case CustomSortMoviesBy.popularityAsc:
        return 'popularity.asc';
      case CustomSortMoviesBy.popularityDesc:
        return 'popularity.desc';
      case CustomSortMoviesBy.revenueAsc:
        return 'revenue.asc';
      case CustomSortMoviesBy.revenueDesc:
        return 'revenue.desc';
      case CustomSortMoviesBy.primaryReleaseDateAsc:
        return 'primary_release_date.asc';
      case CustomSortMoviesBy.primaryReleaseDateDesc:
        return 'primary_release_date.desc';
      case CustomSortMoviesBy.titleAsc:
        return 'title.asc';
      case CustomSortMoviesBy.titleDesc:
        return 'title.desc';
      case CustomSortMoviesBy.voteAverageAsc:
        return 'vote_average.asc';
      case CustomSortMoviesBy.voteAverageDesc:
        return 'vote_average.desc';
      case CustomSortMoviesBy.voteCountAsc:
        return 'vote_count.asc';
      case CustomSortMoviesBy.voteCountDesc:
        return 'vote_count.desc';
    }
  }

  Future<Map> getTvShows({
    String? language = 'en-US',
    SortTvShowsBy sortBy = SortTvShowsBy.popularityDesc,
    int page = 1,
    bool includeAdult = false,
    bool includeNullFirstAirDates = false,
    String? airDateGte,
    String? airDateLte,
    int? firstAirDateYear,
    String? firstAirDateGte,
    String? firstAirDateLte,
    bool? screenedTheatrically,
    String? timezone,
    double? voteAverageGte,
    double? voteAverageLte,
    int? voteCountGte,
    int? voteCountLte,
    String? watchRegion,
    String? withCompanies,
    String? withGenres,
    String? withKeywords,
    String? withNetworks,
    String? withOriginCountry,
    String? withOrginalLanguage,
    int? withRuntimeGte,
    int? withRuntimeLte,
    FilterTvShowsByStatus? withStatus,
    String? withWatchMonetizationTypes,
    String? withWatchProviders,
    String? withoutCompanies,
    String? withoutGenres,
    String? withoutKeywords,
    String? withoutWatchProviders,
    FilterTvShowsByType? withType,
  }) {
    //all the default values
    final queries = <String>[
      'language=$language',
      'sort_by=${_getSortTvShowsBy(sortBy)}',
      'page=$page',
      'includeAdult=$includeAdult',
      'include_null_first_air_dates=$includeNullFirstAirDates',
    ];

    if (airDateGte != null) {
      queries.add('air_date.gte=$airDateGte');
    }

    if (airDateLte != null) {
      queries.add('air_date.lte=$airDateLte');
    }

    if (firstAirDateYear != null) {
      queries.add('first_air_date_year=$firstAirDateYear');
    }

    if (firstAirDateGte != null) {
      queries.add('first_air_date.gte=$firstAirDateGte');
    }

    if (firstAirDateLte != null) {
      queries.add('first_air_date.lte=$firstAirDateLte');
    }

    if (screenedTheatrically != null) {
      queries.add('screened_theatrically=$screenedTheatrically');
    }

    if (timezone != null) {
      queries.add('timezone=$timezone');
    }

    if (voteAverageGte != null) {
      queries.add('vote_average.gte=$voteAverageGte');
    }

    // 原方法没有
    if (voteAverageLte != null) {
      queries.add('vote_average.lte=$voteAverageLte');
    }

    if (voteCountGte != null) {
      queries.add('vote_count.gte=$voteCountGte');
    }

    // 原方法没有
    if (voteCountLte != null) {
      queries.add('vote_count.lte=$voteCountLte');
    }

    if (watchRegion != null) {
      queries.add('watch_region=$watchRegion');
    }

    if (withCompanies != null) {
      queries.add('with_companies=$withCompanies');
    }

    if (withGenres != null) {
      queries.add('with_genres=$withGenres');
    }

    if (withKeywords != null) {
      queries.add('with_keywords=$withKeywords');
    }

    if (withNetworks != null) {
      queries.add('with_networks=$withNetworks');
    }

    // 原方法缺少 with_origin_country
    if (withOriginCountry != null) {
      queries.add('with_origin_country=$withOriginCountry');
    }

    if (withOrginalLanguage != null) {
      queries.add('with_original_language=$withOrginalLanguage');
    }

    if (withRuntimeGte != null) {
      queries.add('with_runtime.gte=$withRuntimeGte');
    }

    if (withRuntimeLte != null) {
      queries.add('with_runtime.lte=$withRuntimeLte');
    }

    if (withStatus != null) {
      queries.add('with_status=${_getFilterTvShowsByStatus(withStatus)}');
    }

    if (withWatchMonetizationTypes != null) {
      queries.add('with_watch_monetization_types=$withWatchMonetizationTypes');
    }

    if (withWatchProviders != null) {
      queries.add('with_watch_providers=$withWatchProviders');
    }

    if (withoutCompanies != null) {
      queries.add('without_companies=$withoutCompanies');
    }

    if (withoutGenres != null) {
      queries.add('without_genres=$withoutGenres');
    }

    if (withoutKeywords != null) {
      queries.add('without_keywords=$withoutKeywords');
    }

    // 原方法缺少 without_watch_providers
    if (withoutWatchProviders != null) {
      queries.add('without_watch_providers=$withoutWatchProviders');
    }

    if (withType != null) {
      queries.add('with_type=${_getFilterTvShowsByType(withType)}');
    }

    return _query('tv', queries);
  }

  String _getSortTvShowsBy(SortTvShowsBy sortBy) {
    switch (sortBy) {
      case SortTvShowsBy.popularityAsc:
        return 'popularity.asc';
      case SortTvShowsBy.popularityDesc:
        return 'popularity.desc';
      case SortTvShowsBy.voteAverageAsc:
        return 'vote_average.asc';
      case SortTvShowsBy.voteAverageDesc:
        return 'vote_average.desc';
      case SortTvShowsBy.firstAirDateAsc:
        return 'first_air_date.asc';
      case SortTvShowsBy.firstAirDateDesc:
        return 'first_air_date.desc';
    }
  }

  String _getFilterTvShowsByStatus(FilterTvShowsByStatus filter) {
    switch (filter) {
      case FilterTvShowsByStatus.returningSeries:
        return '0';
      case FilterTvShowsByStatus.planned:
        return '1';
      case FilterTvShowsByStatus.inProduction:
        return '2';
      case FilterTvShowsByStatus.ended:
        return '3';
      case FilterTvShowsByStatus.cancelled:
        return '4';
      case FilterTvShowsByStatus.pilot:
        return '5';
    }
  }

  String _getFilterTvShowsByType(FilterTvShowsByType filter) {
    switch (filter) {
      case FilterTvShowsByType.documentary:
        return '0';
      case FilterTvShowsByType.news:
        return '1';
      case FilterTvShowsByType.miniseries:
        return '2';
      case FilterTvShowsByType.reality:
        return '3';
      case FilterTvShowsByType.scripted:
        return '4';
      case FilterTvShowsByType.talkShow:
        return '5';
      case FilterTvShowsByType.video:
        return '6';
    }
  }
}

// 2025-08-18 查看文档中发现的排序类型
// https://developer.themoviedb.org/reference/discover-movie
enum CustomSortMoviesBy {
  orginalTitleAsc,
  orginalTitleDesc,
  popularityAsc,
  popularityDesc,
  revenueAsc,
  revenueDesc,
  primaryReleaseDateAsc,
  primaryReleaseDateDesc,
  titleAsc,
  titleDesc,
  voteAverageAsc,
  voteAverageDesc,
  voteCountAsc,
  voteCountDesc,
}

// 扩展方法：将 SortMoviesBy 转换为 CustomSortMoviesBy
extension SortMoviesByExtension on SortMoviesBy {
  CustomSortMoviesBy toCustomSortMoviesBy() {
    switch (this) {
      // 直接对应的值
      case SortMoviesBy.popularityAsc:
        return CustomSortMoviesBy.popularityAsc;
      case SortMoviesBy.popularityDesc:
        return CustomSortMoviesBy.popularityDesc;
      case SortMoviesBy.revenueAsc:
        return CustomSortMoviesBy.revenueAsc;
      case SortMoviesBy.revenueDesc:
        return CustomSortMoviesBy.revenueDesc;
      case SortMoviesBy.primaryReleaseDateAsc:
        return CustomSortMoviesBy.primaryReleaseDateAsc;
      case SortMoviesBy.primaryReleaseDateDesc:
        return CustomSortMoviesBy.primaryReleaseDateDesc;
      case SortMoviesBy.orginalTitleAsc:
        return CustomSortMoviesBy.orginalTitleAsc;
      case SortMoviesBy.orginalTitleDesc:
        return CustomSortMoviesBy.orginalTitleDesc;
      case SortMoviesBy.voteAverageAsc:
        return CustomSortMoviesBy.voteAverageAsc;
      case SortMoviesBy.voteAverageDesc:
        return CustomSortMoviesBy.voteAverageDesc;
      case SortMoviesBy.voteCountAsc:
        return CustomSortMoviesBy.voteCountAsc;
      case SortMoviesBy.voteCountDesc:
        return CustomSortMoviesBy.voteCountDesc;

      // // 需要转换的值（假设 releaseDate 对应 title）
      // case SortMoviesBy.releaseDateAsc:
      //   return CustomSortMoviesBy.titleAsc;
      // case SortMoviesBy.releaseDateDesc:
      //   return CustomSortMoviesBy.titleDesc;

      // 默认值（处理不存在的映射）
      default:
        return CustomSortMoviesBy.popularityDesc;
    }
  }
}
