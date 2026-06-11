import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'raporlar_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _firestore = FirebaseFirestore.instance;
  String _aramaMetni = '';
bool _pasifGoster = false;

  void _urunEkleDialog({DocumentSnapshot? mevcutUrun}) {
    final data = mevcutUrun?.data() as Map<String, dynamic>?;

    final markaController = TextEditingController(text: data?['marka'] ?? '');
    final detayController = TextEditingController(text: data?['detay'] ?? '');
    final gramajController = TextEditingController(text: data?['gramaj'] ?? '');
    final barkodController = TextEditingController(text: data?['barkod'] ?? '');
    final alisFiyatController =
        TextEditingController(text: data?['alisFiyat']?.toString() ?? '');
    final satisFiyatController =
        TextEditingController(text: data?['fiyat']?.toString() ?? '');
    final stokController =
        TextEditingController(text: data?['stok']?.toString() ?? '');
    final kritikController =
        TextEditingController(text: data?['kritikSeviye']?.toString() ?? '5');

    String? seciliKategori = data?['kategori'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(
                mevcutUrun == null ? Icons.add_box_rounded : Icons.edit_rounded,
                color: const Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                mevcutUrun == null
                    ? 'Yeni Ürün Ekle'
                    : 'Ürün Bilgilerini Güncelle',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB)),
              ),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                            Text('Ürün Kimlik Bilgileri',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                                child: _inputAlani('Marka', markaController,
                                    hint: 'Ülker, Nestle...')),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _inputAlani('Detay', detayController,
                                    hint: 'Dido, KitKat...')),
                            const SizedBox(width: 12),
                          Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Gr/Ml',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151))),
      const SizedBox(height: 4),
      TextField(
        controller: gramajController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ],
        decoration: InputDecoration(
          hintText: '35, 500...',
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          suffixText: 'gr/ml',
          suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      ),
    ],
  ),
),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Barkod (EAN-13)',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: barkodController,
                              keyboardType: TextInputType.number,
                              maxLength: 13,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              decoration: InputDecoration(
                                hintText: '13 haneli barkod',
                                hintStyle: const TextStyle(
                                    fontSize: 12, color: Color(0xFF94A3B8)),
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0))),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE2E8F0))),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF2563EB), width: 2)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kategori',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151))),
                            const SizedBox(height: 4),
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('categories')
                                  .snapshots(),
                              builder: (context, snap) {
                                final kategoriler = snap.data?.docs ?? [];
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    border: Border.all(
                                        color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: seciliKategori,
                                      isExpanded: true,
                                      hint: const Text('Seçiniz...',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF94A3B8))),
                                      items: [
                                        ...kategoriler.map((k) =>
                                            DropdownMenuItem<String?>(
                                              value: (k.data() as Map<String,
                                                  dynamic>)['isim'],
                                              child: Text(
                                                (k.data() as Map<String,
                                                        dynamic>)['isim'] ??
                                                    '',
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                            )),
                                        const DropdownMenuItem<String?>(
                                          value: '__yeni__',
                                          child: Row(
                                            children: [
                                              Icon(Icons.add_rounded,
                                                  size: 14,
                                                  color: Color(0xFF2563EB)),
                                              SizedBox(width: 4),
                                              Text('+ Yeni Kategori Ekle',
                                                  style: TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          Color(0xFF2563EB))),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onChanged: (val) async {
                                        if (val == '__yeni__') {
                                          final yeniKatController =
                                              TextEditingController();
                                          final sonuc =
                                              await showDialog<String>(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: const Text(
                                                  'Yeni Kategori'),
                                              content: TextField(
                                                controller:
                                                    yeniKatController,
                                                autofocus: true,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Kategori adı...',
                                                  border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(ctx),
                                                  child:
                                                      const Text('İptal'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          ctx,
                                                          yeniKatController
                                                              .text
                                                              .trim()),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              const Color(
                                                                  0xFF2563EB),
                                                          foregroundColor:
                                                              Colors.white),
                                                  child: const Text('Ekle'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (sonuc != null &&
                                              sonuc.isNotEmpty) {
                                            await _firestore
                                                .collection('categories')
                                                .add({
                                              'isim': sonuc,
                                              'tarih':
                                                  FieldValue.serverTimestamp(),
                                            });
                                            setDialogState(() =>
                                                seciliKategori = sonuc);
                                          }
                                        } else {
                                          setDialogState(
                                              () => seciliKategori = val);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                          child: _inputAlani(
                              'Alış Fiyatı (Maliyet ₺)', alisFiyatController,
                              numpad: true,
                              renk: const Color(0xFF059669),
                              hint: '0.00')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _inputAlani(
                              'Satış Fiyatı (₺)', satisFiyatController,
                              numpad: true,
                              renk: const Color(0xFF2563EB),
                              hint: '0.00')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                          child: _inputAlani('Stok Miktarı', stokController,
                              numpad: true, hint: '0')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _inputAlani(
                              'Kritik Stok Sınırı', kritikController,
                              numpad: true,
                              renk: const Color(0xFFDC2626),
                              hint: '5')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (markaController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Marka adı boş olamaz!'),
                      backgroundColor: Colors.red));
                  return;
                }
                if (barkodController.text.length != 13) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Barkod 13 haneli olmalıdır!'),
                      backgroundColor: Colors.red));
                  return;
                }
if ((double.tryParse(alisFiyatController.text) ?? 0) <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Alış fiyatı 0 olamaz!'),
      backgroundColor: Colors.red));
  return;
}
if ((double.tryParse(satisFiyatController.text) ?? 0) <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Satış fiyatı 0 olamaz!'),
      backgroundColor: Colors.red));
  return;
}
if ((int.tryParse(stokController.text) ?? 0) <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Stok miktarı 0 olamaz!'),
      backgroundColor: Colors.red));
  return;
}
if ((int.tryParse(kritikController.text) ?? 0) <= 0) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Kritik stok sınırı 0 olamaz!'),
      backgroundColor: Colors.red));
  return;
}

                final isim = [
                  markaController.text.trim(),
                  detayController.text.trim(),
                  gramajController.text.trim(),
                ].where((s) => s.isNotEmpty).join(' - ');

                final veri = {
                  'isim': isim,
                  'marka': markaController.text.trim(),
                  'detay': detayController.text.trim(),
                  'gramaj': gramajController.text.trim(),
                  'barkod': barkodController.text.trim(),
                  'kategori': seciliKategori ?? '',
                  'alisFiyat':
                      double.tryParse(alisFiyatController.text) ?? 0,
                  'fiyat':
                      double.tryParse(satisFiyatController.text) ?? 0,
                  'stok': int.tryParse(stokController.text) ?? 0,
                  'kritikSeviye':
                      int.tryParse(kritikController.text) ?? 5,
                  'durum':
                      mevcutUrun == null ? 'aktif' : (data?['durum'] ?? 'aktif'),
                  'tarih': FieldValue.serverTimestamp(),
                };

                if (mevcutUrun == null) {
                  await _firestore.collection('products').add(veri);
                } else {
                  await _firestore
                      .collection('products')
                      .doc(mevcutUrun.id)
                      .update(veri);
                }
                if (mounted) Navigator.of(context, rootNavigator: true).pop();
            
              },
              icon: const Icon(Icons.check, size: 16),
              label: Text(mevcutUrun == null ? 'Kaydet' : 'Güncelle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _urunSilDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDC2626), width: 2),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.close, color: Color(0xFFDC2626), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Emin misin?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text('"${data['isim']}" isimli ürün silinecek!',
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
         onPressed: () async {
  await _firestore.collection('products').doc(doc.id).update({'durum': 'pasif'});
  Navigator.pop(context);
},
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white),
            child: const Text('Evet, sil!'),
          ),
        ],
      ),
    );
  }

  Widget _inputAlani(String label, TextEditingController controller,
      {bool numpad = false, Color? renk, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: renk ?? const Color(0xFF374151))),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: numpad ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color:
                        renk?.withOpacity(0.3) ?? const Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: renk ?? const Color(0xFF2563EB), width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.inventory_2_rounded,
                      color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 8),
                  Text('Ürün Yönetimi',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                ],
              ),
              TextButton.icon(
  onPressed: () => setState(() => _pasifGoster = !_pasifGoster),
  icon: Icon(
    _pasifGoster ? Icons.visibility_off : Icons.visibility,
    size: 16,
    color: _pasifGoster ? const Color(0xFFDC2626) : const Color(0xFF64748B),
  ),
  label: Text(
    _pasifGoster ? 'Pasif Gizle' : 'Pasif Göster',
    style: TextStyle(
      color: _pasifGoster ? const Color(0xFFDC2626) : const Color(0xFF64748B),
    ),
  ),
),
const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _urunEkleDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Yeni Ürün Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) =>
                setState(() => _aramaMetni = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Barkod / Ürün ara...',
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 8)
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('products').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var urunler = snapshot.data?.docs ?? [];
               if (!_pasifGoster) {
  urunler = urunler.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final durum = data.containsKey('durum') ? data['durum'] : 'aktif';
    return durum == 'aktif';
  }).toList();
}
                  if (_aramaMetni.isNotEmpty) {
                    urunler = urunler.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['isim'] ?? '')
                              .toLowerCase()
                              .contains(_aramaMetni) ||
                          (data['barkod'] ?? '')
                              .toLowerCase()
                              .contains(_aramaMetni) ||
                          (data['marka'] ?? '')
                              .toLowerCase()
                              .contains(_aramaMetni);
                    }).toList();
                  }
                  if (urunler.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined,
                              size: 48, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 8),
                          Text('Henüz ürün eklenmemiş',
                              style:
                                  TextStyle(color: Color(0xFF94A3B8))),
                        ],
                      ),
                    );
                  }
                  return Column(
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
                                child: Text('Barkod',
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
                                child: Text('Alış',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                            Expanded(
                                flex: 1,
                                child: Text('Satış',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                            Expanded(
                                flex: 1,
                                child: Text('Stok',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                            Expanded(
                                flex: 1,
                                child: Text('Durum',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                            Expanded(
                                flex: 2,
                                child: Text('İşlemler',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B)))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: urunler.length,
                          itemBuilder: (context, index) {
                            final doc = urunler[index];
                            final data =
                                doc.data() as Map<String, dynamic>;
                            final stok = data['stok'] ?? 0;
                            final kritik =
                                stok <= (data['kritikSeviye'] ?? 5);
                            final durum = data['durum'] ?? 'aktif';
                            final aktif = durum == 'aktif';

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: !aktif
                                    ? const Color(0xFFF8FAFC)
                                    : kritik
                                        ? const Color(0xFFFFF5F5)
                                        : Colors.white,
                                border: Border(
                                  left: !aktif
                                      ? const BorderSide(
                                          color: Color(0xFF94A3B8), width: 3)
                                      : kritik
                                          ? const BorderSide(
                                              color: Color(0xFFDC2626),
                                              width: 3)
                                          : BorderSide.none,
                                  bottom: const BorderSide(
                                      color: Color(0xFFF1F5F9)),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Ürün bilgisi
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(data['isim'] ?? '',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: aktif
                                                    ? const Color(0xFF1E293B)
                                                    : const Color(
                                                        0xFF94A3B8))),
                                        Text(
                                            'Eklenme: ${_tarihFormat(data['tarih'])}',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF94A3B8))),
                                      ],
                                    ),
                                  ),
                                  // Barkod
                                  Expanded(
                                    flex: 2,
                                    child: Text(data['barkod'] ?? '-',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF2563EB),
                                            fontFamily: 'monospace')),
                                  ),
                                  // Kategori
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(data['kategori'] ?? '-',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF2563EB))),
                                    ),
                                  ),
                                  // Alış
                                  Expanded(
                                    flex: 1,
                                    child: Text('₺${data['alisFiyat'] ?? 0}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF059669))),
                                  ),
                                  // Satış
                                  Expanded(
                                    flex: 1,
                                    child: Text('₺${data['fiyat'] ?? 0}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E293B))),
                                  ),
                                  // Stok
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: kritik
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF059669),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        kritik ? '⚠ $stok' : '$stok',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  // Durum toggle
                                 Expanded(
  flex: 1,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: aktif ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      aktif ? 'Aktif' : 'Pasif',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: aktif ? const Color(0xFF059669) : const Color(0xFFDC2626),
      ),
    ),
  ),
),
                                  // İşlemler
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.search_rounded,
                                              color: Color(0xFF059669),
                                              size: 18),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => RaporlarScreen(
                                                  baslangicUrunId: doc.id,
                                                  baslangicUrunIsim:
                                                      data['isim'] ?? '',
                                                ),
                                              ),
                                            );
                                          },
                                          tooltip: 'İncele',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.edit_outlined,
                                              color: Color(0xFF2563EB),
                                              size: 18),
                                          onPressed: () => _urunEkleDialog(
                                              mevcutUrun: doc),
                                          tooltip: 'Düzenle',
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              color: Color(0xFFDC2626),
                                              size: 18),
                                          onPressed: () =>
                                              _urunSilDialog(doc),
                                          tooltip: 'Sil',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _tarihFormat(dynamic tarih) {
    if (tarih == null) return '-';
    try {
      final dt = (tarih as Timestamp).toDate();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (e) {
      return '-';
    }
  }
}