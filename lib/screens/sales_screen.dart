import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/email_service.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _aramaController = TextEditingController();
  String _aramaMetni = '';
  bool _iadeMode = false;
  final List<Map<String, dynamic>> _sepet = [];

  double get _araToplam => _sepet.fold(0, (t, i) => t + (i['fiyat'] * i['miktar']));
  double get _kdv => _araToplam * 0.20;
  double get _toplam => _araToplam + _kdv;

  // ── Miktar popup ──────────────────────────────────────────────────────────
  Future<void> _sepeteEklePopup(Map<String, dynamic> urun, String urunId) async {
    final stok = (urun['stok'] ?? 0) as num;

    // Stok 0 → ekleme
    if (!_iadeMode && stok <= 0) return;

    final controller = TextEditingController(text: '1');

    final sonuc = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(child: Text(urun['isim'] ?? '', style: const TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_iadeMode)
              Text('Mevcut stok: $stok adet',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Miktar',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: 'adet',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final miktar = int.tryParse(controller.text) ?? 1;
              if (miktar <= 0) return;
              // Stok yeterliliği kontrolü (satış modunda)
              if (!_iadeMode && miktar > stok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Yetersiz stok! Maksimum $stok adet ekleyebilirsiniz.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, miktar);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _iadeMode ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sepete Ekle'),
          ),
        ],
      ),
    );

    if (sonuc != null && sonuc > 0) {
      setState(() {
        final index = _sepet.indexWhere((i) => i['id'] == urunId);
        if (index >= 0) {
          _sepet[index]['miktar'] += sonuc;
        } else {
          _sepet.add({
            'id': urunId,
            'isim': urun['isim'],
            'fiyat': (urun['fiyat'] ?? 0).toDouble(),
            'miktar': sonuc,
            'stok': stok,
          });
        }
      });
    }
  }

  void _miktarDegistir(int index, int delta) {
    setState(() {
      _sepet[index]['miktar'] += delta;
      if (_sepet[index]['miktar'] <= 0) _sepet.removeAt(index);
    });
  }

  // ── Ödeme / İade ──────────────────────────────────────────────────────────
  Future<void> _odemeAl() async {
    if (_sepet.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final tip = _iadeMode ? 'giris' : 'cikis';

    // Stok işlemleri
    for (final item in _sepet) {
      final urunRef = _firestore.collection('products').doc(item['id']);
     await _firestore.runTransaction((transaction) async {
  final snap = await transaction.get(urunRef);
  final snapData = snap.data() as Map<String, dynamic>?;
  final mevcutStok = (snapData?['stok'] ?? 0) as num;
  final kritikSeviye = (snapData?['kritikSeviye'] ?? 5) as num;
  final yeniStok = tip == 'cikis'
      ? mevcutStok - item['miktar']
      : mevcutStok + item['miktar'];
  transaction.update(urunRef, {'stok': yeniStok});

  if (tip == 'cikis' && yeniStok <= kritikSeviye) {
    EmailService.kritikStokBildirimi(
      urunIsim: item['isim'],
      stokMiktari: yeniStok.toInt(),
      kritikSeviye: kritikSeviye.toInt(),
    );
  }
});

    await _firestore.collection('stockMovements').add({
  'urunId': item['id'],
  'urunIsim': item['isim'],
  'tip': tip,
  'miktar': item['miktar'],
  'tutar': item['fiyat'] * item['miktar'],
  'not': _iadeMode ? 'İade' : 'Satış',
  'kullanici': user?.email,
  'tarih': FieldValue.serverTimestamp(),
});
    }

    // Fiş için sepeti kopyala
    final fisVerisi = List<Map<String, dynamic>>.from(_sepet);
    final fisToplam = _toplam;
    final fisAra = _araToplam;
    final fisKdv = _kdv;
    final fisMode = _iadeMode;

    setState(() => _sepet.clear());

    // Fiş dialog
    if (!mounted) return;
    _fisCikti(fisVerisi, fisAra, fisKdv, fisToplam, fisMode, user?.email ?? '');
  }

  // ── Fiş / Makbuz Dialog ───────────────────────────────────────────────────
  void _fisCikti(
    List<Map<String, dynamic>> items,
    double ara,
    double kdv,
    double toplam,
    bool iadeMode,
    String kullanici,
  ) {
    final simdi = DateTime.now();
    final tarihStr =
        '${simdi.day.toString().padLeft(2, '0')}.${simdi.month.toString().padLeft(2, '0')}.${simdi.year}  '
        '${simdi.hour.toString().padLeft(2, '0')}:${simdi.minute.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iadeMode ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iadeMode ? Icons.replay_rounded : Icons.check_rounded,
                  color: iadeMode ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                iadeMode ? 'İade Tamamlandı' : 'Satış Tamamlandı',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(tarihStr, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              const SizedBox(height: 4),
              Text(kullanici, style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1))),
              const SizedBox(height: 16),

              // Ürün listesi
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Başlık satırı
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: const [
                          Expanded(child: Text('Ürün', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)))),
                          SizedBox(width: 8),
                          Text('Adet', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
                          SizedBox(width: 16),
                          SizedBox(width: 70, child: Text('Tutar', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)))),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(item['isim'],
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              Text('x${item['miktar']}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  '₺${(item['fiyat'] * item['miktar']).toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Toplam kısım
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _fisSatir('Ara Toplam', '₺${ara.toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    _fisSatir('KDV (%20)', '₺${kdv.toStringAsFixed(2)}'),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOPLAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('₺${toplam.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: iadeMode ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iadeMode ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Kapat', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fisSatir(String label, String deger) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(deger, style: const TextStyle(fontSize: 13)),
        ],
      );

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Mod seçici
          Row(
            children: [
              _modButon('Satış Modu', Icons.shopping_cart_rounded, false),
              const SizedBox(width: 12),
              _modButon('İade Modu', Icons.replay_rounded, true),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol: Ürün grid
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      TextField(
                        controller: _aramaController,
                        onChanged: (v) => setState(() => _aramaMetni = v.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Ürün adı veya barkod yazın...',
                          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore.collection('products').snapshots(),
                          builder: (context, snapshot) {
                            var urunler = snapshot.data?.docs ?? [];
                            if (_aramaMetni.isNotEmpty) {
                              urunler = urunler.where((d) {
                                final data = d.data() as Map<String, dynamic>;
                                return (data['isim'] ?? '').toLowerCase().contains(_aramaMetni) ||
                                    (data['barkod'] ?? '').toLowerCase().contains(_aramaMetni);
                              }).toList();
                            }
                            return GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.3,
                              ),
                              itemCount: urunler.length,
                              itemBuilder: (context, index) {
                                final doc = urunler[index];
                                final data = doc.data() as Map<String, dynamic>;
                                final stok = (data['stok'] ?? 0) as num;
                                final stokBitti = !_iadeMode && stok <= 0;

                                return GestureDetector(
                                  onTap: () => _sepeteEklePopup(data, doc.id),
                                  child: Opacity(
                                    opacity: stokBitti ? 0.45 : 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: stokBitti
                                            ? const Color(0xFFF1F5F9)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: stokBitti
                                            ? Border.all(color: const Color(0xFFE2E8F0))
                                            : null,
                                        boxShadow: stokBitti
                                            ? null
                                            : [
                                                BoxShadow(
                                                    color: Colors.black.withOpacity(0.04),
                                                    blurRadius: 6)
                                              ],
                                      ),
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_rounded,
                                            color: stokBitti
                                                ? const Color(0xFFCBD5E1)
                                                : const Color(0xFF2563EB),
                                            size: 28,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            data['isim'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: stokBitti
                                                  ? const Color(0xFF94A3B8)
                                                  : const Color(0xFF1E293B),
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          if (stokBitti)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFEDED),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('Stok Yok',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFFDC2626),
                                                      fontWeight: FontWeight.w600)),
                                            )
                                          else
                                            Text(
                                              '₺${data['fiyat'] ?? 0}',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2563EB)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Sağ: Sepet
                SizedBox(
                  width: 300,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sepet Bilgisi',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B))),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _iadeMode
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _iadeMode ? 'İade' : 'Satış',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _sepet.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.shopping_basket_outlined,
                                          size: 48, color: Colors.grey.shade300),
                                      const SizedBox(height: 8),
                                      Text('Sepet henüz boş',
                                          style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 13)),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _sepet.length,
                                  itemBuilder: (context, index) {
                                    final item = _sepet[index];
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: const Color(0xFFE2E8F0)), // ✅ düzeltildi
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(item['isim'],
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500)),
                                                Text(
                                                  '₺${(item['fiyat'] * item['miktar']).toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF2563EB),
                                                      fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () =>
                                                    _miktarDegistir(index, -1),
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                      color: const Color(0xFFE2E8F0),
                                                      borderRadius:
                                                          BorderRadius.circular(4)),
                                                  child: const Icon(Icons.remove,
                                                      size: 14),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8),
                                                child: Text('${item['miktar']}',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold)),
                                              ),
                                              GestureDetector(
                                                onTap: () =>
                                                    _miktarDegistir(index, 1),
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                      color: const Color(0xFF2563EB),
                                                      borderRadius:
                                                          BorderRadius.circular(4)),
                                                  child: const Icon(Icons.add,
                                                      size: 14, color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const Divider(),
                        _fisSatir('Ara Toplam', '₺${_araToplam.toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        _fisSatir('KDV (%20)', '₺${_kdv.toStringAsFixed(2)}'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: Color(0xFF2563EB), width: 2))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Toplam',
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('₺${_toplam.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2563EB))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _sepet.isEmpty ? null : _odemeAl,
                            icon: const Icon(Icons.check_rounded),
                            label: Text(
                                _iadeMode ? 'İadeyi Tamamla' : 'Ödeme Al'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _iadeMode
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modButon(String label, IconData icon, bool isIade) {
    final aktif = _iadeMode == isIade;
    final renk = isIade ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _iadeMode = isIade),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: aktif ? renk : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: aktif ? renk : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: aktif ? Colors.white : const Color(0xFF64748B), size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: aktif ? Colors.white : const Color(0xFF64748B))),
            ],
          ),
        ),
      ),
    );
  }
}