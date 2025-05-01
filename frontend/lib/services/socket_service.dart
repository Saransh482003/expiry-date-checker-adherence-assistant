import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'notification_service.dart';

class SocketService {
  late IO.Socket socket;
  final NotificationService _notificationService = NotificationService();

  void initSocket() {
    socket = IO.io('http://10.42.243.81:8000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.on('connect', (_) {
      print('Connected to WebSocket server');
    });

    socket.on('medicine_reminder', (data) {
      _notificationService.showNotification(
        data['title'],
        data['body'],
      );
    });

    socket.connect();
  }
}