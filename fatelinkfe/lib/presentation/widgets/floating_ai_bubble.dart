import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:math' as math;
import 'package:fatelinkfe/core/responsive/responsive.dart';

/// Custom PanGestureRecognizer giúp phản hồi thao tác kéo tức thì mà không bị "khựng" (stutter/slop delay).
/// Mặc định của Flutter [PanGestureRecognizer] yêu cầu ngón tay di chuyển ít nhất 18px (kTouchSlop)
/// mới bắt đầu nhận cử chỉ, dẫn tới việc ngón tay di chuyển một đoạn rồi bong bóng mới giật/nhảy
/// theo một cách đột ngột. Bằng cách override [hasSufficientGlobalDistanceToAccept], chỉ cần
/// di chuyển > 3px là nhận diện ngay, giúp trải nghiệm kéo 1:1 siêu mượt mà.
class QuickPanGestureRecognizer extends PanGestureRecognizer {
  QuickPanGestureRecognizer({super.debugOwner});

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    return globalDistanceMoved > 3.0;
  }
}

class FloatingAiBubble extends StatefulWidget {
  final VoidCallback onTap;
  final bool hasNotification;

  const FloatingAiBubble({
    super.key,
    required this.onTap,
    this.hasNotification = false,
  });

  @override
  State<FloatingAiBubble> createState() => _FloatingAiBubbleState();
}

