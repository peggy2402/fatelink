import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fatelinkfe/core/services/network_connectivity_service.dart';

/// Widget bao bọc toàn ứng dụng để hiển thị Banner thông báo trạng thái mạng
class NetworkStatusBanner extends StatefulWidget {
  final Widget child;

  const NetworkStatusBanner({super.key, required this.child});

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

class _NetworkStatusBannerState extends State<NetworkStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  bool _isOnline = true;
  bool _showBanner = false;
  bool _wasOffline = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _isOnline = NetworkConnectivityService.instance.isOnline;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    // Lắng nghe trạng thái mạng từ service
    NetworkConnectivityService.instance.isOnlineNotifier.addListener(_onNetworkChange);

    // Nếu khi mở app đã bị mất mạng, lập tức báo động
    if (!_isOnline) {
      _showBanner = true;
      _wasOffline = true;
      _animController.forward();
    }
  }

  void _onNetworkChange() {
    final bool newStatus = NetworkConnectivityService.instance.isOnline;
    if (_isOnline == newStatus) return;

    _hideTimer?.cancel();

    if (!newStatus) {
      // Mất mạng
      setState(() {
        _isOnline = false;
        _showBanner = true;
        _wasOffline = true;
      });
      _animController.forward();
    } else {
      // Có mạng trở lại
      setState(() {
        _isOnline = true;
      });

      if (_wasOffline) {
        // Đổi màu sang xanh thông báo "Đã có mạng trở lại" rồi ẩn đi sau 2.5s
        _hideTimer = Timer(const Duration(milliseconds: 2500), () {
          if (mounted) {
            _animController.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showBanner = false;
                  _wasOffline = false;
                });
              }
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    NetworkConnectivityService.instance.isOnlineNotifier.removeListener(_onNetworkChange);
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: topPadding + 6,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isOnline
                            ? const [Color(0xFF059669), Color(0xFF10B981)]
                            : const [Color(0xFFDC2626), Color(0xFFEF4444)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_isOnline ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isOnline
                                ? 'Đã có kết nối mạng trở lại'
                                : 'Đã ngắt kết nối mạng. Vui lòng kiểm tra lại.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
