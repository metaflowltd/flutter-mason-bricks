import 'package:lumen_client_core/lumen_client_core.dart';{{#has_repository}}
import 'package:{{{fullPath}}}/{{name.snakeCase()}}/data/repositories/{{name.snakeCase()}}_repository.dart';{{/has_repository}}{{#needs_configuration_service}}
import 'package:{{{fullPath}}}/{{name.snakeCase()}}/domain/services/{{name.snakeCase()}}_configuration_service.dart';{{/needs_configuration_service}}{{#has_services}}
import 'package:{{{fullPath}}}/{{name.snakeCase()}}/domain/services/{{name.snakeCase()}}_service.dart';{{/has_services}}{{#has_module_api}}
import 'package:{{{fullPath}}}/{{name.snakeCase()}}/{{name.snakeCase()}}_module_api.dart';{{/has_module_api}}{{#has_routes}}
import 'package:prism_flutter_go_router/interfaces/module_route.dart';
import 'package:prism_flutter_go_router/prism_flutter_go_router.dart';{{/has_routes}}

class {{name.pascalCase()}}Module extends {{#is_dependent_module}}Dependent{{/is_dependent_module}}LumenModule{{#has_module_api}}<{{name.pascalCase()}}ModuleApi>{{/has_module_api}}{{#has_routes}} with GoRouterModuleMixin{{/has_routes}} implements ModuleMetadata {
{{#is_dependent_module}}  @override
  ModuleDependenciesMetadata get dependencies => ModuleDependenciesMetadata([{{#needs_configuration_service}}
        ConfigurationModule,{{/needs_configuration_service}}
        //TODO fill this list with module dependencies
      ]);
{{/is_dependent_module}}
{{#has_routes}}  @override
  List<ModuleRoute> configureRoutes() => [
        //TODO fill this list with module routes
      ];{{/has_routes}}

  @override
  Future<void> init({{#is_dependent_module}}ModulesApiProvider container{{/is_dependent_module}}{{^is_dependent_module}}void container{{/is_dependent_module}}) async {
    //TODO initialize module's services here{{#needs_configuration_service}}
    final configurationModuleApi = container.get<ConfigurationModuleApi>();
{{/needs_configuration_service}}{{#has_repository}}    final repository = {{name.pascalCase()}}Repository();{{/has_repository}}{{#has_services}}
    final service = {{name.pascalCase()}}Service();{{/has_services}}{{#needs_configuration_service}}
    final configurationService = {{name.pascalCase()}}ConfigurationService(
      configurationManager: configurationModuleApi.configurationManager,
    );{{/needs_configuration_service}}{{#has_module_output}}

    registerModuleOutput(ModuleOutput(
{{#has_module_api}}      moduleApi: {{name.pascalCase()}}ModuleApi(),{{/has_module_api}}
{{#has_routes}}      blocFactories: [],{{/has_routes}}
    ));{{/has_module_output}}
  }

  @override
  int get level => {{level}};

  @override
  bool get continueOnException => {{continue_on_exception}};

  @override
  bool get allowReinit => {{allow_reinit}};
}
