import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Widget nhập địa chỉ thông minh có gợi ý tự động (Autocomplete)
/// Tích hợp API Cas AddressKit (https://addresskit.cas.so)
/// và làm nổi bật (Highlight Vàng) các từ khóa khớp khi người dùng gõ.
class AddressAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final ValueChanged<String>? onAddressSelected;

  const AddressAutocompleteField({
    super.key,
    required this.controller,
    this.label = 'Địa chỉ / Khu vực sinh sống',
    this.hintText = 'VD: Hà Nội, Việt Nam...',
    this.onAddressSelected,
  });

  @override
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;

  List<String> _provinces = [];
  List<String> _filteredSuggestions = [];
  bool _isLoading = false;

  // Danh sách địa danh mặc định ban đầu nếu chưa tải xong API Cas AddressKit
  static const List<String> _fallbackLocations = [
    'Thành phố Hà Nội',
    'Thành phố Hồ Chí Minh',
    'Thành phố Đà Nẵng',
    'Thành phố Hải Phòng',
    'Thành phố Cần Thơ',
    'Thành phố Nha Trang, Khánh Hòa',
    'Thành phố Đà Lạt, Lâm Đồng',
    'Thành phố Huế, Thừa Thiên Huế',
    'Tỉnh Quảng Ninh',
    'Tỉnh Bình Dương',
    'Tỉnh Đồng Nai',
    'Tỉnh Bà Rịa - Vũng Tàu',
    'Tỉnh Bắc Ninh',
    'Tỉnh Thanh Hóa',
    'Tỉnh Nghệ An',
    'Tỉnh Kiên Giang',
    'Thành phố Buôn Ma Thuột, Đắk Lắk',
    'Thành phố Quy Nhơn, Bình Định',
    'Tỉnh Vĩnh Phúc',
    'Tỉnh Thái Nguyên',
    'Tỉnh Nam Định',
    'Tỉnh Hải Dương',
    'Tỉnh Tiền Giang',
    'Tỉnh An Giang',
  ];

  @override
  void initState() {
    super.initState();
    _fetchProvincesFromAddressKit();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _hideOverlay();
      } else if (widget.controller.text.trim().isNotEmpty) {
        _updateSuggestions(widget.controller.text.trim());
      }
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  /// Gọi API AddressKit từ Cas.so để lấy danh mục hành chính chuẩn
  Future<void> _fetchProvincesFromAddressKit() async {
    setState(() => _isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('https://production.cas.so/address-kit/latest/provinces'))
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['provinces'] as List<dynamic>?;
        if (list != null) {
          final fetched = list
              .map((e) => (e['name'] ?? '').toString())
              .where((name) => name.isNotEmpty)
              .toList();

          if (mounted) {
            setState(() {
              _provinces = fetched.isNotEmpty ? fetched : _fallbackLocations;
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (_) {
      // Fallback an toàn nếu offline hoặc timeout
    }

    if (mounted) {
      setState(() {
        _provinces = _fallbackLocations;
        _isLoading = false;
      });
    }
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    if (query.isEmpty) {
      _hideOverlay();
    } else {
      _updateSuggestions(query);
    }
  }

  String _removeDiacritics(String str) {
    const withDia = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const noDia   = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    var result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], noDia[i]);
    }
    return result;
  }

  void _updateSuggestions(String query) {
    final normalizedQuery = _removeDiacritics(query.toLowerCase());
    final pool = _provinces.isNotEmpty ? _provinces : _fallbackLocations;

    final results = pool.where((item) {
      final normalizedItem = _removeDiacritics(item.toLowerCase());
      return normalizedItem.contains(normalizedQuery);
    }).take(6).toList();

    setState(() {
      _filteredSuggestions = results;
    });

    if (results.isNotEmpty && _focusNode.hasFocus) {
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _showOverlay() {
    _hideOverlay();
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 40,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 54),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(18),
              color: Colors.white,
              shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 250),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header AddressKit tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          const Text(
                            'Gợi ý từ Cas AddressKit',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFF59E0B)),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _filteredSuggestions.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 40, color: Color(0xFFF8FAFC)),
                        itemBuilder: (context, index) {
                          final suggestion = _filteredSuggestions[index];
                          return InkWell(
                            onTap: () {
                              widget.controller.text = suggestion;
                              widget.onAddressSelected?.call(suggestion);
                              _hideOverlay();
                              _focusNode.unfocus();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF6366F1)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildHighlightedText(suggestion, widget.controller.text.trim()),
                                  ),
                                  const Icon(Icons.north_west_rounded, size: 14, color: Color(0xFFCBD5E1)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Phân tích và Highlight Màu Vàng đoạn văn bản khớp với từ khóa người dùng gõ
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 13.5,
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final normalizedText = _removeDiacritics(text.toLowerCase());
    final normalizedQuery = _removeDiacritics(query.toLowerCase());

    final startIndex = normalizedText.indexOf(normalizedQuery);
    if (startIndex == -1) {
      return Text(
        text,
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 13.5,
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final endIndex = startIndex + normalizedQuery.length;
    final before = text.substring(0, startIndex);
    final match = text.substring(startIndex, endIndex);
    final after = text.substring(endIndex);

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 13.5,
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
        ),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          // HIGHLIGHT VÀNG RỰC RỠ CHO CỤM TỪ KHỚP
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7), // Vàng pastel êm dịu
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1), // Vàng đậm
              ),
              child: Text(
                match,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB45309), // Chữ vàng nâu sắc nét
                ),
              ),
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF334155),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: Color(0xFFD97706), size: 11),
                        SizedBox(width: 3),
                        Text(
                          'AddressKit',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 15,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 20),
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                fontFamily: 'BeVietnamPro',
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
              ),
              suffixIcon: widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}
