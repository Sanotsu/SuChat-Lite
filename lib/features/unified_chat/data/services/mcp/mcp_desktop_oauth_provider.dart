import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:mcp_dart/mcp_dart.dart';

import '../../../../../../core/utils/simple_tools.dart';
import '../../models/mcp_models.dart';
import '../unified_secure_storage.dart';

/// 2026-09-15 P4-2 OAuth授权码流(桌面端MVP)
///
/// MCP SEP-21授权：SDK transport内置了元数据发现/动态客户端注册/PKCE/
/// code交换——provider只需负责：
/// ①令牌持久化(secure storage) ②打开系统浏览器 ③本地loopback回调
/// 等待授权码 ④调transport.finishAuthRedirect完成交换
///
/// 流程：请求401 → transport准备授权URL并调redirectToAuthorizationUrl
/// (本类内阻塞等待用户在浏览器完成授权并交换令牌) → 抛UnauthorizedError
/// → manager重试连接(tokens()已有值自动带Bearer) → 成功
///
/// 仅桌面端使用(依赖dart:io HttpServer本地回调+系统浏览器)；移动端
/// 浏览器回调需要deep link基建，暂不接入
class McpDesktopOAuthProvider implements OAuthAuthorizationCodeProvider {
  McpDesktopOAuthProvider._(this._config, this._loopbackPort, this._server);

  /// 为server创建provider：立即绑定127.0.0.1随机端口作为回调地址。
  /// 仅桌面端可调用(调用方已做平台判断)；绑定失败抛错由调用方处理
  static Future<McpDesktopOAuthProvider> create(McpServerConfig config) async {
    final server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
    return McpDesktopOAuthProvider._(config, server.port, server);
  }

  final McpServerConfig _config;
  final int _loopbackPort;
  final io.HttpServer _server;

  /// finishAuthRedirect所需(构造后由manager注入)
  dynamic _transport;

  /// attachTransport: 授权码交换要回到transport完成
  // ignore: avoid_setters_without_getters
  set transport(dynamic transport) => _transport = transport;

  Completer<Uri>? _pendingCallback;
  bool _disposed = false;

  @override
  Uri get redirectUri => Uri.parse('http://127.0.0.1:$_loopbackPort/callback');

  /// 预注册客户端ID(留空字符串=SDK走动态客户端注册)
  @override
  String get clientId => _config.oauthClientId ?? '';

  @override
  String? get clientSecret => null;

  @override
  List<String> get scopes {
    final raw = _config.oauthScopes?.trim() ?? '';
    if (raw.isEmpty) return const [];
    return raw.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
  }

  @override
  Future<OAuthTokens?> tokens() async {
    final raw = await UnifiedSecureStorage.getMcpOAuthTokens(_config.id);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final access = decoded['access_token'];
      if (access is! String || access.isEmpty) return null;
      return OAuthTokens(
        accessToken: access,
        refreshToken: decoded['refresh_token'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveTokens(OAuthTokens tokens) async {
    final payload = <String, dynamic>{
      'access_token': tokens.accessToken,
      if (tokens.refreshToken != null) 'refresh_token': tokens.refreshToken,
      if (tokens is OAuthAuthorizationCodeTokens) ...{
        if (tokens.tokenType.isNotEmpty) 'token_type': tokens.tokenType,
        if (tokens.expiresIn != null) 'expires_in': tokens.expiresIn,
        if (tokens.scope != null) 'scope': tokens.scope,
      },
      'saved_at': DateTime.now().millisecondsSinceEpoch,
    };
    await UnifiedSecureStorage.setMcpOAuthTokens(
      _config.id,
      jsonEncode(payload),
    );
  }

  /// 基类旧接口(无参授权导航)：授权码流走redirectToAuthorizationUrl，
  /// 此方法不会被OAuthAuthorizationCodeProvider路径调用
  @override
  Future<void> redirectToAuthorization() async {
    throw UnsupportedError('请使用授权码流(redirectToAuthorizationUrl)');
  }

  /// 打开系统浏览器并阻塞等待loopback回调，拿到授权码后交transport
  /// 完成PKCE交换(saveTokens由SDK回调)。用户授权通常秒级~分钟级，
  /// 阻塞期间connect的超时由外层放宽(OAuth流程自带5分钟上限)
  @override
  Future<void> redirectToAuthorizationUrl(Uri authorizationUri) async {
    if (_disposed) {
      throw StateError('OAuth provider已释放');
    }

    pl.i('MCP OAuth: 打开浏览器授权(${_config.name})');
    launchStringUrl(authorizationUri.toString());

    final callback = Completer<Uri>();
    _pendingCallback = callback;
    try {
      final redirect = await callback.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () => throw TimeoutException('OAuth授权等待超时(5分钟)'),
      );

      final code = redirect.queryParameters['code'];
      if (code == null || code.isEmpty) {
        final error = redirect.queryParameters['error'];
        throw StateError('OAuth授权失败: ${error ?? '回调缺少授权码'}');
      }
      final state = redirect.queryParameters['state'] ?? '';

      final transport = _transport;
      if (transport is StreamableHttpClientTransport) {
        // SDK校验state与issuer后完成code交换并回调saveTokens
        await transport.finishAuthRedirect(code, state: state);
      } else {
        throw StateError('OAuth transport未就绪');
      }
      pl.i('MCP OAuth: 授权完成(${_config.name})');
    } finally {
      _pendingCallback = null;
    }
  }

  /// 释放loopback回调server(server删除/断开时调用)
  Future<void> dispose() async {
    _disposed = true;
    _pendingCallback?.completeError(StateError('OAuth provider已释放'));
    _pendingCallback = null;
    try {
      await _server.close(force: true);
    } catch (_) {}
  }
}
