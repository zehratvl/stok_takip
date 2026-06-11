import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _errorMessage = '';
  String _secilenRol = 'calisan';

  Future<void> _register() async {
    if (_passwordController.text != _passwordConfirmController.text) {
      setState(() => _errorMessage = 'Şifreler eşleşmiyor!');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await UserService.kullaniciKaydet(
        uid: userCredential.user!.uid,
        email: _emailController.text.trim(),
        rol: _secilenRol,
      );
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kayıt Başarılı! 🎉'),
            content: Text('Hesabınız "${_secilenRol == 'admin' ? 'Admin' : 'Çalışan'}" rolüyle oluşturuldu. Şimdi giriş yapabilirsiniz.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                child: const Text('Giriş Yap'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Bir hata oluştu');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 420,
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text('Hesap Oluştur', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                const Text('Yeni bir hesap oluşturun.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(height: 32),
                _inputAlani('E-posta', _emailController, hint: 'ornek@email.com'),
                const SizedBox(height: 16),
                _inputAlani('Şifre', _passwordController, hint: '••••••••', obscure: _obscurePassword, onToggle: () => setState(() => _obscurePassword = !_obscurePassword)),
                const SizedBox(height: 16),
                _inputAlani('Şifre Tekrar', _passwordConfirmController, hint: '••••••••', obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
                const SizedBox(height: 16),
                Align(alignment: Alignment.centerLeft, child: Text('Rol Seçin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _secilenRol = 'admin'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _secilenRol == 'admin' ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _secilenRol == 'admin' ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, color: _secilenRol == 'admin' ? Colors.white : const Color(0xFF64748B), size: 24),
                              const SizedBox(height: 4),
                              Text('Admin', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _secilenRol == 'admin' ? Colors.white : const Color(0xFF64748B))),
                              Text('Tam yetki', style: TextStyle(fontSize: 11, color: _secilenRol == 'admin' ? Colors.white70 : const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _secilenRol = 'calisan'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _secilenRol == 'calisan' ? const Color(0xFF059669) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _secilenRol == 'calisan' ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.person_rounded, color: _secilenRol == 'calisan' ? Colors.white : const Color(0xFF64748B), size: 24),
                              const SizedBox(height: 4),
                              Text('Çalışan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _secilenRol == 'calisan' ? Colors.white : const Color(0xFF64748B))),
                              Text('Sınırlı yetki', style: TextStyle(fontSize: 11, color: _secilenRol == 'calisan' ? Colors.white70 : const Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Kayıt Ol', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Zaten hesabın var mı?', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Giriş Yap', style: TextStyle(color: Color(0xFF2563EB), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputAlani(String label, TextEditingController controller, {String hint = '', bool obscure = false, VoidCallback? onToggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            suffixIcon: onToggle != null
                ? IconButton(
                    icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
                    onPressed: onToggle,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}