import 'dart:convert';

import '../../../../../core/network/dio_client/cus_http_client.dart';
import '../../../../../core/utils/get_app_key_helper.dart';
import '../../../../../shared/constants/default_models.dart';

class IgdbToken {
  String accessToken;
  int expiresIn;
  String tokenType;

  IgdbToken({
    required this.accessToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory IgdbToken.fromJson(Map<String, dynamic> json) => IgdbToken(
    accessToken: json['access_token'],
    expiresIn: json['expires_in'],
    tokenType: json['token_type'],
  );
}

Future<IgdbToken> getIgdbAccessToken() async {
  try {
    var clientID = getStoredUserKey(
      "USER_TWITCH_CLIENT_ID",
      DefaultApiKeys.twitchClientId,
    );

    var clientSecret = getStoredUserKey(
      "USER_TWITCH_API_KEY",
      DefaultApiKeys.twitchApiKey,
    );

    var respData = await HttpUtils.post(
      path:
          "https://id.twitch.tv/oauth2/token?client_id=$clientID&client_secret=$clientSecret&grant_type=client_credentials",
      // 因为上拉下拉有加载圈，就不显示请求的加载了
      showLoading: false,
      data: {
        "client_id": clientID,
        "client_secret": clientSecret,
        "grant_type": "client_credentials",
      },
    );

    if (respData.runtimeType == String) {
      respData = json.decode(respData);
    }

    print("IGDB Access Token: $respData");

    return IgdbToken.fromJson(respData);
  } catch (e) {
    // API请求报错，显示报错信息
    rethrow;
  }
}
