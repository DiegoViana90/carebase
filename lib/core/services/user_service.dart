import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class UserService {
  static const _userKey = 'anon_user_id';

  /// Retorna o ID do usuário anônimo (gera se ainda não existir)
  static Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_userKey);

    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_userKey, id);
    }

    return id;
  }
}
