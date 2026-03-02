import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  final Dio dio;

  const LoginScreen(
    {
      super.key,
      required this.authService,
      required this.dio,
    }
  );

  @override
  State<LoginScreen> createState() => _LoginScreenState();

}


// The Stateful class
class _LoginScreenState extends State<LoginScreen> {
  // Text edit controls. Current value is read by controller.text
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage; // null = no error

  // dispose() is always called when this widged is not int the tree. Apways dispose to free memory!
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(()
      {
        _isLoading = true;
        _errorMessage = null;
      }
    );

    try {
      await widget.authService.login( // Fill with text from login form
        _usernameController.text.trim(),
        _passwordController.text,
      );

      // Check is widget is still in tree (user may have navigated away)
      if (!mounted) return;

      //Remove LoginScreen fromthe stack (back button wont return to login screen)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(dio: widget.dio, authService: widget.authService)
        ),
      );

    } on DioException catch(e) {
      // Catch dio network/response errors
      setState(() {
        _errorMessage = e.response?.statusCode == 401
          ? 'Incorrect username or password'
          : 'Could not connect. Is the server running? ($e)';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // stretch makes children fill the full width
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[

              const Text(
                '☕ CoffeeLog',
                style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48.0),

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next, // keyboard "next" key
              ),
              const SizedBox(height: 16.0),

              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true, // masks input
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(), // pressing "done" triggers login
              ),

              // Conditionally show error — only renders if _errorMessage != null
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),

              const SizedBox(height: 24.0),

              // FilledButton is the Material 3 primary action button.
              // Setting onPressed to null automatically disables + greys it out.
              FilledButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const SizedBox(
                        height: 20.0,
                        width: 20.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Text('Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
