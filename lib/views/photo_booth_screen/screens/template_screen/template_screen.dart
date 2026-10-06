import 'package:momento_booth/views/base/build_context_accessor.dart';
import 'package:momento_booth/views/base/screen_base.dart';

import 'package:momento_booth/views/photo_booth_screen/screens/template_screen/template_screen_controller.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/template_screen/template_screen_view.dart';
import 'package:momento_booth/views/photo_booth_screen/screens/template_screen/template_screen_view_model.dart';

class TemplateScreen
    extends
        ScreenBase<
          TemplateScreenViewModel,
          TemplateScreenController,
          TemplateScreenView
        > {
  static const String defaultRoute = "/templates";

  const TemplateScreen({super.key});

  @override
  TemplateScreenController createController({
    required TemplateScreenViewModel viewModel,
    required BuildContextAccessor contextAccessor,
  }) {
    return TemplateScreenController(
      viewModel: viewModel,
      contextAccessor: contextAccessor,
    );
  }

  @override
  TemplateScreenView createView({
    required TemplateScreenController controller,
    required TemplateScreenViewModel viewModel,
    required BuildContextAccessor contextAccessor,
  }) {
    return TemplateScreenView(
      contextAccessor: contextAccessor,
      controller: controller,
      viewModel: viewModel,
    );
  }

  @override
  TemplateScreenViewModel createViewModel({
    required BuildContextAccessor contextAccessor,
  }) {
    return TemplateScreenViewModel(contextAccessor: contextAccessor);
  }
}
