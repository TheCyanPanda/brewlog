import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../services/app_services.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AppServices services;

  const LoginScreen({super.key, required this.services});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Text edit controls — current value read via controller.text.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage; // null = no error to show

  // Always dispose controllers to free memory.
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.services.auth.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      // Guard against the widget being removed mid-await.
      if (!mounted) return;

      // Replace login screen so the back button won't return to it.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(services: widget.services),
        ),
      );
    } on DioException catch (e) {
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

              // Only rendered when there is an error to show.
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

              // Setting onPressed to null automatically disables + greys out the button.
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
