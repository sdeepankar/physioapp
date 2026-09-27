/// Contact details for Deep Care support.
///
/// Keep these unset until the product owner provides verified contact
/// information. Phone numbers should use international format (for example,
/// +91 followed by the number); WhatsApp numbers should contain digits only.
class SupportConfiguration {
  const SupportConfiguration({
    this.phoneNumber,
    this.whatsAppNumber,
    this.emailAddress,
  });

  final String? phoneNumber;
  final String? whatsAppNumber;
  final String? emailAddress;
}

const supportConfiguration = SupportConfiguration(
  phoneNumber: null,
  whatsAppNumber: null,
  emailAddress: null,
);
