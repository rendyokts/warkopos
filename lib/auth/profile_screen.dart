import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:warkopos/auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userName;
  String? name;
  String? telp;
  String? email;
  String? role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print(token);

      if (token == null) {
        // Jika tidak ada token, redirect ke login
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
        return;
      }

      setState(() {
        userName = prefs.getString('user_username') ?? '';
        name = prefs.getString('user_name') ?? '';
        telp = prefs.getString('user_telp') ?? '';
        email = prefs.getString('user_email') ?? '';
        role = prefs.getString('user_role') ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data profil')),
        );
      }
    }
  }

  Future<void> _saveUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name ?? '');
      await prefs.setString('user_email', email ?? '');
      await prefs.setString('user_telp', telp ?? '');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data profil')),
        );
      }
    }
  }

  final List<Map<String, dynamic>> menuOptions = [
    // {
    //   'title': 'Backup Data',
    //   'subtitle': 'Cadangkan data transaksi',
    //   'icon': Icons.backup,
    //   'color': Colors.teal,
    //   'route': 'backup',
    // },
    {
      'title': 'Tentang Aplikasi',
      'subtitle': 'Versi 1.0.0',
      'icon': Icons.info,
      'color': Colors.indigo,
      'route': 'about',
    },
  ];

  void _handleMenuTap(String route) {
    switch (route) {
      case 'edit_profile':
        _showEditProfileDialog();
        break;
      case 'change_password':
        _showChangePasswordDialog();
        break;
      case 'notifications':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => _buildPlaceholderScreen('Pengaturan Notifikasi'),
          ),
        );
        break;
      case 'language':
        _showLanguageBottomSheet();
        break;
      case 'backup':
        _showBackupDialog();
        break;
      case 'about':
        _showAboutDialog();
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitur sedang dalam pengembangan')),
        );
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final phoneController = TextEditingController(text: telp);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Profil'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'No. Telepon',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validasi input
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Nama tidak boleh kosong')),
                    );
                    return;
                  }

                  if (emailController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email tidak boleh kosong')),
                    );
                    return;
                  }

                  // Validasi format email sederhana
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                  if (!emailRegex.hasMatch(emailController.text.trim())) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Format email tidak valid')),
                    );
                    return;
                  }

                  setState(() {
                    name = nameController.text.trim();
                    email = emailController.text.trim();
                    telp = phoneController.text.trim();
                  });

                  await _saveUserData();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil berhasil diperbarui'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan'),
              ),
            ],
          ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Ganti Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Lama',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Baru',
                      border: OutlineInputBorder(),
                      helperText: 'Minimal 6 karakter',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Validasi input
                  if (currentPasswordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password lama harus diisi'),
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password baru minimal 6 karakter'),
                      ),
                    );
                    return;
                  }

                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Konfirmasi password tidak cocok'),
                      ),
                    );
                    return;
                  }

                  // TODO: Implementasi API call untuk mengubah password
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password berhasil diubah')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ubah'),
              ),
            ],
          ),
    );
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pilih Bahasa',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Text('🇮🇩', style: TextStyle(fontSize: 24)),
                  title: const Text('Bahasa Indonesia'),
                  trailing: const Icon(Icons.check, color: Colors.green),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                  title: const Text('English'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Backup Data'),
            content: const Text(
              'Apakah Anda ingin membuat backup data transaksi? '
              'Backup akan disimpan di penyimpanan lokal.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _performBackup();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Backup'),
              ),
            ],
          ),
    );
  }

  void _performBackup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Membuat backup...'),
              ],
            ),
          ),
    );

    // Simulasi proses backup
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup berhasil dibuat')));
      }
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Tentang Aplikasi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_cafe, size: 64, color: Colors.blue[600]),
                const SizedBox(height: 16),
                const Text(
                  'Warkop POS',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Versi 1.0.0'),
                const SizedBox(height: 16),
                const Text(
                  'Sistem kasir sederhana untuk warung kopi dan restoran kecil.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  '© 2024 Warkop Aceng',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal logout')));
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Keluar'),
            content: const Text(
              'Apakah Anda yakin ingin keluar dari aplikasi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _logout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );
  }

  Widget _buildPlaceholderScreen(String title) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sedang dalam pengembangan',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'Profil',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.blue[100],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name?.isNotEmpty == true ? name! : 'Nama Pengguna',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      role?.isNotEmpty == true ? '$role' : '@role',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildContactInfo(
                        Icons.email,
                        email?.isNotEmpty == true
                            ? email!
                            : 'Email tidak diset',
                      ),
                      Container(width: 1, height: 30, color: Colors.grey[300]),
                      _buildContactInfo(
                        Icons.phone,
                        telp?.isNotEmpty == true
                            ? telp!
                            : 'Telepon tidak diset',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu Options
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children:
                    menuOptions.asMap().entries.map((entry) {
                      int index = entry.key;
                      Map<String, dynamic> option = entry.value;

                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: option['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                option['icon'],
                                color: option['color'],
                                size: 20,
                              ),
                            ),
                            title: Text(
                              option['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              option['subtitle'],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () => _handleMenuTap(option['route']),
                          ),
                          if (index < menuOptions.length - 1)
                            Divider(height: 1, color: Colors.grey[200]),
                        ],
                      );
                    }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // Logout Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[600],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red[200]!),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Keluar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
