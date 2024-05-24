
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AuthSessionConfig {

  static final AuthSessionConfig shared = AuthSessionConfig._();

  late final Future<Dio> _dio;

  late final String _domain;
  late final String _site;

  late Future<String> _securityToken;

  AuthSessionConfig._() {
    _initDomainSite();
    //
    final dio = Dio();
    _dio = _configDio(dio);
    //
    _loadSecurityToken();
  }

  void _initDomainSite() {
    _site = '2001774';
    _domain = 'k12home2.coquan.vn';
  }

  void _loadSecurityToken() async {
    _securityToken = _dio
      .then((dio) => _getAppInfo(dio: dio, domain: _domain)
      .then((appInfo) => appInfo['csrfToken']));
  }

  Future<Dio> _configDio(Dio dio) async {
    Directory tempDir = await getTemporaryDirectory();

    final tempPath = tempDir.path;
    final cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(tempPath),
    );
    dio.interceptors.add(CookieManager(cookieJar));

    return _signIn(dio: dio, domain: _domain, username: 'manhpd@vhv.vn', password: 'Demo@123');
  }

  String getSite() => _site;

  Future<String> getSecurityToken() => _securityToken;

  Future<Dio> getDio() => _dio;

  String getDomain() => _domain;
}

Future<Map<String, dynamic>> _getAppInfo({
  required Dio dio,
  required String domain,  
}) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String version = packageInfo.version;
  final deviceId = await DeviceInfoPlugin().androidInfo.then((value) => value.id);
  final String url = 'https://$domain/api/CMS.Application/getInfo?deviceId=$deviceId&appVersion=$version&appBundleId=${packageInfo.packageName}';

  debugPrint(url);

  final response = await dio.get(url, options: Options(headers: {'Content-Type': 'application/json'}));
  return response.data;
}

Future<Dio> _signIn({
  required Dio dio,
  required String domain,  
  required String username,
  required String password,
}) async {
  final String url = 'https://$domain/api/Member/User/login';

  FormData formData = FormData.fromMap({
    'fields[username]': username,
    'fields[password]': password,
  });
  await dio.post(url, data: formData, options: Options(headers: {'Content-Type': 'application/json'}));

  return dio;
}
