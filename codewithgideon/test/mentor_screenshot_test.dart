import 'package:codewithgideon/src/features/community/models/mentor_request_model.dart';
import 'package:codewithgideon/src/features/community/state/mentor_request_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the image types the server accepts can be sent', () {
    expect(screenshotContentType('shot.PNG'), 'image/png');
    expect(screenshotContentType('a.jpeg'), 'image/jpeg');
    expect(screenshotContentType('a.webp'), 'image/webp');
    expect(screenshotContentType('a.heic'), isNull);
    expect(screenshotContentType('notes.pdf'), isNull);
  });

  test('screenshots in a message are read from its attachments', () {
    final message = MentorChatMessage.fromMap(
      conversationId: 'c1',
      fallbackId: 'm1',
      data: {
        'message': 'See the error',
        'senderType': 'user',
        'attachments': [
          {'url': 'https://firebasestorage.googleapis.com/x', 'name': 'a.png'},
          {'url': 'javascript:alert(1)'},
          'not a map',
        ],
      },
    );
    expect(message.imageUrls, ['https://firebasestorage.googleapis.com/x']);
  });
}
