import 'package:auto_generate_storybook/stories.dart';
import 'package:flutter/material.dart';
import 'package:storybook_flutter/storybook_flutter.dart';

void main() {
  runApp(const StorybookApp());
}

class StorybookApp extends StatelessWidget {
  const StorybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final device = DeviceInfo.genericPhone(
      platform: TargetPlatform.iOS,
      id: "id",
      name: "IPhone",
      screenSize: const Size(428, 926),
    );

    return Storybook(
      plugins: [
        DeviceFramePlugin(
          initialData: (
            device: device,
            orientation: Orientation.portrait,
            isFrameVisible: true,
          ),
        ),
      ],
      stories: stories,
    );
  }
}
