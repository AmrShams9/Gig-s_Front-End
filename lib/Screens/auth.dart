import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  String _selectedRole = 'runner'; // Default role
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

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    if (!_isLogin && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a profile picture.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _form.currentState!.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await _authService.signInWithEmailAndPassword(
          _enteredEmail,
          _enteredPassword,
        );
      } else {
        UserCredential userCredential = await _authService.signUpWithEmailAndPassword(
          _enteredEmail,
          _enteredPassword,
        );

        if (_selectedImage != null && userCredential.user != null) {
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = path.basename(_selectedImage!.path);
          final savedImage = await _selectedImage!.copy('${appDir.path}/$fileName');

          // Pass the saved image path to RunnerHomeScreen
          if (mounted) {
            if (_selectedRole == 'runner') {
              Navigator.of(context).pushReplacementNamed(
                '/runner-home',
                arguments: savedImage.path, // Pass image path as argument
              );
            } else {
              Navigator.of(context).pushReplacementNamed('/poster-home');
            }
          }
        } else {
          // If no image is selected or user is null, navigate without image path
          if (mounted) {
            if (_selectedRole == 'runner') {
              Navigator.of(context).pushReplacementNamed('/runner-home');
            } else {
              Navigator.of(context).pushReplacementNamed('/poster-home');
            }
          }
        }
        // In a real app, you would also save _enteredFirstName, _enteredLastName, _enteredGovernmentId to Firebase Firestore.
      }

      // On successful authentication, navigate to the appropriate home screen if not already navigated
      if (mounted) {
        if (_selectedRole == 'runner') {
          Navigator.of(context).pushReplacementNamed('/runner-home');
        } else {
          Navigator.of(context).pushReplacementNamed('/poster-home');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        String message = 'An error occurred, please check your credentials!';
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided for that user.';
        } else if (e.code == 'email-already-in-use') {
          message = 'The email address is already in use by another account.';
        } else if (e.code == 'weak-password') {
          message = 'The password provided is too weak.';
        } else if (e.code == 'invalid-email') {
          message = 'The email address is not valid.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
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
                              _tempPassword = value; // Store password temporarily
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
                                  onTap: () {
                                    setState(() {
                                      _selectedRole = 'runner';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'runner'
                                          ? const Color(0xFF1DBF73)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.directions_run,
                                            color: _selectedRole == 'runner'
                                                ? Colors.white
                                                : Colors.black54),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Runner',
                                          style: TextStyle(
                                            color: _selectedRole == 'runner'
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
                                  onTap: () {
                                    setState(() {
                                      _selectedRole = 'task_poster';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 20),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'task_poster'
                                          ? const Color(0xFF1DBF73)
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(Icons.assignment,
                                            color: _selectedRole == 'task_poster'
                                                ? Colors.white
                                                : Colors.black54),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Task Poster',
                                          style: TextStyle(
                                            color: _selectedRole == 'task_poster'
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
                                backgroundColor: const Color(0xFF1DBF73), // Button color
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