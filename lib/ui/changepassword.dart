import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChangePassword extends StatefulWidget {
  final String userId;
  
  const ChangePassword({Key? key, required this.userId}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  Future<void> _updatePassword() async {
    // First validate input fields
    if (_currentPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vă rugăm să introduceți parola curentă')),
      );
      return;
    }

    if (_newPasswordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parola nouă trebuie să aibă cel puțin 8 caractere')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parolele noi nu se potrivesc')),
      );
      return;
    }

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eroare: Utilizatorul nu este autentificat')),
        );
        return;
      }

      // First verify current password
      try {
        // Create credentials with current password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: _currentPasswordController.text,
        );

        // Attempt to reauthenticate
        await user.reauthenticateWithCredential(credential);
      } catch (e) {
        // If reauthentication fails, it means current password is wrong
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parola curentă este incorectă')),
        );
        return;
      }

      // If we get here, current password was correct
      // Update password in Firebase Auth
      await user.updatePassword(_newPasswordController.text);
      
      // Update password in Firestore
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .update({'password': _newPasswordController.text});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parola a fost actualizată cu succes')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      String errorMessage = 'Actualizarea parolei a eșuat';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'requires-recent-login':
            errorMessage = 'Vă rugăm să vă autentificați din nou pentru a schimba parola';
            break;
          case 'weak-password':
            errorMessage = 'Parola nouă este prea slabă';
            break;
          default:
            errorMessage = 'A apărut o eroare. Vă rugăm să încercați din nou';
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schimbă Parola',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'IBMPlexSans',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Parola Curentă',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _currentPasswordController,
              obscureText: !_showCurrentPassword,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Introduceți parola curentă',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showCurrentPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Parola Nouă',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newPasswordController,
              obscureText: !_showNewPassword,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Introduceți parola nouă',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Confirmă Parola Nouă',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Confirmați parola nouă',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            const Text(
              'Parola trebuie să conțină cel puțin 8 caractere.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontFamily: 'IBMPlexSans',
              ),
            ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDA291C),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Actualizează Parola',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'IBMPlexSans',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
