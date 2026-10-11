import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../state/app_data.dart';
import '../theme.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final AppData data;

  const LoginScreen({super.key, required this.data});

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
      await widget.data.services.auth.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      // Guard against the widget being removed mid-await.
      if (!mounted) return;

      // Replace login screen so the back button won't return to it.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(data: widget.data),
        ),
      );
    } on DioException catch (e) {
      setState(() {
        _errorMessage = e.response?.statusCode == 401
            ? 'Incorrect username or password'
            : 'Could not connect. Is the server running?';
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

              Center(
                child: Container(
                  width: 76.0,
                  height: 76.0,
                  decoration: BoxDecoration(
                    color: BrewColors.caramel.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                  child: const Icon(Icons.coffee_rounded, size: 40.0, color: BrewColors.caramel),
                ),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Brewlog',
                style: TextStyle(fontSize: 34.0, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Remember what made the cup good.',
                style: TextStyle(color: BrewColors.muted, fontSize: 15.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40.0),

              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline_rounded),
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
                  prefixIcon: Icon(Icons.lock_outline_rounded),
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
