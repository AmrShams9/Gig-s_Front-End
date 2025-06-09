import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
//firbasefirstore.instance.collection('users').doc(user id).set(username email imageurl,
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  final _authService = AuthService();
  final _form = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  var _enteredConfirmPassword = '';
  var _enteredFirstName = '';
  var _enteredLastName = '';
  var _enteredGovernmentId = '';
  File? _selectedImage;
  var _selectedRoles = <String>[]; // List to store selected roles
  var _isLoading = false;
  String? _tempPassword; // Add this line to store password temporarily

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 150,
      );

      if (pickedImage != null) {
        setState(() {
          _selectedImage = File(pickedImage.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRole(String role) {
    setState(() {
      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }
    });
  }

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    _form.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // For login, we need to select a role
        if (_selectedRoles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a role to continue.'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        await _authService.signInWithEmailAndPassword(
          _enteredEmail,
          _enteredPassword,
        );

        // After successful login, navigate based on selected role
        if (mounted) {
          if (_selectedRoles.contains('runner')) {
            Navigator.of(context).pushReplacementNamed('/runner-home');
          } else {
            Navigator.of(context).pushReplacementNamed('/poster-home');
          }
        }
      } else {
        // For signup, create user with both roles
        UserCredential userCredential = await _authService.signUpWithEmailAndPassword(
          _enteredEmail,
          _enteredPassword,
          _enteredFirstName,
          _enteredLastName,
          _enteredGovernmentId,
          ['runner', 'task_poster'], // Register with both roles
          _selectedImage?.path, // Optional profile picture
        );

        if (userCredential.user != null) {
          if (mounted) {
            // After signup, show role selection dialog
            _showRoleSelectionDialog();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        String message = 'An error occurred, please check your credentials!';
        if (e.toString().contains('user-not-found')) {
          message = 'No user found for that email.';
        } else if (e.toString().contains('wrong-password')) {
          message = 'Wrong password provided for that user.';
        } else if (e.toString().contains('email-already-in-use')) {
          message = 'The email address is already in use by another account.';
        } else if (e.toString().contains('weak-password')) {
          message = 'The password provided is too weak.';
        } else if (e.toString().contains('invalid-email')) {
          message = 'The email address is not valid.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRoleSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Your Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please select how you want to use the app:'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/runner-home');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.directions_run, color: Colors.blue.shade700),
                        const SizedBox(height: 8),
                        const Text('Runner'),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (mounted) {
                      Navigator.of(context).pushReplacementNamed('/poster-home');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.assignment, color: Colors.green.shade700),
                        const SizedBox(height: 8),
                        const Text('Task Poster'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(
                  top: 30,
                  bottom: 20,
                  left: 20,
                  right: 20,
                ),
                child: const Text(
                  'Gigs',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1DBF73),
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin) ...[
                            Center(
                              child: Stack(
                                children: [
                                  GestureDetector(
                                    onTap: _showImagePickerDialog,
                                    child: Container(
                                      width: 120,
                                      height: 120,
                                      margin: const EdgeInsets.only(bottom: 20),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Theme.of(context).colorScheme.primaryContainer,
                                        image: _selectedImage != null
                                            ? DecorationImage(
                                                image: FileImage(_selectedImage!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _selectedImage == null
                                          ? Icon(
                                              Icons.camera_alt,
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                                              size: 50,
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (_selectedImage != null)
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: InkWell(
                                        onTap: _showImagePickerDialog,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.secondaryContainer,
                                            shape: BoxShape.circle,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: Icon(
                                            Icons.edit,
                                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            TextFormField(
                              key: const ValueKey('firstname'),
                              autocorrect: false,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your first name.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredFirstName = value!;
                              },
                            ),
                            TextFormField(
                              key: const ValueKey('lastname'),
                              autocorrect: false,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Last Name',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your last name.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredLastName = value!;
                              },
                            ),
                            TextFormField(
                              key: const ValueKey('governmentid'),
                              keyboardType: TextInputType.text,
                              decoration: const InputDecoration(
                                labelText: 'Government ID',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your government ID.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredGovernmentId = value!;
                              },
                            ),
                          ],
                          TextFormField(
                            key: const ValueKey('email'),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                            ),
                            validator: (value) {
                              if (value == null || !value.contains('@')) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredEmail = value!;
                            },
                          ),
                          TextFormField(
                            key: const ValueKey('password'),
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            validator: (value) {
                              _tempPassword = value;
                              if (value == null || value.trim().length < 6) {
                                return 'Password must be at least 6 characters long.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredPassword = value!;
                            },
                          ),
                          if (!_isLogin) ...[
                            TextFormField(
                              key: const ValueKey('confirmpassword'),
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Confirm Password',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please confirm your password.';
                                }
                                if (value != _tempPassword) {
                                  return 'Passwords do not match.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredConfirmPassword = value!;
                              },
                            ),
                          ],
                          const SizedBox(height: 12),
                          if (_isLogin) ...[
                            // Role Selection for Login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                InkWell(
                                  onTap: () => _toggleRole('runner'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: _selectedRoles.contains('runner')
                                          ? const Color(0xFF1DBF73)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.directions_run,
                                            color: _selectedRoles.contains('runner')
                                                ? Colors.white
                                                : Colors.black54),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Runner',
                                          style: TextStyle(
                                            color: _selectedRoles.contains('runner')
                                                ? Colors.white
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                InkWell(
                                  onTap: () => _toggleRole('task_poster'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: _selectedRoles.contains('task_poster')
                                          ? const Color(0xFF1DBF73)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.assignment,
                                            color: _selectedRoles.contains('task_poster')
                                                ? Colors.white
                                                : Colors.black54),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Task Poster',
                                          style: TextStyle(
                                            color: _selectedRoles.contains('task_poster')
                                                ? Colors.white
                                                : Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1DBF73),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                _isLogin ? 'Login' : 'Signup',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _selectedRoles.clear();
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? 'Create an account'
                                  : 'I already have an account',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}