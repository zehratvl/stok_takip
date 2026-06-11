import 'dart:js' as js;

class EmailService {
  static const String _serviceId = 'service_5wmquoe';
  static const String _templateId = 'template_qwhcjvn';

  static Future<bool> kritikStokBildirimi({
    required String urunIsim,
    required int stokMiktari,
    required int kritikSeviye,
  }) async {
    try {
      final templateParams = js.JsObject.jsify({
        'urun_isim': urunIsim,
        'stok_miktari': stokMiktari.toString(),
        'kritik_seviye': kritikSeviye.toString(),
        'name': 'stOK Panel',
        'email': 'acerisa453@gmail.com',
      });

      final emailjs = js.context['emailjs'];
      emailjs.callMethod('send', [
        _serviceId,
        _templateId,
        templateParams,
      ]);

      print('Email gönderildi: $urunIsim');
      return true;
    } catch (e) {
      print('EmailJS hata: $e');
      return false;
    }
  }
}