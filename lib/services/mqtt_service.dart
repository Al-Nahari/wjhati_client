import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  final String server = 'nahari-m1qoxs.a03.euc1.aws.hivemq.cloud';
  final int port = 8883;
  final String clientId = 'flutter_modern_ui_client';
  final String username = 'hivemq.client.1740007217404';
  final String password = 'N@VG3:C7dBh#Qgze0<j5';

  late MqttServerClient client;
  final Function(String message) onMessageReceived;

  MqttService({required this.onMessageReceived}) {
    client = MqttServerClient.withPort(server, clientId, port)
      ..secure = true
      ..keepAlivePeriod = 20
      ..logging(on: true)
      ..onConnected = _onConnected
      ..onDisconnected = _onDisconnected
      ..onSubscribed = _onSubscribed;
  }

  Future<void> connect() async {
    try {
      client.connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .startClean()
          .withWillQos(MqttQos.atMostOnce);
      await client.connect();
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        print('✅ تم الاتصال بـ MQTT Broker');
      } else {
        print('❌ فشل الاتصال: ${client.connectionStatus}');
        disconnect();
      }
    } catch (e) {
      print('❌ خطأ أثناء الاتصال: $e');
      disconnect();
    }
  }

  void disconnect() {
    client.disconnect();
    print('❌ تم قطع الاتصال');
  }

  void _onConnected() {
    print('✅ تم الاتصال بنجاح');
  }

  void _onDisconnected() {
    print('❌ تم قطع الاتصال');
  }

  void _onSubscribed(String topic) {
    print('✅ تم الاشتراك في الموضوع: $topic');
  }

  void subscribeToTopic(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> events) {
      final recMess = events[0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('📩 رسالة جديدة من $topic: $pt');
      onMessageReceived(pt);
    });
  }

  void publishMessage(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print('📤 تم إرسال: $message إلى $topic');
  }
}
