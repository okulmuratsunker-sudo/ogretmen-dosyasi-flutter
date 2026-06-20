import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool loading = false;
  String? error;
  String? info;
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  Future<void> _submit() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => error = 'E-posta ve şifre gerekli');
      return;
    }
    setState(() {
      loading = true;
      error = null;
      info = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      if (isLogin) {
        await auth.signInWithPassword(email: email, password: pass);
      } else {
        final res = await auth.signUp(email: email, password: pass);
        if (res.user != null && res.session == null) {
          setState(() =>
              info = '✓ Kayıt başarılı! E-postanızı onaylayın, ardından giriş yapın.');
        }
      }
    } on AuthException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('📋 Öğretmen Dosyası',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Hesabınıza giriş yapın',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Giriş Yap')),
                        ButtonSegment(value: false, label: Text('Kayıt Ol')),
                      ],
                      selected: {isLogin},
                      onSelectionChanged: (s) =>
                          setState(() => isLogin = s.first),
                    ),
                    const SizedBox(height: 16),
                    if (error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.red.withOpacity(.08),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    if (info != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.green.withOpacity(.08),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(info!,
                            style: const TextStyle(color: Colors.green)),
                      ),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                          labelText: 'E-posta', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Şifre', border: OutlineInputBorder()),
                      obscureText: true,
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
