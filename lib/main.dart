import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';

void main() {
  runApp(SmsFilterApp());
}

class SmsFilterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Filter App',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: Colors.black,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: SmsFilterScreen(),
    );
  }
}

class SmsFilterScreen extends StatefulWidget {
  @override
  _SmsFilterScreenState createState() => _SmsFilterScreenState();
}

class _SmsFilterScreenState extends State<SmsFilterScreen> {
  final Telephony telephony = Telephony.instance;
  List<SmsMessage> allMessages = [];
  List<SmsMessage> filteredMessages = [];
  final TextEditingController numberController = TextEditingController();

  // List of specific numbers you want to show
  final List<String> allowedNumbers = [
    'ComBankCard',
    'Airtel',
  ];

  @override
  void initState() {
    super.initState();
    requestPermissionAndLoadSms();
  }

  void requestPermissionAndLoadSms() async {
    bool? permissionGranted = await telephony.requestPhoneAndSmsPermissions;

    if (permissionGranted ?? false) {
      print("SMS permission granted!");
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
      setState(() {
        allMessages = messages;
        filteredMessages = messages.where((msg) {
          // Only include messages from allowed numbers
          return allowedNumbers.contains(msg.address);
        }).toList();
      });
    } else {
      print("SMS permission NOT granted.");
    }
  }

  void filterMessages(String input) {
    final query = input.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    setState(() {
      filteredMessages = allMessages.where((msg) {
        final address =
            msg.address?.toLowerCase().replaceAll(RegExp(r'\s+'), '') ?? '';
        return address.contains(query) && allowedNumbers.contains(msg.address);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages from Specific Numbers'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: numberController,
              decoration: InputDecoration(
                hintText: 'Enter number or name...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: filterMessages,
            ),
            SizedBox(height: 12),
            Expanded(
              child: filteredMessages.isEmpty
                  ? Center(
                child: Text(
                  "No messages found.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: filteredMessages.length,
                itemBuilder: (context, index) {
                  final msg = filteredMessages[index];
                  return Card(
                    color: Colors.grey[850],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(
                        msg.address ?? "Unknown",
                        style: TextStyle(color: Colors.lightBlueAccent),
                      ),
                      subtitle: Text(
                        msg.body ?? "",
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: Text(
                        DateTime.fromMillisecondsSinceEpoch(msg.date ?? 0)
                            .toLocal()
                            .toString()
                            .split('.')[0],
                        style: TextStyle(
                            color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
