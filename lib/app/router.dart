import 'package:flutter/material.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/dashboard/presentation/screens/splash_screen.dart';
import '../features/document_chat/presentation/screens/document_chat_screen.dart';
import '../features/documents/domain/models/document_entity.dart';
import '../features/documents/presentation/screens/document_details_screen.dart';
import '../features/documents/presentation/screens/pdf_viewer_screen.dart';
import '../features/model_manager/presentation/screens/model_manager_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/summarization/presentation/screens/summary_screen.dart';

/// Central application navigation router.
class AppRouter {
  static const String splash = '/';
  static const String dashboard = '/dashboard';
  static const String documentDetails = '/document-details';
  static const String pdfViewer = '/pdf-viewer';
  static const String modelManager = '/model-manager';
  static const String documentChat = '/document-chat';
  static const String summary = '/summary';
  static const String settings = '/settings';

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case documentDetails:
        final doc = routeSettings.arguments as DocumentEntity;
        return MaterialPageRoute(
          builder: (_) => DocumentDetailsScreen(document: doc),
        );
      case pdfViewer:
        if (routeSettings.arguments is PdfViewerArgs) {
          final args = routeSettings.arguments as PdfViewerArgs;
          return MaterialPageRoute(
            builder: (_) => PdfViewerScreen(
              document: args.document,
              initialPageNumber: args.initialPageNumber,
            ),
          );
        }
        final doc = routeSettings.arguments as DocumentEntity;
        return MaterialPageRoute(
          builder: (_) => PdfViewerScreen(document: doc),
        );
      case modelManager:
        return MaterialPageRoute(builder: (_) => const ModelManagerScreen());
      case documentChat:
        final doc = routeSettings.arguments as DocumentEntity;
        return MaterialPageRoute(
          builder: (_) => DocumentChatScreen(document: doc),
        );
      case summary:
        final doc = routeSettings.arguments as DocumentEntity;
        return MaterialPageRoute(
          builder: (_) => SummaryScreen(document: doc),
        );
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
}
