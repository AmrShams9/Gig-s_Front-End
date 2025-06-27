import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../services/auth_service.dart';
import '../services/token_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
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
  var _enteredUsername = '';
  var _enteredPassword = '';
  var _enteredConfirmPassword = '';
  var _enteredFirstName = '';
  var _enteredLastName = '';
  var _enteredGovernmentId = '';
  var _enteredPhoneNumber = '';
  File? _selectedImage;
  var _selectedRoles = <String>[]; // List to store selected roles
  var _isLoading = false;
  String? _tempPassword; // Add this line to store password temporarily
  String? _authToken; // Store the authentication token

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

        // Try Spring backend login first
        final loginResult = await _authService.loginWithBackend(
          username: _enteredUsername,
          password: _enteredPassword,
        );

        if (loginResult['success']) {
          // Decode and print the token for debugging
          final token = loginResult['token'];
          if (token != null && token.isNotEmpty) {
            final Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
            print('--- DECODED TOKEN ---');
            print(jsonEncode(decodedToken));
            print('---------------------');
          }

          // Ensure the token exists before proceeding
          if (loginResult['token'] == null || loginResult['token'].isEmpty) {
            if (mounted) {
              final responseData = loginResult['data']?.toString() ?? 'No data received.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Login successful, but no token was found in the server response. Received: $responseData'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          // Check if a user ID is stored in TokenService
          final storedUserId = await TokenService.getUserId();
          if (storedUserId == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Login successful, but User ID could not be determined.'),
                  backgroundColor: Colors.red,
                ),
        );
            }
            return;
          }

          // Hardcoded admin check
          if (_enteredUsername.toLowerCase() == 'admin') {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/admin-dashboard');
            }
            return;
          }

          // Check if user is admin (you might need to modify this based on your backend response)
          bool isAdmin = false; // You'll need to implement this based on your backend

          if (isAdmin) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/admin-dashboard');
            }
            return;
          }

        // After successful login, navigate based on selected role
        if (mounted) {
          if (_selectedRoles.contains('runner')) {
            Navigator.of(context).pushReplacementNamed('/runner-home');
          } else {
            Navigator.of(context).pushReplacementNamed('/poster-home');
          }
        }
      } else {
          // Show error message from backend
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loginResult['error']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        // For signup, use Spring backend
        final registerResult = await _authService.registerWithBackend(
          username: _enteredUsername,
          firstName: _enteredFirstName,
          lastName: _enteredLastName,
          email: _enteredEmail,
          password: _enteredPassword,
          phoneNumber: _enteredPhoneNumber,
        );

        if (registerResult['success']) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Registration successful! Please login.'),
                backgroundColor: Colors.green,
              ),
            );
            // Switch to login mode
            setState(() {
              _isLogin = true;
              _selectedRoles.clear();
            });
          }
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(registerResult['error']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        // Show the actual error instead of a generic message
        final errorMessage = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
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
                              key: const ValueKey('email_signup'),
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
                              key: const ValueKey('phonenumber'),
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your phone number.';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _enteredPhoneNumber = value!;
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
                            key: const ValueKey('username'),
                            autocorrect: false,
                            textCapitalization: TextCapitalization.none,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your username.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _enteredUsername = value!.trim();
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
                              _enteredPassword = value!.trim();
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