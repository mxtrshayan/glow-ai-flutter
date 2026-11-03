import 'dart:io';

Future<String> portraitFixture() async {
  const localPath = String.fromEnvironment('TEST_PORTRAIT_PATH');
  if (localPath.isNotEmpty) return localPath;
  // Use a public test image when running on Android, which cannot read host files.
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse(
        'https://raw.githubusercontent.com/scikit-image/scikit-image/v0.24.0/skimage/data/astronaut.png',
      ),
    );
    final response = await request.close();
    if (response.statusCode != 200) {
      throw HttpException('Could not download the public test fixture');
    }
    final bytes = await response.fold<List<int>>(
      [],
      (all, chunk) => all..addAll(chunk),
    );
    final file = File('${Directory.systemTemp.path}/glow-test-portrait.png');
    await file.writeAsBytes(bytes);
    return file.path;
  } finally {
    client.close();
  }
}
