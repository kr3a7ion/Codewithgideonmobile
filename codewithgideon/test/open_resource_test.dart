import 'package:codewithgideon/src/features/resources/open_resource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDFs open through the Google viewer', () {
    final uri = Uri.parse(
      'https://firebasestorage.googleapis.com/v0/b/x/o/resources%2Fslides.pdf?alt=media&token=t',
    );
    final viewer = viewerUriFor(uri, type: 'PDF');
    expect(viewer.host, 'docs.google.com');
    expect(viewer.queryParameters['url'], uri.toString());
  });

  test('links already on Google Docs, and other links, open as they are', () {
    final doc = Uri.parse('https://docs.google.com/document/d/abc/edit');
    final site = Uri.parse('https://flutter.dev/docs');
    expect(viewerUriFor(doc, type: 'PDF'), doc);
    expect(viewerUriFor(site, type: 'Link'), site);
  });
}
