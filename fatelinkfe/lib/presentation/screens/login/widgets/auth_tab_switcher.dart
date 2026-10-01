import 'package:flutter/material.dart';

class AuthTabSwitcher extends StatelessWidget {
  final bool isLogin;
  final ValueChanged<bool> onTabChanged;

  const AuthTabSwitcher({
    super.key,
    required this.isLogin,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tab 1: Đăng nhập
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isLogin
                      ? const LinearGradient(
                          colors: [Color(0xFFF43F5E), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isLogin ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: isLogin
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_open_rounded,
                        size: 16,
                        color: isLogin ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Đăng nhập',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isLogin ? FontWeight.w800 : FontWeight.w600,
                            color: isLogin ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tab 2: Tạo tài khoản
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  gradient: !isLogin
                      ? const LinearGradient(
                          colors: [Color(0xFFF43F5E), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: !isLogin ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: !isLogin
                      ? [
                          BoxShadow(
                            color: const Color(0xFFF43F5E).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        size: 16,
                        color: !isLogin ? Colors.white : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Tạo tài khoản',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: !isLogin ? FontWeight.w800 : FontWeight.w600,
                            color: !isLogin ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
