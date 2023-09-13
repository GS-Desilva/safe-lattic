import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:safelattice/api/auth_manager/auth_manager.dart';
import 'package:safelattice/presentation/screens/home_screen.dart';
import 'package:safelattice/presentation/utils/app_colors.dart';
import 'package:safelattice/presentation/utils/sl_alerts.dart';
import 'package:safelattice/presentation/utils/sl_bottomsheet.dart';
import 'package:safelattice/presentation/widgets/logo_with_text.dart';
import 'package:safelattice/presentation/widgets/primary_button.dart';
import 'package:safelattice/presentation/widgets/primary_textfiled.dart';

class StagingScreen extends StatelessWidget {
  const StagingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? signInEmail;
    String? signInPassword;
    String? signUpEmail;
    String? signUpUsername;
    String? signUpPassword;
    String? signUpConfirmPassword;

    String? validateSignUp() {
      RegExp emailRegex = RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
      RegExp userNameRegex = RegExp(r'^[A-Za-z ]+$');
      RegExp passwordRegex = RegExp(
          r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{7,}$');

      if (!emailRegex.hasMatch(signUpEmail ?? "")) {
        return "Please enter valid email address";
      } else if (signUpUsername == null ||
          signUpUsername!.isEmpty ||
          !userNameRegex.hasMatch(signUpUsername ?? "")) {
        return "Please enter a valid username.";
      } else if (signUpPassword == null || signUpConfirmPassword == null) {
        return "Please enter valid passwords.";
      } else if (!passwordRegex.hasMatch(signUpPassword ?? "")) {
        return "Password should be more than 6 characters long and it should contain at least a single uppercase letter, lowercase letter, a number and a special character.";
      } else if (signUpPassword != signUpConfirmPassword) {
        return "Passwords entered do not match.";
      }

      return null;
    }

    String? validateSignIn() {
      RegExp emailRegex = RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

      if (!emailRegex.hasMatch(signInEmail ?? "")) {
        return "Please enter valid email address.";
      } else if (signInPassword == null || signInPassword!.isEmpty) {
        return "Please enter valid password.";
      }

      return null;
    }

    String? validateForgotPassword() {
      RegExp emailRegex = RegExp(
          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

      if (signInEmail == null ||
          signInEmail!.isEmpty ||
          !emailRegex.hasMatch(signInEmail!)) {
        return "Please enter a valid email address.";
      }

      return null;
    }

    Future<void> onTapSignUp() async {
      String? validationMessage = validateSignUp();
      if (validationMessage == null) {
        if (await AuthManager().signUp(
          email: signUpEmail!.trim(),
          password: signUpPassword!.trim(),
          userName: signUpUsername!.trim(),
        )) {
          Navigator.pop(context);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: "/HomeScreen"),
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      } else {
        SlAlert().showMessageDialog(
          context: context,
          title: "Invalid Input",
          message: validationMessage,
        );
      }
    }

    Future<void> onTapSignIn() async {
      String? validationMessage = validateSignIn();
      if (validationMessage == null) {
        if (await AuthManager().signIn(
            email: signInEmail!.trim(), password: signInPassword!.trim())) {
          Navigator.pop(context);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              settings: const RouteSettings(name: "/HomeScreen"),
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      } else {
        SlAlert().showMessageDialog(
          context: context,
          title: "Invalid Input",
          message: validationMessage,
        );
      }
    }

    Future<void> onTapForgotPassword() async {
      String? validationMessage = validateForgotPassword();
      if (validationMessage == null) {
        if (await AuthManager().sendPasswordResetLink(email: signInEmail!)) {
          SlAlert().showMessageDialog(
            context: context,
            title: "Success",
            message: "Password reset link sent to $signInEmail",
          );
        }
      } else {
        SlAlert().showMessageDialog(
          context: context,
          title: "Invalid Input",
          message: validationMessage,
        );
      }
    }

    void signUpModalContent() {
      SlBottomSheet().showCustomSheet(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Sign Up",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 45.0,
              ),
            ),
            const SizedBox(height: 10.0),
            Column(children: [
              PrimaryTextField(
                labelText: "Email",
                value: signUpEmail,
                keyboardType: TextInputType.emailAddress,
                callback: (value) => signUpEmail = value,
              ),
              const SizedBox(height: 10.0),
              PrimaryTextField(
                labelText: "Username",
                value: signUpUsername,
                maxLength: 20,
                callback: (value) => signUpUsername = value,
              ),
              const SizedBox(height: 10.0),
              PrimaryTextField(
                labelText: "Password",
                value: signUpPassword,
                isPassword: true,
                callback: (value) => signUpPassword = value,
              ),
              const SizedBox(height: 10.0),
              PrimaryTextField(
                labelText: "Confirm Password",
                value: signUpConfirmPassword,
                isPassword: true,
                callback: (value) => signUpConfirmPassword = value,
              ),
            ]),
            const SizedBox(height: 22.0),
            PrimaryButton(
              buttonText: "Join",
              callback: onTapSignUp,
            ),
            const SizedBox(height: 26.0),
          ],
        ),
      );
    }

    void loginModalContent() {
      SlBottomSheet().showCustomSheet(
        context: context,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Login",
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 45.0,
              ),
            ),
            const SizedBox(height: 10.0),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              PrimaryTextField(
                labelText: "Email",
                value: signInEmail,
                keyboardType: TextInputType.emailAddress,
                callback: (value) => signInEmail = value,
              ),
              const SizedBox(height: 10.0),
              PrimaryTextField(
                labelText: "Password",
                value: signInPassword,
                isPassword: true,
                callback: (value) => signInPassword = value,
              ),
              TextButton(
                onPressed: onTapForgotPassword,
                child: const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    fontSize: 14.0,
                    color: AppColors.primaryColor,
                  ),
                ),
              )
            ]),
            const SizedBox(height: 22.0),
            PrimaryButton(
              buttonText: "Proceed",
              callback: onTapSignIn,
            ),
            const SizedBox(height: 26.0),
          ],
        ),
      );
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.5,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 19.5, top: 47.0),
                child: LogoWithText(),
              ),
              const SizedBox(height: 61.8),
              SvgPicture.asset(
                "assets/images/staging_illustration.svg",
              ),
              const SizedBox(height: 43.7),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 21.5),
                child: Column(
                  children: [
                    PrimaryButton(
                      buttonText: "Sign Up",
                      callback: signUpModalContent,
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      buttonText: "Login",
                      outline: true,
                      callback: loginModalContent,
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 10.0),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
