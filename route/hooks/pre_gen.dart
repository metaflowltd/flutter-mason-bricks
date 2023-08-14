import 'dart:io';

import 'package:mason/mason.dart';
import 'package:yaml/yaml.dart';

Future run(HookContext context) async {
  final logger = context.logger;
  final helper = _Helper(context);

  final directory = Directory.current.path;
  try {
    final (packageName, modulePath) = await helper.retrievePaths();
    final subdomainConst = helper.subdomainConst();

    context.vars = {
      ...context.vars,
      'fullPath': ('$packageName/$modulePath').replaceAll('//', '/'),
      'metadata_file_name': helper.metadataFile().name,
      'analytics_domain_const': helper.domainConst(),
      'has_subdomain': subdomainConst.isNotEmpty,
      'analytics_subdomain_const': subdomainConst,
    };
  } on RangeError catch (_) {
    logger.alert(red.wrap('Could not find lib folder in $directory'));
    logger.alert(red.wrap('Re-run this brick inside your lib folder'));
    throw Exception();
  } on FileSystemException catch (e, s) {
    logger.alert(red.wrap('$e $s Could not find pubspec.yaml folder in ${directory.replaceAll('\\lib', '')}'));
    throw Exception();
  } on PubspecNameException catch (_) {
    logger.alert(red.wrap('Could not read package name in pubspec.yaml}'));
    logger.alert(red.wrap('Does your pubspec have a name: ?'));
    throw Exception();
  } on MetadataFileException catch (_) {
    logger.alert(red.wrap('Something is wrong with metadata file'));
    throw Exception();
  } on NoDomainNameException catch (_) {
    logger.alert(red.wrap('Domain name is empty and no consts in metadata file found'));
    throw Exception();
  } on Exception catch (e) {
    throw e;
  }
}

class _Helper {
  final HookContext context;

  _Helper(this.context);

  Future<(String, String)> retrievePaths() async {
    final directory = Directory.current.path;
    List<String> folders;

    if (Platform.isWindows) {
      folders = directory.split(r'\').toList();
    } else {
      folders = directory.split('/').toList();
    }
    final libIndex = folders.indexWhere((folder) => folder == 'lib');
    final modulePath = folders.sublist(libIndex + 1, folders.length).join('/');
    final pubSpecFile = File('${folders.sublist(0, libIndex).join('/')}/pubspec.yaml');
    final content = await pubSpecFile.readAsString();
    final yamlMap = loadYaml(content);
    final packageName = yamlMap['name'];

    if (packageName is! String) {
      throw PubspecNameException();
    }

    return (packageName, modulePath);
  }

  File metadataFile() {
    try {
      final directory = Directory.current.path;

      String metadataFile = context.vars['metadata_file_name'].toString().toLowerCase();
      if (metadataFile.isEmpty) {
        final routesFolder = Directory('$directory/routes');
        return routesFolder.listSync().whereType<File>().firstWhere((element) => element.name.contains("metadata"));
      } else {
        return File('$directory/routes/$metadataFile');
      }
    } catch (_) {
      throw MetadataFileException();
    }
  }

  String domainConst() {
    final file = metadataFile();
    final lines = file.readAsStringSync().split("\n");
    final domainValue = context.vars['analytics_domain'].toString();
    final String line;
    if (domainValue.isEmpty) {
      line = lines.firstWhere(
        (line) => line.toLowerCase().contains("domain"),
        orElse: () => throw NoDomainNameException(),
      );
    } else {
      line = lines.firstWhere(
        (line) => line.endsWith(' = "$domainValue";'),
        orElse: () => "",
      );
    }

    final parts = line.split("=");

    if (line.isEmpty || parts.isEmpty || parts[0].startsWith("const String") == false) {
      return _appendNewConstLine(domainValue, "Domain", file);
    }

    return parts[0].substring(12).trim();
  }

  String subdomainConst() {
    final subdomainValue = context.vars['analytics_subdomain'].toString();
    if (subdomainValue.isEmpty) {
      return "";
    }

    final file = metadataFile();
    final lines = file.readAsStringSync().split("\n");
    final line = lines.firstWhere(
      (line) => line.endsWith(' = "$subdomainValue";'),
      orElse: () => "",
    );
    final parts = line.split("=");

    if (line.isEmpty || parts.isEmpty || parts[0].startsWith("const String") == false) {
      return _appendNewConstLine(subdomainValue, "SubDomain", file);
    }

    return parts[0].substring(12).trim();
  }

  String _appendNewConstLine(String subdomainValue, String suffix, File file) {
    final constName = "$subdomainValue$suffix";
    final newLine = 'const String $constName = "$subdomainValue";\n';
    file.writeAsStringSync(newLine, mode: FileMode.append);
    context.logger.info(magenta.wrap('Adding new line to file:${file.name}\n$newLine'));
    return constName;
  }
}

class PubspecNameException implements Exception {}

class MetadataFileException implements Exception {}

class NoDomainNameException implements Exception {}

extension on FileSystemEntity {
  String get name => this.path.split(Platform.pathSeparator).last;
}
