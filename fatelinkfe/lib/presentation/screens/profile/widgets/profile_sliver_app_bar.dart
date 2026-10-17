import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../logic/blocs/main/main_bloc.dart';
import '../../../../logic/blocs/main/main_event.dart';
import '../../../widgets/back.dart';

class ProfileSliverAppBar extends StatelessWidget {
  final VoidCallback? onMenuTap;

  const ProfileSliverAppBar({
    super.key,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFF1F5F9)),
      ),
      centerTitle: true,
      title: Text(
        'MyProfile'.tr(),
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          color: Color(0xFF0F172A),
          fontWeight: FontWeight.w800,
          fontSize: 18,
          letterSpacing: -0.2,
        ),
      ),
      leading: Center(
        child: CustomBackButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.read<MainBloc>().add(PopTabEvent());
            }
          },
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Center(
            child: IconButton(
              onPressed: () => onMenuTap?.call(),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: const EdgeInsets.all(8),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF1E293B),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
