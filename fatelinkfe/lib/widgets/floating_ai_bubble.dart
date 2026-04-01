import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/physics.dart'; // Thư viện vật lý của Flutter

class FloatingAiBubble extends StatefulWidget {
  final VoidCallback onTap;
  final bool hasNotification; // Thêm trạng thái notification

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
  bool _isDragging = false;
  bool _isHoveringX = false; // Đang đè lên nút X
  bool _isVisible = true; // Ẩn/hiện bong bóng
  bool _isInitialized = false;
  double _left = 0.0;
  double _top = 0.0;

  // Lưu vị trí gốc khi bắt đầu kéo để tracking chuẩn tuyệt đối 1:1
  double _dragStartLeft = 0.0;
  double _dragStartTop = 0.0;
  Offset _dragStartGlobal = Offset.zero;
  Offset _currentDelta =
      Offset.zero; // Lưu delta để tính hiệu ứng biến dạng (Squash & Stretch)

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
    }
  }

  @override
  void didUpdateWidget(FloatingAiBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu có thông báo mới (hasNotification = true) thì tự động hiện lại bong bóng nếu nó đang bị đóng
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
        final size = MediaQuery.of(context).size;
        if (savedLeft != null && savedTop != null) {
          _left = savedLeft;
          _top = savedTop;
        } else {
          // Vị trí mặc định: mép phải, trên thanh BottomNav
          _left = size.width - 50.0 - 16.0;
          _top = size.height - 180.0;
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

    // Lấy kích thước màn hình để giới hạn khu vực kéo thả
    final screenSize = MediaQuery.of(context).size;

    // Kiểm tra xem bong bóng đang ở nửa trái hay nửa phải màn hình
    final isLeftAligned = _left < screenSize.width / 2;

    // Tính toán hiệu ứng bóp méo (Squash & Stretch) dựa trên gia tốc
    double scaleX = 1.0;
    double scaleY = 1.0;

    if (_isDragging) {
      scaleX =
          1.0 +
          (_currentDelta.dx.abs() / 40).clamp(0.0, 0.15) -
          (_currentDelta.dy.abs() / 50).clamp(0.0, 0.1);
      scaleY =
          1.0 +
          (_currentDelta.dy.abs() / 40).clamp(0.0, 0.15) -
          (_currentDelta.dx.abs() / 50).clamp(0.0, 0.1);
    } else if (_xController.isAnimating || _yController.isAnimating) {
      scaleX =
          1.0 +
          (_xController.velocity.abs() / 2000).clamp(0.0, 0.15) -
          (_yController.velocity.abs() / 3000).clamp(0.0, 0.1);
      scaleY =
          1.0 +
          (_yController.velocity.abs() / 2000).clamp(0.0, 0.15) -
          (_xController.velocity.abs() / 3000).clamp(0.0, 0.1);
    }

    if (_isHoveringX) {
      scaleX *= 0.6; // Thu nhỏ mạnh khi bị hút vào nút X
      scaleY *= 0.6;
    }

    // Sử dụng Positioned.fill bọc ngoài để có không gian vẽ nút "X" ở dưới cùng
    return Positioned.fill(
      child: Stack(
        children: [
          // Khu vực Nút "X" (Close Target)
          if (_isDragging)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: _isHoveringX ? 70 : 50,
                  height: _isHoveringX ? 70 : 50,
                  decoration: BoxDecoration(
                    color: _isHoveringX ? Colors.red : Colors.black54,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (_isHoveringX)
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                    ],
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ),

          // Cụm Bong bóng AI
          Positioned(
            left: _left,
            top: _top,
            child: GestureDetector(
              behavior:
                  HitTestBehavior.opaque, // Đảm bảo luôn bắt được vùng chạm
              onTap: widget.onTap,
              onPanDown: (details) {
                // Ghi nhận tọa độ TỨC THÌ khi vừa chạm ngón tay (bỏ qua độ trễ nhận diện vuốt/chạm của Flutter)
                _xController.stop();
                _yController.stop();
                _dragStartLeft = _left;
                _dragStartTop = _top;
                _dragStartGlobal = details.globalPosition;
                _currentDelta = Offset.zero;
              },
              onPanStart: (details) {
                setState(() {
                  _isDragging = true;
                  _isHoveringX = false;
                  _showSpeechBubble =
                      false; // Tạm ẩn bong bóng text khi đang kéo
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _currentDelta = details.delta;

                  // Tọa độ ngón tay thô
                  double rawLeft =
                      _dragStartLeft +
                      (details.globalPosition.dx - _dragStartGlobal.dx);
                  double rawTop =
                      _dragStartTop +
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
                    // Bán kính từ trường 80px
                    _isHoveringX = true;
                    // Càng gần X lực hút càng mạnh (từ 0.0 -> 1.0)
                    double pull = (1.0 - (distance / 80)).clamp(0.0, 1.0);
                    pull = Curves.easeOutCubic.transform(
                      pull,
                    ); // Cảm giác hút mượt hơn

                    _left =
                        rawLeft + ((xButtonCenter.dx - 25) - rawLeft) * pull;
                    _top = rawTop + ((xButtonCenter.dy - 25) - rawTop) * pull;
                  } else {
                    _isHoveringX = false;
                    _left = rawLeft.clamp(0.0, screenSize.width - 50.0);
                    _top = rawTop.clamp(0.0, screenSize.height - 100.0);
                  }
                  _xController.value = _left;
                  _yController.value = _top;
                });
              },
              onPanEnd: (details) {
                _currentDelta = Offset.zero;
                setState(() {
                  _isDragging = false;
                  if (_isHoveringX) {
                    // Nếu thả vào nút X -> Đóng bong bóng
                    _isVisible = false;
                  } else {
                    // Snap (Hít) về 2 mép màn hình
                    double targetLeft = _left < screenSize.width / 2
                        ? 16.0
                        : screenSize.width - 50.0 - 16.0;
                    // Đảm bảo không đè lên Header hoặc BottomNavBar
                    double targetTop = _top.clamp(
                      60.0,
                      screenSize.height - 180.0,
                    );

                    final velocity = details.velocity.pixelsPerSecond;

                    // MÔ PHỎNG VẬT LÝ LÒ XO (Spring Simulation)
                    // mass (khối lượng), stiffness (độ cứng lò xo), damping (lực cản)
                    const spring = SpringDescription(
                      mass: 1,
                      stiffness: 250,
                      damping: 20,
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

                    // Truyền động lượng (velocity) vào để bong bóng trượt theo đà trước khi bị hút về mép
                    _xController.animateWith(xSim);
                    _yController.animateWith(ySim).then((_) => _savePosition());
                  }
                  _isHoveringX = false;
                });
              },
              // Tối ưu hóa render bằng RepaintBoundary
              child: RepaintBoundary(
                child: Transform(
                  transform: Matrix4.identity()..scale(scaleX, scaleY),
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Bong bóng text thoại
                      if (_showSpeechBubble && !_isDragging)
                        Positioned(
                          // Tự động đảo chiều bong bóng text để không bị lẹm viền màn hình
                          left: isLeftAligned ? 56 : null,
                          right: isLeftAligned ? null : 56,
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
                                  color: Colors.black.withOpacity(0.2),
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
                            ),
                          ),
                        ),

                      // Avatar AI (Breathing effect)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0066FF),
                              width: 2,
                            ),
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
          ), // Đóng Positioned của Cụm Bong bóng AI
        ],
      ),
    );
  }
}
