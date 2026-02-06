import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version.dart';

class UpdateRepository {
  final String apiUrl = "https://api.github.com/repos/mlacnout-sketch/stabil/releases";

  Future<AppVersion?> fetchUpdate() async {
    try {
      print("Checking update from: $apiUrl");
      final response = await http.get(Uri.parse(apiUrl));
      print("Response status: ${response.statusCode}");
      
      if (response.statusCode != 200) {
        print("Failed to fetch updates: ${response.body}");
        return null;
      }

      final List releases = json.decode(response.body);
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;
      
      print("Current App: $currentVersion ($currentBuildNumber)");
      print("Found ${releases.length} releases.");

      for (var release in releases) {
        final tagName = release['tag_name'].toString();
        print("Checking release tag: $tagName");
        
        if (_isNewer(tagName, currentVersion, currentBuildNumber)) {
          print("Newer version found: $tagName");
          final assets = release['assets'] as List?;
          if (assets == null) {
             print("No assets in this release.");
             continue;
          }

          final asset = assets.firstWhere(
            (a) => a['content_type'] == 'application/vnd.android.package-archive' || a['name'].toString().endsWith('.apk'),
            orElse: () => null
          );

          if (asset != null) {
            print("APK asset found: ${asset['name']}");
            return AppVersion(
              name: tagName,
              apkUrl: asset['browser_download_url'],
              apkSize: asset['size'],
              description: release['body'] ?? "",
            );
          } else {
            print("No APK asset found in release $tagName");
          }
        }
      }
    } catch (e) {
      print("Error fetching update: $e");
    }
    print("No update available.");
    return null;
  }

  bool _isNewer(String latestTag, String currentVersion, String currentBuildNumber) {
    try {
      // 1. Parse Semantic Version (1.0.3)
      final RegExp regVer = RegExp(r'(\d+)\.(\d+)\.(\d+)');
      final match1 = regVer.firstMatch(latestTag);
      final match2 = regVer.firstMatch(currentVersion);

      if (match1 == null || match2 == null) return false;

      final v1 = [
        int.parse(match1.group(1)!),
        int.parse(match1.group(2)!),
        int.parse(match1.group(3)!)
      ];
      
      final v2 = [
        int.parse(match2.group(1)!),
        int.parse(match2.group(2)!),
        int.parse(match2.group(3)!)
      ];

      for (int i = 0; i < 3; i++) {
        if (v1[i] > v2[i]) return true;
        if (v1[i] < v2[i]) return false;
      }
      
      // 2. If Versions Equal (1.0.3 == 1.0.3), Compare Build Number
      // Tag format: v1.0.3-b123
      if (latestTag.contains("-b")) {
        final RegExp regBuild = RegExp(r'-b(\d+)');
        final matchBuild = regBuild.firstMatch(latestTag);
        
        if (matchBuild != null) {
          final remoteBuild = int.tryParse(matchBuild.group(1)!);
          final localBuild = int.tryParse(currentBuildNumber) ?? 0;
          
          if (remoteBuild != null) {
            print("Comparing Build: Remote $remoteBuild vs Local $localBuild");
            return remoteBuild > localBuild;
          }
        }
      }
      
      return false;
    } catch (e) {
      print("Compare Error: $e");
      return false;
    }
  }
}