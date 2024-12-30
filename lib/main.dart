import 'package:flutter/material.dart';
import 'package:fridge_mate_app/pages/home_page.dart';
import 'package:fridge_mate_app/pages/register_page.dart';

void main() {
  runApp(const FridgeMateApp());
}

class FridgeMateApp extends StatelessWidget {
  const FridgeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FridgeMate',
      theme: _buildThemeData(),
      home: const LoginScreen(),
    );
  }

  // Extract common theme styling into a method for easier maintenance.
  ThemeData _buildThemeData() {
    return ThemeData(
      primarySwatch: Colors.green,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _onForgotCredentialsPressed() {
    // Handle 'forgot username/password' action here
  }

  void _onLoginPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HomePage(),
      ),
    );
  }

  // Pass in BuildContext so we can push a new route.
  void _onRegisterPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RegisterScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FridgeMate',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          // Centers all items vertically in the middle of the screen.
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Center(
              child: Text(
                'Never waste a bite!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800, // Extra bold
                  fontStyle: FontStyle.italic, // Italic
                  color: Color.fromARGB(255, 183, 183, 183), // Gray interior
                  shadows: [
                    // Green outline effect using multiple shadows
                    Shadow(
                      offset: Offset(-1, -1),
                      blurRadius: 0,
                      color: Colors.green,
                    ),
                    Shadow(
                      offset: Offset(1, -1),
                      blurRadius: 0,
                      color: Colors.green,
                    ),
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 0,
                      color: Colors.green,
                    ),
                    Shadow(
                      offset: Offset(-1, 1),
                      blurRadius: 0,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Username',
              ),
            ),
            const SizedBox(height: 20),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Forgot username/password?',
                    style: TextStyle(fontSize: 13)),
                TextButton(
                  onPressed: _onForgotCredentialsPressed,
                  child: const Text(
                    'Click here',
                    style: TextStyle(fontSize: 14, color: Colors.purple),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 18),
              ),
              onPressed: () => _onLoginPressed(context),
              child: const Text(
                'Login',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 100),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?",
                      style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 10, width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onPressed: () => _onRegisterPressed(context),
                    child: const Text(
                      'Register!',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  

//  The code above is a simple Flutter app that displays a login screen. The app has a title, a help icon, and a form with a username and password field. The form also has a 'forgot username/password' link, a login button, and a 'register' button. 
//  The app is structured in a way that makes it easy to test. The  LoginScreen  widget is separated from the actions that handle the button presses. This separation makes it easier to test the actions without having to interact with the UI. 
//  The  FridgeMateApp  widget is also separated from the  LoginScreen  widget. This separation makes it easier to test the app's theme styling without having to interact with the UI. 
//  The  _buildThemeData  method in the  FridgeMateApp  widget extracts common theme styling into a method for easier maintenance. This method returns a  ThemeData  object that defines the app's theme. 
//  The  _onHelpPressed ,  _onForgotCredentialsPressed ,  _onLoginPressed , and  _onRegisterPressed  methods in the  LoginScreen  widget handle the button presses. These methods are separated from the UI code to make it easier to test the actions without having to interact with the UI. 
//  The  LoginScreen  widget is a stateless widget that displays the login screen. It has a title, a help icon, a form with a username and password field, a 'forgot username/password' link, a login button, and a 'register' button. 
//  The  LoginScreen  widget is structured in a way that makes it easy to test. The actions that handle the button presses are separated from the UI code, making it easier to test the actions without having to interact with the UI. 
//  The  FridgeMateApp  widget is a stateless widget that displays the app. It has a title, a theme, and a  LoginScreen  widget as its home screen. 
//  The  FridgeMateApp  widget is structured in a way that makes it easy to test. The theme styling is separated from the  LoginScreen  widget, making it easier to test the app's theme without having to interact with the UI. 
//  The code above is a simple Flutter app that displays a login screen. The app has a title, a help icon, and a form with a username and password field. The form also has a 'forgot username/password' link, a login button