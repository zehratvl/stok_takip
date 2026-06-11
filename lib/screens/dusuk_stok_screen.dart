import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class DusukStokScreen extends StatefulWidget {
  const DusukStokScreen({super.key});

  @override
  State<DusukStokScreen> createState() => _DusukStokScreenState();
}

class _DusukStokScreenState extends State<DusukStokScreen> {
  final _firestore = FirebaseFirestore.instance;

  final Map<String, Map<String, dynamic>> _sepet = {};

  String? _seciliTedarikciId;
  String? _seciliTedarikciWa;
  final _notController = TextEditingController();

  // Tedarikçi ekleme form controller'ları
  final _tedarikciIsimController = TextEditingController();
  final _tedarikciWaController = TextEditingController();

  void _sepeteEkle(String urunId, String urunIsim, int stok) {
    setState(() {
      if (_sepet.containsKey(urunId)) {
        _sepet[urunId]!['adet'] = (_sepet[urunId]!['adet'] as int) + 10;
      } else {
        _sepet[urunId] = {'isim': urunIsim, 'adet': 10};
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$urunIsim" sipariş listesine eklendi!'),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _sepettenCikar(String urunId) {
    setState(() => _sepet.remove(urunId));
  }

  void _adetDegistir(String urunId, int delta) {
    setState(() {
      final yeni = (_sepet[urunId]!['adet'] as int) + delta;
      if (yeni <= 0) {
        _sepet.remove(urunId);
      } else {
        _sepet[urunId]!['adet'] = yeni;
      }
    });
  }

 void _tedarikciEkleDialog() {
  _tedarikciIsimController.clear();
  _tedarikciWaController.clear();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Row(
        children: [
          Icon(Icons.people_rounded, color: Color(0xFF2563EB), size: 20),
          SizedBox(width: 8),
          Text('Tedarikçi Yönetimi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mevcut Tedarikçiler',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('suppliers').snapshots(),
              builder: (context, snap) {
                final liste = snap.data?.docs ?? [];
                if (liste.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Henüz tedarikçi yok.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  );
                }
                return Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: liste.length,
                    itemBuilder: (context, index) {
                      final doc = liste[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.person_rounded, size: 18, color: Color(0xFF2563EB)),
                        title: Text(data['isim'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        subtitle: Text(data['whatsapp'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                          onPressed: () async {
                            await _firestore.collection('suppliers').doc(doc.id).delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${data['isim']}" silindi!'),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Yeni Tedarikçi Ekle',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _tedarikciIsimController,
              decoration: InputDecoration(
                labelText: 'Tedarikçi Adı',
                hintText: 'örn: ABC Gıda Ltd.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tedarikciWaController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'WhatsApp Numarası',
                hintText: 'örn: 905321234567',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kapat', style: TextStyle(color: Color(0xFF94A3B8))),
        ),
        ElevatedButton(
          onPressed: () async {
            final isim = _tedarikciIsimController.text.trim();
            final wa = _tedarikciWaController.text.trim();
            if (isim.isEmpty || wa.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lütfen tüm alanları doldurun!'), backgroundColor: Colors.red),
              );
              return;
            }
            await _firestore.collection('suppliers').add({
              'isim': isim,
              'whatsapp': wa,
              'createdAt': FieldValue.serverTimestamp(),
            });
            _tedarikciIsimController.clear();
            _tedarikciWaController.clear();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"$isim" eklendi!'), backgroundColor: const Color(0xFF059669)),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Ekle'),
        ),
      ],
    ),
  );
}

  void _whatsappGonder() {
    if (_seciliTedarikciWa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir tedarikçi seçin!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_sepet.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş listesi boş! Ürün ekleyin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final simdi = DateTime.now();
    final tarih =
        '${simdi.day.toString().padLeft(2, '0')}.${simdi.month.toString().padLeft(2, '0')}.${simdi.year} ${simdi.hour.toString().padLeft(2, '0')}:${simdi.minute.toString().padLeft(2, '0')}';

    String mesaj = '🏪 *stOK SİSTEMİ - YENİ SİPARİŞ*\n';
    mesaj += '📅 Tarih: $tarih\n\n';
    mesaj += '*SİPARİŞ KALEMLERİ:*\n';

    _sepet.forEach((id, urun) {
      mesaj += '• ${urun['isim']} → *${urun['adet']} Adet*\n';
    });

    mesaj += '\n✅ Toplam: ${_sepet.length} Kalem Ürün\n';

    if (_notController.text.isNotEmpty) {
      mesaj += '\n📝 Not: En kısa sürede teslimat rica olunsun.';
    }

    final encoded = Uri.encodeComponent(mesaj);
    final wa = _seciliTedarikciWa!.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/$wa?text=$encoded';

    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').snapshots(),
        builder: (context, snapshot) {
          final tumUrunler = snapshot.data?.docs ?? [];
          final kritikUrunler = tumUrunler.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return (data['stok'] ?? 0) <= (data['kritikSeviye'] ?? 5);
          }).toList();

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol: Tablo
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFD97706), size: 22),
                        const SizedBox(width: 8),
                        const Text('Stok Alarmı Veren Ürünler',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${kritikUrunler.length} ürün kritik seviyede',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8)
                          ],
                        ),
                        child: kritikUrunler.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_outline,
                                        size: 48, color: Color(0xFF059669)),
                                    SizedBox(height: 8),
                                    Text('Tüm stoklar yeterli! 👍',
                                        style: TextStyle(
                                            color: Color(0xFF059669),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 12),
                                    decoration: const BoxDecoration(
                                        border: Border(
                                            bottom: BorderSide(
                                                color: Color(0xFFE2E8F0)))),
                                    child: const Row(
                                      children: [
                                        Expanded(
                                            flex: 3,
                                            child: Text('Ürün Bilgisi',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B)))),
                                        Expanded(
                                            flex: 2,
                                            child: Text('Kategori',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B)))),
                                        Expanded(
                                            flex: 1,
                                            child: Text('Mevcut',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B)))),
                                        Expanded(
                                            flex: 2,
                                            child: Text('İşlem',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF64748B)))),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: kritikUrunler.length,
                                      itemBuilder: (context, index) {
                                        final doc = kritikUrunler[index];
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        final stok = data['stok'] ?? 0;
                                        final kritik =
                                            data['kritikSeviye'] ?? 5;
                                        final urunIsim = data['isim'] ?? '';
                                        final sepette =
                                            _sepet.containsKey(doc.id);

                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: sepette
                                                ? const Color(0xFFEFFFF5)
                                                : Colors.white,
                                            border: Border(
                                              left: sepette
                                                  ? const BorderSide(
                                                      color: Color(0xFF059669),
                                                      width: 3)
                                                  : BorderSide.none,
                                              bottom: const BorderSide(
                                                  color: Color(0xFFF1F5F9)),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(urunIsim,
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Color(
                                                                0xFF1E293B))),
                                                    Text(
                                                        data['barkod'] ?? '-',
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Color(
                                                                0xFF94A3B8))),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFEFF6FF),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    data['kategori'] ?? '-',
                                                    style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Color(0xFF2563EB)),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                flex: 1,
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      '$stok',
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color(
                                                              0xFFDC2626)),
                                                    ),
                                                    Text(
                                                      '/$kritik',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Color(
                                                              0xFF94A3B8)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                flex: 2,
                                                child: sepette
                                                    ? Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        8,
                                                                    vertical:
                                                                        4),
                                                            decoration: BoxDecoration(
                                                                color: const Color(
                                                                    0xFFDCFCE7),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6)),
                                                            child: Text(
                                                              '${_sepet[doc.id]!['adet']} adet',
                                                              style: const TextStyle(
                                                                  fontSize: 11,
                                                                  color: Color(
                                                                      0xFF059669),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          GestureDetector(
                                                            onTap: () =>
                                                                _sepettenCikar(
                                                                    doc.id),
                                                            child: const Icon(
                                                                Icons
                                                                    .close_rounded,
                                                                size: 16,
                                                                color: Color(
                                                                    0xFFDC2626)),
                                                          ),
                                                        ],
                                                      )
                                                    : ElevatedButton.icon(
                                                        onPressed: () =>
                                                            _sepeteEkle(
                                                                doc.id,
                                                                urunIsim,
                                                                stok),
                                                        icon: const Icon(
                                                            Icons.add_rounded,
                                                            size: 14),
                                                        label: const Text(
                                                            '+ Tedariye Ekle',
                                                            style: TextStyle(
                                                                fontSize: 11)),
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                  0xFF2563EB),
                                                          foregroundColor:
                                                              Colors.white,
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6)),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 6),
                                                        ),
                                                      ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Sağ: Sipariş Formu
              SizedBox(
                width: 280,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04), blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Başlık
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.send_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Hızlı Sipariş Formu',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tedarikçi Seç + Ekle butonu
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Tedarikçi Seç',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151))),
                                GestureDetector(
                                  onTap: _tedarikciEkleDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.add_rounded,
                                            size: 12, color: Color(0xFF2563EB)),
                                        SizedBox(width: 2),
                                        Text('Ekle',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Tedarikçi dropdown - StreamBuilder ile gerçek zamanlı
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('suppliers')
                                  .snapshots(),
                              builder: (context, tedSnap) {
                                final tedarikciler =
                                    tedSnap.data?.docs.map((d) {
                                          final data =
                                              d.data() as Map<String, dynamic>;
                                          return {
                                            'id': d.id,
                                            'isim': data['isim'] ?? '',
                                            'whatsapp': data['whatsapp'] ?? '',
                                          };
                                        }).toList() ??
                                        [];

                                // Seçili tedarikçi artık yoksa sıfırla
                                if (_seciliTedarikciId != null &&
                                    !tedarikciler.any((t) =>
                                        t['id'] == _seciliTedarikciId)) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    setState(() {
                                      _seciliTedarikciId = null;
                                      _seciliTedarikciWa = null;
                                    });
                                  });
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: _seciliTedarikciId,
                                      isExpanded: true,
                                      hint: const Text('Seçiniz...',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF94A3B8))),
                                      items: tedarikciler
                                          .map((t) => DropdownMenuItem<String?>(
                                                value: t['id'],
                                                child: Text(t['isim'],
                                                    style: const TextStyle(
                                                        fontSize: 13)),
                                              ))
                                          .toList(),
                                      onChanged: (val) {
                                        final t = tedarikciler.firstWhere(
                                            (t) => t['id'] == val);
                                        setState(() {
                                          _seciliTedarikciId = val;
                                          _seciliTedarikciWa = t['whatsapp'];
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // Sipariş listesi
                            const Text('Sipariş Listesi',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151))),
                            const SizedBox(height: 8),

                            Container(
                              constraints:
                                  const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: _sepet.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: Text(
                                          'Henüz ürün eklenmedi.\nSoldan "+ Tedariye Ekle" ile ekleyin.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF94A3B8)),
                                        ),
                                      ),
                                    )
                                  : ListView(
                                      shrinkWrap: true,
                                      children: _sepet.entries.map((e) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  e.value['isim'],
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _adetDegistir(e.key, -1),
                                                    child: Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                          color: const Color(
                                                              0xFFE2E8F0),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4)),
                                                      child: const Icon(
                                                          Icons.remove,
                                                          size: 12),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6),
                                                    child: Text(
                                                      '${e.value['adet']}',
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _adetDegistir(e.key, 1),
                                                    child: Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                          color: const Color(
                                                              0xFF2563EB),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4)),
                                                      child: const Icon(
                                                          Icons.add,
                                                          size: 12,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ),
                            const SizedBox(height: 12),

                            // Sipariş notu
                            const Text('Sipariş Notu',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151))),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Notlarınızı buraya yazın...',
                                hintStyle: const TextStyle(
                                    fontSize: 12, color: Color(0xFF94A3B8)),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0))),
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // WhatsApp butonu
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _whatsappGonder,
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: const Text('WhatsApp ile Sipariş Geç'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            Center(
                              child: TextButton(
                                onPressed: () => setState(() {
                                  _sepet.clear();
                                  _seciliTedarikciId = null;
                                  _seciliTedarikciWa = null;
                                  _notController.clear();
                                }),
                                child: const Text('Formu Sıfırla',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8))),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}