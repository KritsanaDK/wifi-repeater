import 'package:flutter/services.dart';

String friendlyWifiError(Object error) {
  if (error is MissingPluginException) {
    return 'ฟีเจอร์นี้ใช้งานได้บน Android เท่านั้น';
  }
  if (error is PlatformException) {
    switch (error.code) {
      case 'unsupported':
        return 'อุปกรณ์นี้ไม่รองรับการตั้งค่าที่ต้องการ';
      case 'activity_not_found':
      case 'settings_unavailable':
        return 'ไม่พบหน้าการตั้งค่านี้ในอุปกรณ์';
      case 'permission_denied':
        return 'ยังไม่ได้รับสิทธิ์สำหรับดูชื่อ Wi-Fi';
    }
  }
  return 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';
}
