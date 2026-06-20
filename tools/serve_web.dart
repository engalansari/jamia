import 'dart:io';

Future<void> main() async {
  final root = Directory('app/build/web');
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
  await for (final request in server) {
    var path = Uri.decodeComponent(request.uri.path);
    if (path == '/') path = '/index.html';

    var file = File('${root.path}$path');
    if (!await file.exists()) {
      file = File('${root.path}/index.html');
    }

    request.response.headers.contentType = _contentType(file.path);
    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}

ContentType _contentType(String path) {
  if (path.endsWith('.html')) {
    return ContentType.html;
  }
  if (path.endsWith('.js')) {
    return ContentType('application', 'javascript', charset: 'utf-8');
  }
  if (path.endsWith('.json')) {
    return ContentType.json;
  }
  if (path.endsWith('.png')) {
    return ContentType('image', 'png');
  }
  if (path.endsWith('.wasm')) {
    return ContentType('application', 'wasm');
  }
  return ContentType.binary;
}
