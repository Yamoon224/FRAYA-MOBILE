import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fraya_mobile/core/utils/password_policy.dart';

TextEditingValue _apply(String text) {
  var value = TextEditingValue.empty;
  for (final formatter in PasswordPolicy.inputFormatters) {
    value = formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );
    text = value.text;
  }
  return value;
}

void main() {
  group('PasswordPolicy', () {
    test('accepte exactement 4 chiffres', () {
      for (final value in ['0000', '1234', '4821', '9999']) {
        expect(PasswordPolicy.isValidNew(value), isTrue, reason: value);
        expect(PasswordPolicy.validateNew(value), isNull, reason: value);
      }
    });

    test('refuse tout le reste', () {
      for (final value in ['', '123', '12345', 'abcd', '12a4', ' 123', '1 23', 'Secret123', '٤٨٢١']) {
        expect(PasswordPolicy.isValidNew(value), isFalse, reason: value);
        expect(PasswordPolicy.validateNew(value), isNotNull, reason: value);
      }
      expect(PasswordPolicy.validateNew(null), 'Champ requis');
      expect(PasswordPolicy.validateNew('123'), PasswordPolicy.invalidMessage);
    });

    test('la connexion accepte un code court comme un ancien mot de passe fort', () {
      expect(PasswordPolicy.minLoginLength, 4);
      expect('4821'.length >= PasswordPolicy.minLoginLength, isTrue);
      expect('Secret123'.length >= PasswordPolicy.minLoginLength, isTrue);
      expect('123'.length >= PasswordPolicy.minLoginLength, isFalse);
    });

    test('le clavier ne laisse passer que 4 chiffres', () {
      expect(_apply('48a2b1c9').text, '4821');
      expect(_apply('123456').text, '1234');
      expect(PasswordPolicy.keyboardType, TextInputType.number);
    });
  });
}
