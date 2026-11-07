import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/learning_models.dart';
import '../../core/widgets/app_controls.dart';

/// Opens a course resource inside the app (Chrome Custom Tabs on Android,
/// Safari view on iOS), so the student stays in the app. Falls back to the
/// browser if the in-app view isn't available.
Future<void> openCourseResource(
  BuildContext context,
  CourseResource resource,
) async {
  final rawUrl = resource.url.trim();
  if (rawUrl.isEmpty) {
    showAppSnackBar(
      context,
      'A file link has not been added yet for ${resource.name}.',
    );
    return;
  }
  final uri = Uri.tryParse(rawUrl);
  if (uri == null || !uri.hasScheme) {
    showAppSnackBar(context, 'This resource link is not valid yet.');
    return;
  }

  var opened = false;
  try {
    opened = await launchUrl(
      viewerUriFor(uri, type: resource.type),
      mode: LaunchMode.inAppBrowserView,
    );
  } catch (_) {
    opened = false;
  }
  if (!opened) {
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
  }
  if (!opened && context.mounted) {
    showAppSnackBar(context, 'Could not open ${resource.name} right now.');
  }
}

/// Chrome downloads a PDF instead of showing it, so PDFs go through Google's
/// viewer. Links already on Google Docs/Drive open as they are.
/// shortcut: Google's viewer can't open very large or private PDFs; move to a
/// native PDF viewer if students report that.
Uri viewerUriFor(Uri uri, {required String type}) {
  final isPdf =
      type.trim().toLowerCase() == 'pdf' ||
      uri.path.toLowerCase().endsWith('.pdf');
  final onGoogle =
      uri.host.endsWith('docs.google.com') ||
      uri.host.endsWith('drive.google.com');
  if (!isPdf || onGoogle) return uri;
  return Uri.https('docs.google.com', '/viewer', {'url': uri.toString()});
}
