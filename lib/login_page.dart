import 'package:flutter/material.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'main_page.dart';
import 'roll_call_page.dart';
import 'voting_page.dart';
import 'settings_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Login',
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 32.0),
              SupaEmailAuth(
                redirectTo: kIsWeb ? null : 'com.wheelermun.modelunwebcontrol://callback',
                onSignInComplete: (response) {
                  // Navigate to the home page on successful sign-in
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                onSignUpComplete: (response) {
                  // Navigate to a waiting page after sign-up
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WaitingPage()),
                  );
                },
                metadataFields: [
                  MetaDataField(
                    prefixIcon: const Icon(Icons.person),
                    label: 'Username',
                    key: 'username',
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              SizedBox(height: 24.0),
              Text(
                'Or sign in with',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 16.0),
              SupaSocialsAuth(
                socialProviders: [
                  OAuthProvider.apple,
                  OAuthProvider.google,
                ],
                nativeGoogleAuthConfig: const NativeGoogleAuthConfig(
                  webClientId: 'YOUR_WEB_CLIENT_ID',
                  iosClientId: 'YOUR_IOS_CLIENT_ID',
                ),
                enableNativeAppleAuth: true,
                colored: true,
                onSuccess: (Session response) {
                  // Navigate to the home page on successful social sign-in
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                onError: (error) {
                  // Handle the error
                  print('Social sign-in error: $error');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WaitingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email,
              size: 80.0,
              color: Colors.blue,
            ),
            SizedBox(height: 24.0),
            Text(
              'Thank you for signing up!',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.0),
            Text(
              'Please check your email to verify your account.',
              style: TextStyle(fontSize: 18.0),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                // Navigate back to the login page
                Navigator.pushReplacementNamed(context, '/');
              },
              child: Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}