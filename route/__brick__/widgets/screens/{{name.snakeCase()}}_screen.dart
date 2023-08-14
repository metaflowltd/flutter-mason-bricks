import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:{{{fullPath}}}/blocs/{{name.snakeCase()}}_bloc.dart';
import 'package:{{{fullPath}}}/widgets/ui_widgets/{{name.snakeCase()}}_ui_widget.dart';

class {{name.pascalCase()}}Screen extends StatelessWidget {
  const {{name.pascalCase()}}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<{{name.pascalCase()}}Bloc, {{name.pascalCase()}}State>(
      builder: (context, state) {
        return const {{name.pascalCase()}}UiWidget();
      },
    );
  }
}
