import 'package:flutter/material.dart';
import 'otp_request_screen.dart';
import 'final_registration_screen.dart';

class RegistrationFlow extends StatefulWidget {
  const RegistrationFlow({super.key});

  @override
  State<RegistrationFlow> createState() => _RegistrationFlowState();
}

class _RegistrationFlowState extends State<RegistrationFlow> {
  String? _registrationEmail; 
  bool _registrationSuccessful = false;

  void _handleOtpRequested(String email) {
    setState(() {
      _registrationEmail = email;
    });
  }

  void _handleRegistrationSuccess() {
    setState(() {
      _registrationSuccessful = true;
    });
  }

  void _resetFlow() {
    setState(() {
      _registrationEmail = null;
      _registrationSuccessful = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_registrationSuccessful) {
      // Success Screen (placeholder)
      return const Center(child: Text("Registration Complete!"));
    }

    if (_registrationEmail == null) {
      // Step 1: Request OTP
      return OtpRequestScreen(
        onOtpRequested: _handleOtpRequested,
      );
    } else {
      // Step 2: Final Registration
      return FinalRegistrationScreen(
        email: _registrationEmail!,
        onRegistrationSuccess: _handleRegistrationSuccess,
        onBack: _resetFlow,
      );
    }
  }
}