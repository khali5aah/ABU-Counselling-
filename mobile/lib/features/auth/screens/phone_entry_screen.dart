import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../config/routes.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';

class CountryCode {
  const CountryCode(this.name, this.dialCode, this.isoCode);

  final String name;
  final String dialCode; // e.g. '+234'
  final String isoCode; // e.g. 'NG'
}

// Add or remove countries as needed.
const List<CountryCode> kCountryCodes = [
  CountryCode('Nigeria', '+234', 'NG'),
  CountryCode('Ghana', '+233', 'GH'),
  CountryCode('Kenya', '+254', 'KE'),
  CountryCode('South Africa', '+27', 'ZA'),
  CountryCode('Egypt', '+20', 'EG'),
  CountryCode('United Kingdom', '+44', 'GB'),
  CountryCode('United States', '+1', 'US'),
  CountryCode('Canada', '+1', 'CA'),
  CountryCode('India', '+91', 'IN'),
  CountryCode('Pakistan', '+92', 'PK'),
  CountryCode('Bangladesh', '+880', 'BD'),
  CountryCode('China', '+86', 'CN'),
  CountryCode('Malaysia', '+60', 'MY'),
  CountryCode('Saudi Arabia', '+966', 'SA'),
  CountryCode('United Arab Emirates', '+971', 'AE'),
  CountryCode('Germany', '+49', 'DE'),
  CountryCode('France', '+33', 'FR'),
  CountryCode('Turkey', '+90', 'TR'),
  CountryCode('Australia', '+61', 'AU'),
];

class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  String? _phoneError;
  bool _loading = false;
  CountryCode _country = kCountryCodes.first; // Nigeria by default

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Returns the local number as digits only, with any leading zero kept.
  String _cleanLocalInput(String input) {
    return input.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Converts the user's input into E.164 format using the selected country.
  /// Handles: local with leading zero (0803...), with dial code (234803...),
  /// or already international (+234803...).
  String _normalizeToE164(String input, CountryCode country) {
    final dialDigits =
        country.dialCode.replaceAll(RegExp(r'[^\d]'), ''); // e.g. '234'

    String cleaned = _cleanLocalInput(input);

    if (cleaned.startsWith('00$dialDigits')) {
      // '00234803...' -> '+234803...'
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith(dialDigits) &&
        cleaned.length > dialDigits.length + 6) {
      // '234803...' -> '+234803...'
    } else if (cleaned.startsWith('0')) {
      // '0803...' -> dial + '803...'
      cleaned = '$dialDigits${cleaned.substring(1)}';
    } else {
      // '803...' -> dial + '803...'
      cleaned = '$dialDigits$cleaned';
    }
    return '+$cleaned';
  }

  Future<void> _submitPhoneNumber() async {
    final rawInput = _phoneController.text.trim();
    final localDigits = _cleanLocalInput(rawInput);

    // International numbers: 7–12 digits for the national significant number.
    if (localDigits.length < 7 || localDigits.length > 15) {
      setState(() {
        _phoneError = 'Enter a valid phone number for ${_country.name}.';
      });
      return;
    }

    final normalizedPhone = _normalizeToE164(rawInput, _country);

    setState(() {
      _phoneError = null;
      _loading = true;
    });

    try {
      final result =
          await context.read<ApiClient>().requestOtp(normalizedPhone);
      if (!mounted) return;

      Navigator.pushNamed(
        context,
        Routes.otp,
        arguments: OtpArgs(
          phoneNumber: normalizedPhone,
          requestId: result.requestId,
          resendAfter: result.resendAfter,
          message: result.message,
          isRegistrationCode: result.isRegistrationCode,
        ),
      );
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _phoneError =
            exception.fieldError('phone_number') ?? exception.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Phone Number')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<CountryCode>(
                    initialValue: _country,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      border: OutlineInputBorder(),
                    ),
                    items: kCountryCodes
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.isoCode} ${c.dialCode}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _country = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\d\+\s\-\(\)]'),
                      ),
                      LengthLimitingTextInputFormatter(20),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. 8031234567',
                      errorText: _phoneError,
                      errorMaxLines: 3,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submitPhoneNumber,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
