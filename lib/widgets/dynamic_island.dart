import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DynamicIsland {
  static OverlayEntry? _overlay;

  static void show(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color color = Colors.cyan,
    Duration duration = const Duration(seconds: 2),
  }) {
    _overlay?.remove();

    HapticFeedback.mediumImpact();

    _overlay = OverlayEntry(
      builder: (context) =>
          _DynamicIslandWidget(icon: icon, title: title, color: color),
    );

    Overlay.of(context).insert(_overlay!);

    Future.delayed(duration, () {
      _overlay?.remove();
      _overlay = null;
    });
  }
}

class _DynamicIslandWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _DynamicIslandWidget({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  State<_DynamicIslandWidget> createState() => _DynamicIslandWidgetState();
}

class _DynamicIslandWidgetState extends State<_DynamicIslandWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<Offset> offset;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    offset = Tween(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: offset,
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(.95),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: widget.color.withOpacity(.6)),
              boxShadow: [
                BoxShadow(color: widget.color.withOpacity(.35), blurRadius: 25),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.color),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
