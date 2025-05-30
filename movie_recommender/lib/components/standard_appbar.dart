import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool showDefaultIcon;
  final bool center;

  const StandardAppBar({
    super.key,
    this.title,
    this.actions,
    this.showDefaultIcon = true,
    this.center = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title:
          title ??
          (showDefaultIcon
              ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.movie_filter),
                  SizedBox(width: 8),
                  Text(
                    dotenv.env['APP_NAME']!,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )
              : null),
      actions: [
        IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              Navigator.pushReplacementNamed(context, '/search');
            },
          ),
          ...?actions,
        ],
      centerTitle: center,
      backgroundColor: Colors.grey[900],
    );
  }
}
