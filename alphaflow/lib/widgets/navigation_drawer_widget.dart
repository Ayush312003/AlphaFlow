import 'package:flutter/material.dart';
import 'package:alphaflow/common/widgets/alphaflow_drawer.dart';

/// Navigation drawer widget that uses the premium AlphaFlow drawer
class NavigationDrawerWidget extends StatelessWidget {
  const NavigationDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: const AlphaFlowDrawer(),
    );
  }
}
