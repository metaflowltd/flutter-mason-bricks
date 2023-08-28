part of 'pre_gen.dart';

class RouteBrickHelper {
  final HookContext context;

  RouteBrickHelper(this.context);

  Future<bool> isModulesDir() async {
    try {
      return await moduleFile().exists();
    } catch (e) {
      return false;
    }
  }

  File moduleFile() =>
      Directory.current.listSync().whereType<File>().firstWhere((element) => element.name.endsWith("_module.dart"));

  void addRouteToModule() {
    final name = context.vars['name'] as String;
    final file = moduleFile();
    final moduleData = file.readAsLinesSync();
    final classIndex = moduleData.indexWhere((element) => element.startsWith("class "));
    moduleData.insert(classIndex - 1, "import 'routes/${name.snakeCase}_route.dart';");
    final getItModuleParentIndex =
        moduleData.indexWhere((element) => element.contains(" extends GetItModule "), classIndex + 1);
    final isGetItModule = getItModuleParentIndex != -1;
    if (isGetItModule) {
      moduleData[getItModuleParentIndex] = moduleData[getItModuleParentIndex].replaceAll(
        " extends GetItModule ",
        " extends GoRouterModule ",
      );

      final importIndex = moduleData.indexOf("import 'package:prism_flutter_getit/modules/getit_module.dart';");
      if (importIndex == -1) {
        int insertIndex = 0;
        final lastImportIndex = moduleData.lastIndexWhere((element) => element.startsWith("import 'package:"));
        if (lastImportIndex != -1) {
          insertIndex - lastImportIndex;
        }
        moduleData.insert(insertIndex, "import 'package:prism_flutter_go_router/interfaces/module_route.dart';");
        moduleData.insert(insertIndex, "import 'package:prism_flutter_go_router/prism_flutter_go_router.dart';");
      } else {
        moduleData[importIndex] = "import 'package:prism_flutter_go_router/prism_flutter_go_router.dart';";
        moduleData.insert(importIndex, "import 'package:prism_flutter_go_router/interfaces/module_route.dart';");
      }

      final firstClassLine = moduleData.indexWhere((element) => element.contains("{"), getItModuleParentIndex);

      moduleData.insertAll(firstClassLine + 1, [
        "  @override",
        "  List<ModuleRoute> configureRoutes() {",
        "    return [",
        "      const ${name.pascalCase}Route(),",
        "    ];",
        "  }",
        ""
      ]);
    } else {
      final routesListIndex =
          moduleData.indexWhere((element) => element.contains("List<ModuleRoute> configureRoutes() {"));
      if (routesListIndex == -1) {
        context.logger.alert(red.wrap('CAnnot insert route, no sign of line "List<ModuleRoute> configureRoutes() {" '));
      } else {
        final listLine = moduleData.indexWhere((element) => element.contains("]"), routesListIndex);
        moduleData.insert(listLine, "      const ${name.pascalCase}Route(),");
      }
    }
    moduleData.add("");

    file.writeAsStringSync(moduleData.join("\n"));
  }

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

extension on FileSystemEntity {
  String get name => this.path.split(Platform.pathSeparator).last;
}
