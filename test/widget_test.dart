// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:physio/client/models/care_service.dart';
import 'package:physio/client/models/patient_profile.dart';
import 'package:physio/client/models/saved_address.dart';
import 'package:physio/client/screens/booking_flow_screen.dart';
import 'package:physio/client/screens/profile_screen.dart';
import 'package:physio/client/screens/onboarding_screen.dart';
import 'package:physio/client/core/app_settings.dart';

void main() {
  testWidgets('Material app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SizedBox())),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('login is first; sign up asks for basic profile details', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileSetupPage()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Full name'), findsNothing);
    expect(find.text('Mobile number'), findsNothing);
    expect(find.text('Not registered? Sign up'), findsOneWidget);

    await tester.tap(find.text('Not registered? Sign up'));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Gender (optional)'), findsOneWidget);
    expect(find.text('Age (optional)'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(4));
    final phoneField = find.widgetWithText(TextFormField, 'Mobile number');
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '+91 7985464728');
    expect(
      tester.widget<TextFormField>(phoneField).controller?.text,
      '7985464728',
    );
    await tester.scrollUntilVisible(
      find.text('Already registered? Log in'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Already registered? Log in'), findsOneWidget);
  });

  testWidgets('profile editor contains personal details only', (
    WidgetTester tester,
  ) async {
    PatientProfile? savedProfile;
    await tester.pumpWidget(
      MaterialApp(
        home: ProfileEditPage(
          initialProfile: const PatientProfile(name: 'Test Patient'),
          onSave: (profile) async => savedProfile = profile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Personal details'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Gender (optional)'), findsOneWidget);
    expect(find.text('Age (optional)'), findsOneWidget);
    expect(find.text('Medical details (optional)'), findsNothing);
    expect(find.text('Blood group'), findsNothing);
    expect(find.text('Allergies'), findsNothing);
    await tester.tap(find.text('Save details'));
    await tester.pumpAndSettle();
    expect(savedProfile?.name, 'Test Patient');
  });

  testWidgets('medical history has its own health details form', (
    WidgetTester tester,
  ) async {
    PatientProfile? savedProfile;
    await tester.pumpWidget(
      MaterialApp(
        home: MedicalHistoryPage(
          initialProfile: const PatientProfile(name: 'Test Patient'),
          onSave: (profile) async => savedProfile = profile,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Medical history'), findsOneWidget);
    expect(find.text('Medical details (optional)'), findsOneWidget);
    expect(find.text('Blood group'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Allergies'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Allergies'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Current medications'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Existing conditions'), findsOneWidget);
    expect(find.text('Current medications'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Emergency contact (optional)'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Emergency contact (optional)'), findsOneWidget);

    await tester.tap(find.text('Save medical history'));
    await tester.pumpAndSettle();
    expect(savedProfile?.name, 'Test Patient');
  });

  testWidgets('address book supports adding, editing, and deleting addresses', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: AddressBookPage(bookings: [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('No saved addresses yet'), findsOneWidget);
    await tester.tap(find.text('Add address'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'House / flat and street address'),
      '22 Lake View Road',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Area / locality'),
      'Indiranagar',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'City'),
      'Bengaluru',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'State'),
      'Karnataka',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'PIN code'),
      '560038',
    );
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();

    expect(find.text('No saved addresses yet'), findsNothing);
    expect(find.text('22 Lake View Road'), findsOneWidget);
    expect(
      find.text('Indiranagar, Bengaluru, Karnataka, 560038'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Edit address'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'House / flat and street address'),
      '24 Lake View Road',
    );
    await tester.tap(find.text('Save address'));
    await tester.pumpAndSettle();
    expect(find.text('24 Lake View Road'), findsOneWidget);
    expect(find.text('22 Lake View Road'), findsNothing);

    await tester.tap(find.byTooltip('Delete address'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('No saved addresses yet'), findsOneWidget);
  });

  testWidgets('booking form can fill its address from the address book', (
    WidgetTester tester,
  ) async {
    const savedAddress = SavedAddress(
      id: 'home-1',
      label: 'Home',
      addressType: 'Home',
      address: '22 Lake View Road',
      area: 'Indiranagar',
      city: 'Bengaluru',
      state: 'Karnataka',
      pinCode: '560038',
      landmark: 'Lake View Park',
    );
    SharedPreferences.setMockInitialValues({
      savedAddressesKey: jsonEncode([savedAddress.toJson()]),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BookingAddressPage(
          service: careServices.first,
          currentPlace: null,
          date: DateTime(2026, 10, 24),
          time: '10:00 AM',
          onBookingConfirmed: (booking) async => booking,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addressPicker = find.byType(DropdownButtonFormField<String>);
    expect(addressPicker, findsOneWidget);
    await tester.tap(addressPicker);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Home · 22 Lake View Road'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save & continue'));
    await tester.pumpAndSettle();

    expect(find.text('Review booking'), findsOneWidget);
    expect(
      find.text('22 Lake View Road\nIndiranagar\nBengaluru, Karnataka, 560038'),
      findsOneWidget,
    );
    expect(find.text(savedAddress.landmark), findsOneWidget);
  });
}
