import 'package:momento_booth/models/photo_template.dart';
import 'package:momento_booth/views/base/screen_controller_base.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/template_screen/template_screen_view_model.dart';

class TemplateScreenController
    extends ScreenControllerBase<TemplateScreenViewModel> {
  TemplateScreenController({
    required super.viewModel,
    required super.contextAccessor,
  });

  void onBack() {
    router.pop();
  }

  void onSelectTemplate(PhotoTemplate template) {
    viewModel.selectTemplate(template);
  }

  void onHoverTemplate(int? index) {
    viewModel.setHoveredIndex(index);
  }

  Future<void> onCreateTemplate() async {
    await viewModel.createTemplate();
  }
}