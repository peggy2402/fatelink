import 'package:flutter/material.dart';
import '../../../../core/services/image_picker_service.dart';

class ProfileSoulIdCard extends StatelessWidget {
  final String name;
  final String avatar;
  final String soulId;
  final String mood;
  final String moodIcon;
  final String frequency;
  final String bio;
  final String handle;
  final String? address;
  final String? dob;
  final String? gender;

  const ProfileSoulIdCard({
    super.key,
    required this.name,
    required this.avatar,
    required this.soulId,
    required this.mood,
    required this.moodIcon,
    required this.frequency,
    required this.bio,
    required this.handle,
    this.address,
    this.dob,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final displayAddress = (address != null && address!.isNotEmpty)
        ? address!
        : 'Đang phát tín hiệu gần bạn';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar với viền phát sáng Gradient tròn tự nhiên & Mood Badge (Không vệt vuông mờ)
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF6366F1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.14),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image(
                        image: ImagePickerService.getImageProvider(avatar),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE0E7FF),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF6366F1),
                                size: 40,
                              ),
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        moodIcon,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Thông tin người dùng
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      handle,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Tần số cảm xúc Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.graphic_eq_rounded,
                            size: 14,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '$frequency • $mood',
                              style: const TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 12,
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), thickness: 1),
          const SizedBox(height: 12),

          // Bio
          Text(
            '"$bio"',
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              color: Color(0xFF475569),
              fontStyle: FontStyle.italic,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Vị trí / Ngày sinh / Giới tính
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  displayAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (dob != null && dob!.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.cake_outlined,
                  size: 15,
                  color: Color(0xFFEC4899),
                ),
                const SizedBox(width: 4),
                Text(
                  dob!,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (gender != null && gender!.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(
                  gender == 'female'
                      ? Icons.female_rounded
                      : (gender == 'male'
                            ? Icons.male_rounded
                            : Icons.all_inclusive_rounded),
                  size: 15,
                  color: gender == 'female'
                      ? const Color(0xFFEC4899)
                      : (gender == 'male'
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF8B5CF6)),
                ),
                const SizedBox(width: 4),
                Text(
                  gender == 'female'
                      ? 'Nữ'
                      : (gender == 'male' ? 'Nam' : 'Khác'),
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
