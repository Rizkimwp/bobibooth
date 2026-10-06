import 'package:fluent_ui/fluent_ui.dart';
import 'package:mobx/mobx.dart';
import 'package:momento_booth/main.dart';
import 'package:momento_booth/managers/project_manager.dart';
import 'package:momento_booth/models/photo_template.dart';
import 'package:momento_booth/views/base/screen_view_model_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/template_screen/create_template_dialog.dart';

part 'template_screen_view_model.g.dart';

class TemplateScreenViewModel = TemplateScreenViewModelBase
    with _$TemplateScreenViewModel;

abstract class TemplateScreenViewModelBase extends ScreenViewModelBase
    with Store {
  TemplateScreenViewModelBase({
    required super.contextAccessor,
  });

  ProjectManager get projectManager => getIt<ProjectManager>();

  List<PhotoTemplate> get templates => projectManager.customTemplates;

  PhotoTemplate? get selectedTemplate =>
      projectManager.selectedCustomTemplate;

  bool isSelected(PhotoTemplate template) {
    return selectedTemplate?.id == template.id;
  }

  @observable
  int? hoveredIndex;

  @action
  void setHoveredIndex(int? index) {
    hoveredIndex = index;
  }

  @action
  void selectTemplate(PhotoTemplate template) {
    projectManager.selectCustomTemplate(template);
  }

  Future<void> createTemplate() async {
  await showDialog<bool>(
    context: contextAccessor.buildContext,
    builder: (_) => const CreateTemplateDialog(),
  );
}
}