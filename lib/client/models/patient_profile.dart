class PatientProfile {
  const PatientProfile({
    this.name = '',
    this.phone = '',
    this.gender = '',
    this.age,
    this.bloodGroup = '',
    this.allergies = '',
    this.conditions = '',
    this.medications = '',
    this.emergencyContact = '',
  });

  final String name;
  final String phone;
  final String gender;
  final int? age;
  final String bloodGroup;
  final String allergies;
  final String conditions;
  final String medications;
  final String emergencyContact;
}
