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
    final declareRouteInModule = context.vars['declare_route_in_module'] as bool;
    final file = moduleFile();
    var fileString = file.readAsStringSync();


    final replacesMap = <String, String>{};

    // Appending imports
    final importsRegexp = RegExp(r'(?<imports>[\s\S]+)\nclass');
    final importsMatch = importsRegexp.firstMatch(fileString)!;
    final imports = importsMatch.namedGroup('imports')!;
    final importsBuffer = StringBuffer();
    if (declareRouteInModule && !imports.contains("prism_flutter_go_router")) {
      importsBuffer.write("import 'package:prism_flutter_go_router/prism_flutter_go_router.dart';\n");
      importsBuffer.write("import 'package:prism_flutter_go_router/interfaces/module_route.dart';\n");
      importsBuffer.write("import 'routes/${name.snakeCase}_route.dart';\n");
    }
    importsBuffer.write("import 'ui/screens/${name.snakeCase}/${name.snakeCase}_bloc.dart';\n");
    replacesMap[imports] = "${imports}${importsBuffer.toString()}";
    //

    // Declaring module route
    if (declareRouteInModule) {
      final classSignatureRegexp = RegExp(
          r"class(?<class>[\s\S]+)extends(?<parent>[\s\S]+?)(with(?<mixins>[\s\S]+?))?(implements(?<interfaces>[\s\S]+))(?<classBody>{[\s\S]+})");
      final classSignatureMatch = classSignatureRegexp.firstMatch(fileString)!;
      final parent = classSignatureMatch.namedGroup('parent')!;
      final mixins = classSignatureMatch.namedGroup('mixins');

      final isGoRouterModule = mixins?.contains('GoRouterModuleMixin') ?? false;
      if (!isGoRouterModule) {
        if (mixins != null) {
          replacesMap[mixins] = ' GoRouterModuleMixin, $mixins';
        } else {
          replacesMap[parent] = "${parent}with GoRouterModuleMixin ";
        }

        replacesMap['{'] = """{
    @override
    List<ModuleRoute> configureRoutes() => [
      const ${name.pascalCase}Route(),
    ];
    """;
      } else {
        final routesRegexp = RegExp(r'configureRoutes\(\)[\s\S]+?(?<routes>\[[\s\S]+?\])');
        final routesMatch = routesRegexp.firstMatch(fileString);
        final routes = routesMatch?.namedGroup('routes');
        if (routes != null) {
          final listEndIndex = routes.indexOf("]");
          final replaceRoutes = routes.substring(0, listEndIndex) + "\tconst ${name.pascalCase}Route(),\n\t\t]";

          replacesMap[routes] = replaceRoutes;
        } else {
          context.logger.alert(red.wrap('Cannot insert route, no sign of "configureRoutes" method'));
        }
      }
    }
    //

    // Declaring bloc factory
    final blocFactoriesRegexp = RegExp(r'(?<blocFactories>blocFactories: \[)');
    final moduleOutputRegexp = RegExp(r'(?<moduleOutput>(\s|\()ModuleOutput\()');
    final blocFactoriesMatch = blocFactoriesRegexp.firstMatch(fileString);
    final moduleOutputMatch = moduleOutputRegexp.firstMatch(fileString);
    final blocFactoriesDeclaration = blocFactoriesMatch?.namedGroup('blocFactories');
    final moduleOutputDeclaration = moduleOutputMatch?.namedGroup('moduleOutput');
    if (blocFactoriesDeclaration != null) {
      replacesMap[blocFactoriesDeclaration] = """$blocFactoriesDeclaration
        BlocFactory(
          (context, {args}) => ${name.pascalCase}Bloc(),
        ),""";
    } else if (moduleOutputDeclaration != null) {
      replacesMap[moduleOutputDeclaration] = """$moduleOutputDeclaration
      blocFactories: [
        BlocFactory(
          (context, {args}) => ${name.pascalCase}Bloc(),
        ),
      ]""";
    } else {
      context.logger.alert(red.wrap('Cannot insert bloc factory, no sign of module output registration'));
    }
    //

    // Applying changes
    for (final replaceEntry in replacesMap.entries) {
      fileString = fileString.replaceFirst(replaceEntry.key, replaceEntry.value);
    }

    file.writeAsStringSync(fileString);
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
    final file = metadataFile();
    final lines = file.readAsStringSync().split("\n");
    final subdomainValue = context.vars['analytics_subdomain'].toString();
    final String line;
    if (subdomainValue.isEmpty) {
      line = lines.firstWhere(
        (line) => line.contains("SubDomain"),
        orElse: () => throw NoSubDomainNameException(),
      );
    } else {
      line = lines.firstWhere(
        (line) => line.endsWith(' = "$subdomainValue";'),
        orElse: () => "",
      );
    }

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