class _FloatingAiBubbleState extends State<FloatingAiBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _showSpeechBubble = false;

  // Sử dụng AnimationController không giới hạn (unbounded) để mô phỏng vật lý 2D độc lập
  late AnimationController _xController;
  late AnimationController _yController;

  // Trạng thái vị trí và tương tác
  bool _isPressed = false; // Đang giữ ngón tay vào bubble
  bool _isDragging = false; // Đang thực sự kéo di chuyển
  bool _isHoveringX = false; // Đang đè lên nút X
  bool _isVisible = true; // Ẩn/hiện bong bóng
  bool _isInitialized = false;
  double _left = 0.0;
  double _top = 0.0;

  // Lưu vị trí gốc khi bắt đầu kéo để tracking chuẩn tuyệt đối 1:1
  double _dragStartLeft = 0.0;
  double _dragStartTop = 0.0;
  Offset _dragStartGlobal = Offset.zero;
  Offset _currentDelta = Offset.zero; // Lưu delta để tính hiệu ứng biến dạng (Squash & Stretch)

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );

    // Khởi tạo Controller Vật lý
    _xController = AnimationController.unbounded(vsync: this);
    _yController = AnimationController.unbounded(vsync: this);

    _xController.addListener(() {
      if (!_isDragging && mounted) {
        setState(() => _left = _xController.value);
      }
    });

    _yController.addListener(() {
      if (!_isDragging && mounted) {
        setState(() => _top = _yController.value);
      }
    });

    // Thi thoảng hiển thị bong bóng chat
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showSpeechBubble = true);
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted) setState(() => _showSpeechBubble = false);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadPosition();
    } else {
      // Tự động re-clamp nếu xoay màn hình (orientation change) hoặc đổi kích thước cửa sổ
      final size = context.screenSize;
      final safeTop = context.safeTop;
      final safeBottom = context.safeBottom;
      final maxLeft = (size.width - 50.0 - 16.0).clamp(16.0, double.infinity);
      final maxTop = (size.height - 180.0 - safeBottom).clamp(safeTop + 16.0, double.infinity);
      _left = _left.clamp(16.0, maxLeft);
      _top = _top.clamp(safeTop + 16.0, maxTop);
      _xController.value = _left;
      _yController.value = _top;
    }
  }

  @override
  void didUpdateWidget(FloatingAiBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasNotification && !oldWidget.hasNotification) {
      setState(() => _isVisible = true);
    }
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLeft = prefs.getDouble('bubble_left');
    final savedTop = prefs.getDouble('bubble_top');

    if (mounted) {
      setState(() {
        final size = context.screenSize;
        final safeTop = context.safeTop;
        final safeBottom = context.safeBottom;
        final maxLeft = (size.width - 50.0 - 16.0).clamp(16.0, double.infinity);
        final maxTop = (size.height - 180.0 - safeBottom).clamp(safeTop + 16.0, double.infinity);
        if (savedLeft != null && savedTop != null) {
          _left = savedLeft.clamp(16.0, maxLeft);
          _top = savedTop.clamp(safeTop + 16.0, maxTop);
        } else {
          // Vị trí mặc định: mép phải, trên thanh BottomNav
          _left = maxLeft;
          _top = maxTop;
        }
        // Đồng bộ vị trí ban đầu vào Controller
        _xController.value = _left;
        _yController.value = _top;
        _isInitialized = true;
      });
    }
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bubble_left', _left);
    await prefs.setDouble('bubble_top', _top);
  }

  @override
  void dispose() {
    _controller.dispose();
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || !_isInitialized) return const SizedBox.shrink();

    final screenSize = MediaQuery.of(context).size;
    final isLeftAligned = _left < screenSize.width / 2;

    // Tính toán hiệu ứng bóp méo (Squash & Stretch) mượt mà dựa trên gia tốc
    double scaleX = 1.0;
    double scaleY = 1.0;

    if (_isDragging) {
      scaleX = 1.0 +
          (_currentDelta.dx.abs() / 45).clamp(0.0, 0.12) -
          (_currentDelta.dy.abs() / 55).clamp(0.0, 0.08);
      scaleY = 1.0 +
          (_currentDelta.dy.abs() / 45).clamp(0.0, 0.12) -
          (_currentDelta.dx.abs() / 55).clamp(0.0, 0.08);
    } else if (_xController.isAnimating || _yController.isAnimating) {
      scaleX = 1.0 +
          (_xController.velocity.abs() / 2500).clamp(0.0, 0.12) -
          (_yController.velocity.abs() / 3500).clamp(0.0, 0.08);
      scaleY = 1.0 +
          (_yController.velocity.abs() / 2500).clamp(0.0, 0.12) -
          (_xController.velocity.abs() / 3500).clamp(0.0, 0.08);
    }

    if (_isHoveringX) {
      scaleX *= 0.6; // Thu nhỏ mạnh khi bị hút vào nút X
      scaleY *= 0.6;
    }

    return Positioned.fill(
      child: Stack(
        children: [
          // Khu vực Nút "X" (Close Target) - Giữ sẵn trong Tree với AnimatedOpacity & AnimatedScale
          // để tránh giật khung hình (frame drop) khi bắt đầu kéo
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: IgnorePointer(
              ignoring: !_isDragging,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                opacity: _isDragging ? 1.0 : 0.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  scale: _isDragging ? (_isHoveringX ? 1.25 : 1.0) : 0.5,
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isHoveringX
                            ? Colors.redAccent
                            : Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _isHoveringX
                                ? Colors.redAccent.withValues(alpha: 0.6)
                                : Colors.black.withValues(alpha: 0.25),
                            blurRadius: _isHoveringX ? 20 : 10,
                            spreadRadius: _isHoveringX ? 4 : 0,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Cụm Bong bóng AI
          Positioned(
            left: _left,
            top: _top,
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                // Recognizer phản hồi kéo siêu nhạy (chỉ cần > 3px di chuyển)
                QuickPanGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<QuickPanGestureRecognizer>(
                  () => QuickPanGestureRecognizer(),
                  (QuickPanGestureRecognizer instance) {
                    instance
                      ..onDown = (details) {
                        // Vừa chạm ngón tay vào bubble:
                        _xController.stop();
                        _yController.stop();
                        _controller.stop(); // Tạm dừng breathing để bubble cố định ổn định
                        _currentDelta = Offset.zero;
                        HapticFeedback.selectionClick(); // Phản hồi xúc giác tức thì khi chạm
                        setState(() {
                          _isPressed = true;
                          _showSpeechBubble = false;
                        });
                      }
                      ..onStart = (details) {
                        // Nhận diện kéo thành công mà không có độ trễ slop
                        setState(() {
                          _isDragging = true;
                          _isPressed = false;
                          _isHoveringX = false;
                          _dragStartLeft = _left;
                          _dragStartTop = _top;
                          _dragStartGlobal = details.globalPosition;
                          _currentDelta = Offset.zero;
                        });
                      }
                      ..onUpdate = (details) {
                        setState(() {
                          // Làm mượt delta để biến dạng tự nhiên, không bị giật
                          _currentDelta = Offset.lerp(
                                _currentDelta,
                                details.delta,
                                0.35,
                              ) ??
                              details.delta;

                          // Tọa độ ngón tay thô tracking 1:1 mượt mà
                          double rawLeft = _dragStartLeft +
                              (details.globalPosition.dx - _dragStartGlobal.dx);
                          double rawTop = _dragStartTop +
                              (details.globalPosition.dy - _dragStartGlobal.dy);

                          // Tính toán khoảng cách từ bong bóng đến nút X
                          final xButtonCenter = Offset(
                            screenSize.width / 2,
                            screenSize.height - 85,
                          );
                          final bubbleCenter = Offset(rawLeft + 25, rawTop + 25);
                          final distance = (bubbleCenter - xButtonCenter).distance;

                          // HIỆU ỨNG NAM CHÂM (Magnetic Pull)
                          if (distance < 80) {
                            if (!_isHoveringX) {
                              HapticFeedback.mediumImpact(); // Rung khi rơi vào vùng nút X
                            }
                            _isHoveringX = true;
                            double pull = (1.0 - (distance / 80)).clamp(0.0, 1.0);
                            pull = Curves.easeOutCubic.transform(pull);

                            _left = rawLeft +
                                ((xButtonCenter.dx - 25) - rawLeft) * pull;
                            _top = rawTop +
                                ((xButtonCenter.dy - 25) - rawTop) * pull;
                          } else {
                            if (_isHoveringX) {
                              HapticFeedback.selectionClick(); // Rung khi thoát khỏi vùng nút X
                            }
                            _isHoveringX = false;
                            _left = rawLeft.clamp(0.0, screenSize.width - 50.0);
                            _top = rawTop.clamp(0.0, screenSize.height - 100.0);
                          }
                          _xController.value = _left;
                          _yController.value = _top;
                        });
                      }
                      ..onEnd = (details) {
                        _currentDelta = Offset.zero;
                        setState(() {
                          _isDragging = false;
                          _isPressed = false;

                          if (_isHoveringX) {
                            // Thả vào nút X -> Đóng bong bóng
                            _isVisible = false;
                            HapticFeedback.heavyImpact();
                          } else {
                            // Snap (Hít) về mép màn hình trái hoặc phải
                            final safeTop = context.safeTop;
                            final safeBottom = context.safeBottom;
                            final maxLeft = (screenSize.width - 50.0 - 16.0).clamp(16.0, double.infinity);
                            final maxTop = (screenSize.height - 180.0 - safeBottom).clamp(safeTop + 16.0, double.infinity);

                            double targetLeft = _left < screenSize.width / 2
                                ? 16.0
                                : maxLeft;
                            double targetTop = _top.clamp(
                              safeTop + 16.0,
                              maxTop,
                            );

                            final velocity = details.velocity.pixelsPerSecond;

                            const spring = SpringDescription(
                              mass: 1,
                              stiffness: 260,
                              damping: 22,
                            );
                            final xSim = SpringSimulation(
                              spring,
                              _left,
                              targetLeft,
                              velocity.dx,
                            );
                            final ySim = SpringSimulation(
                              spring,
                              _top,
                              targetTop,
                              velocity.dy,
                            );

                            _xController.animateWith(xSim);
                            _yController.animateWith(ySim).then((_) {
                              _savePosition();
                              if (mounted) {
                                _controller.repeat(reverse: true); // Tiếp tục thở nhẹ nhàng
                              }
                            });
                          }
                          _isHoveringX = false;
                        });
                      }
                      ..onCancel = () {
                        setState(() {
                          _isPressed = false;
                          _isDragging = false;
                          _isHoveringX = false;
                        });
                        _controller.repeat(reverse: true);
                      };
                  },
                ),
                // Recognizer xử lý chạm Tap thông thường
                TapGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                  () => TapGestureRecognizer(),
                  (TapGestureRecognizer instance) {
                    instance.onTap = () {
                      setState(() {
                        _isPressed = false;
                      });
                      _controller.repeat(reverse: true);
                      widget.onTap();
                    };
                  },
                ),
              },
              child: RepaintBoundary(
                child: Transform(
                  transform: Matrix4.diagonal3Values(
                    scaleX * (_isPressed ? 1.08 : 1.0),
                    scaleY * (_isPressed ? 1.08 : 1.0),
                    1.0,
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Bong bóng text thoại
                      if (_showSpeechBubble && !_isDragging && !_isPressed)
                        Positioned(
                          left: isLeftAligned ? 56 : null,
                          right: isLeftAligned ? null : 56,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: math.min(screenSize.width * 0.55, 220.0),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'NGÀY HÔM NAY CỦA BẠN THẾ NÀO?',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),

                      // Avatar AI (Breathing effect khi nhàn rỗi)
                      ScaleTransition(
                        scale: _isPressed ? const AlwaysStoppedAnimation(1.0) : _scaleAnimation,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isPressed
                                  ? const Color(0xFF00C6FF)
                                  : const Color(0xFF0066FF),
                              width: _isPressed ? 2.5 : 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0066FF).withValues(
                                  alpha: _isPressed ? 0.5 : 0.25,
                                ),
                                blurRadius: _isPressed ? 14 : 8,
                                spreadRadius: _isPressed ? 2 : 0,
                              ),
                            ],
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/avt_faye_ai.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // Chấm đỏ thông báo
                      if (widget.hasNotification)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '1',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
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
