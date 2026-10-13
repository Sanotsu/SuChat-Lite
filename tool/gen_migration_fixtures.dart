// 一次性工具：从 DDL 源文件提取建表语句生成迁移测试 fixture
// 用法: dart run tool/gen_migration_fixtures.dart <v1_ddl_path>
// ignore_for_file: avoid_print
import 'dart:io';

void main(List<String> args) {
  final v1Path = args[0];
  final curPath =
      'lib/features/unified_chat/data/database/unified_chat_ddl.dart';

  Directory('test/fixtures').createSync(recursive: true);
  generate(
    v1Path,
    'test/fixtures/migration_ddl_v1.dart',
    'kDdlV10Statements',
    '0.1.4 (commit 748e2ef) unified_chat DDL, v1 start schema',
  );
  generate(
    curPath,
    'test/fixtures/migration_ddl_current.dart',
    'kDdlCurrentStatements',
    'current unified_chat DDL, expected schema after migration',
  );
}

void generate(String srcPath, String outPath, String constName, String header) {
  var text = File(srcPath).readAsStringSync();

  // 1. table var map: tableXxx = 'value';
  final varMap = <String, String>{};
  for (final m in RegExp(
    r"table(\w+)\s*=\s*(?:String\s+)?'([^']*)';",
  ).allMatches(text)) {
    final val = m
        .group(2)!
        .replaceAll(r'${DBInitConfig.tablePerfix}', 'suchat_');
    varMap['table${m.group(1)}'] = val;
  }

  // 2. replace $tableXxx / ${tableXxx} references
  text = text.replaceAllMapped(
    RegExp(r'\$\{?table(\w+)\}?'),
    (m) => varMap['table${m.group(1)}'] ?? m.group(0)!,
  );

  // 3. extract CREATE statements (ddl source ends with "''';" — strip it)
  final stmts = RegExp(r'CREATE (?:UNIQUE )?(?:TABLE|INDEX)[^;]*;')
      .allMatches(text)
      .map((m) {
        var s = m.group(0)!.trim();
        if (s.endsWith("''';")) {
          s = '${s.substring(0, s.length - "''';".length).trimRight()};';
        }
        return s;
      })
      .toList();

  // 4. emit dart fixture
  final srcName = srcPath.replaceAll('\\', '/').split('/').last;
  final sb = StringBuffer()
    ..writeln('// 自动生成 (tool/gen_migration_fixtures.dart)：勿手改')
    ..writeln('// $header (src: $srcName)')
    ..writeln('const List<String> $constName = [');
  for (final s in stmts) {
    if (s.contains("'''")) throw 'statement contains triple quote';
    sb
      ..writeln("  r'''")
      ..writeln(s)
      ..writeln("''',");
  }
  sb.writeln('];');
  File(outPath).writeAsStringSync(sb.toString());
  print('generated $outPath (${stmts.length} statements)');
}
