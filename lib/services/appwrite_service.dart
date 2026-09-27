import 'package:appwrite/appwrite.dart';

import '../core/appwrite_config.dart';

class AppwriteService {
  AppwriteService._()
    : client = Client()
          .setEndpoint(appwriteEndpoint)
          .setProject(appwriteProjectId);

  static final AppwriteService instance = AppwriteService._();

  final Client client;

  Future<String> ping() => client.ping();
}
