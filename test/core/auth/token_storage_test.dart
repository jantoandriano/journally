import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journally/core/auth/data/token_storage.dart';
import 'package:journally/core/auth/domain/auth_user.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockFlutterSecureStorage mockStorage;
  late TokenStorage tokenStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStorage = TokenStorage(storage: mockStorage);
  });

  test('saveSession writes the refresh token and serialized user', () async {
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    await tokenStorage.saveSession(
      refreshToken: 'refresh-abc',
      user: const AuthUser(id: 'u1', email: 'a@b.com'),
    );

    verify(() => mockStorage.write(key: 'refresh_token', value: 'refresh-abc')).called(1);
    verify(
      () => mockStorage.write(
        key: 'auth_user',
        value: '{"id":"u1","email":"a@b.com"}',
      ),
    ).called(1);
  });

  test('readSession returns null when nothing is stored', () async {
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

    expect(await tokenStorage.readSession(), isNull);
  });

  test('readSession reconstructs the stored session', () async {
    when(() => mockStorage.read(key: 'refresh_token')).thenAnswer((_) async => 'refresh-abc');
    when(() => mockStorage.read(key: 'auth_user'))
        .thenAnswer((_) async => '{"id":"u1","email":"a@b.com"}');

    final session = await tokenStorage.readSession();

    expect(session!.refreshToken, 'refresh-abc');
    expect(session.user.id, 'u1');
    expect(session.user.email, 'a@b.com');
  });

  test('clear deletes both keys', () async {
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    await tokenStorage.clear();

    verify(() => mockStorage.delete(key: 'refresh_token')).called(1);
    verify(() => mockStorage.delete(key: 'auth_user')).called(1);
  });
}
