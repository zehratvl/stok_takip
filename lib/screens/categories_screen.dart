import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _firestore = FirebaseFirestore.instance;

  void _kategoriEkleDialog({DocumentSnapshot? mevcutKategori}) {
    final data = mevcutKategori?.data() as Map<String, dynamic>?;
    final isimController = TextEditingController(text: data?['isim'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          mevcutKategori == null ? 'Yeni Kategori Ekle' : 'Kategoriyi Düzenle',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kategori Adı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(
              controller: isimController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Örn: Elektronik',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              if (isimController.text.trim().isEmpty) return;
              if (mevcutKategori == null) {
                await _firestore.collection('categories').add({
                  'isim': isimController.text.trim(),
                  'tarih': FieldValue.serverTimestamp(),
                });
              } else {
                await _firestore.collection('categories').doc(mevcutKategori.id).update({
                  'isim': isimController.text.trim(),
                });
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check, size: 16),
            label: Text(mevcutKategori == null ? 'Ekle' : 'Güncelle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _kategoriSilDialog(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final urunler = await _firestore.collection('products').where('kategori', isEqualTo: data['isim']).get();

    if (urunler.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDC2626), width: 2), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Color(0xFFDC2626), size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Silemezsiniz!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text('"${data['isim']}" kategorisinde ${urunler.docs.length} adet aktif ürün var.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
              child: const Text('Anladım'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFFDC2626), width: 2), shape: BoxShape.circle),
              child: const Icon(Icons.close, color: Color(0xFFDC2626), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Emin misin?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('"${data['isim']}" kategorisi silinecek!',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('categories').doc(doc.id).delete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Evet, sil!'),
          ),
        ],
      ),
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
                  Icon(Icons.label_rounded, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 8),
                  Text('Kategori Yönetimi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _kategoriEkleDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('+ Yeni Kategori'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Ürün gruplarını organize edin.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('categories').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final kategoriler = snapshot.data?.docs ?? [];
                if (kategoriler.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.label_outline, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Henüz kategori yok', style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _kategoriEkleDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('İlk Kategoriyi Ekle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: kategoriler.length,
                  itemBuilder: (context, index) {
                    final doc = kategoriler[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('products').where('kategori', isEqualTo: data['isim']).snapshots(),
                      builder: (context, urunSnapshot) {
                        final urunSayisi = urunSnapshot.data?.docs.length ?? 0;
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.label_rounded, color: Color(0xFF2563EB), size: 20),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFFD97706), size: 18),
                                        onPressed: () => _kategoriEkleDialog(mevcutKategori: doc),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 18),
                                        onPressed: () => _kategoriSilDialog(doc),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(data['isim'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                              const SizedBox(height: 4),
                              GestureDetector(
                                child: Text('$urunSayisi Ürün Mevcut >', style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}