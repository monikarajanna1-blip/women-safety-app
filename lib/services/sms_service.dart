import 'package:telephony/telephony.dart';

class SmsService {
  static final Telephony telephony = Telephony.instance;

  static Future<void> sendSMS(String number, String message) async {
    try {
      await telephony.sendSms(
        to: number,
        message: message,
      );
    } catch (e) {
      print("SMS sending error: $e");
    }
  }

  static Future<void> sendSmsToGuardians(List<String> numbers, String msg) async {
    for (String num in numbers) {
      await sendSMS(num, msg);
    }
  }
}


