import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Volkswagen Travel & Navigation',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _vinController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String email = _emailController.text.trim();
    String vin = _vinController.text.trim();

    if (email.isEmpty || vin.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Please enter both email and VIN.';
      });
      return;
    }

    await Future.delayed(const Duration(seconds: 2));

    if (email == "akilan1@gmail.com" && vin == "1234567890") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid email or VIN. Please try again.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.blueAccent,
      end: Colors.purpleAccent,
    ).animate(_animationController);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Volkswagen Login')),
      body: AnimatedBuilder(
        animation : _colorAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_colorAnimation.value!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'Login to your Volkswagen account',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _vinController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle VIN',
                        border: OutlineInputBorder(),
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Log In'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.blueAccent,
                      ),
                    ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isJourneyStarted = false;
  String? _fromValue;
  String? _toValue;
  final _dateController = TextEditingController();
  final List<Map<String, String>> _journeyList = [];
  int _newsClickCount = 0; // Counter for news icon clicks

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 3) { // News icon tapped
      _showNewsNotification();
    }
  }

  void _onJourneyPressed() {
    setState(() {
      _isJourneyStarted = !_isJourneyStarted; // Toggle the journey section
    });
  }

  void _onCustomizeCarPressed() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Car Customization'),
        content: Text('Customize your car features here.'),
      ),
    );
  }

  void _onAboutPressed() {
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('About Volkswagen'),
        content: Text('Learn more about Volkswagen here.'),
      ),
    );
  }

  void _addJourney() {
    if (_fromValue != null && _toValue != null && _dateController.text.isNotEmpty) {
      setState(() {
        _journeyList.add({
          'from': _fromValue!,
          'to': _toValue!,
          'date': _dateController.text,
        });
        _fromValue = null;
        _toValue = null;
        _dateController.clear();
        _isJourneyStarted = false; // Optionally close the journey section
      });
      // Redirect to MapPage after adding journey
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapPage()),
      );
    }
  }

  void _showNewsNotification() {
    _newsClickCount++; // Increment the click count
    String message;

    if (_newsClickCount == 1) {
      message = "There is a high rain in Madurai";
    } else if (_newsClickCount == 2) {
      message = "There is a flood in Chennai";
      _newsClickCount = 0; // Reset the counter after the second click
    } else {
      return; // Ignore further clicks
    }

    // Show the notification
    DelightToastBar(
      builder: (context) {
        return ToastCard(
          leading: Icon(
            Icons.add_alert,
            size: 32,
          ),
          title: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        );
      },
      position: DelightSnackbarPosition.top,
      autoDismiss: true, // Enables automatic dismissal
      snackbarDuration: Duration(seconds: 4), // Duration before it disappears
    ).show(context);
  }

  void _showChatbot() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chatbot'),
        content: Chatbot(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Volkswagen App Home')),
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/nextcar.png'), // Path to your image
              fit: BoxFit.cover, // This will cover the entire background
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                SizedBox(width:150,
                    child: FloatingActionButton(
                  onPressed: _onJourneyPressed,
                  child: const Icon(Icons.directions_car),
                  backgroundColor: Colors.grey,
                ),
                ),
                const SizedBox(height: 20),
                SizedBox(width:150,
                child: FloatingActionButton(
                  onPressed: _onCustomizeCarPressed,
                  child: const Icon(Icons.build),
                  backgroundColor: Colors.grey,
                  ),
                  ),
                const SizedBox(height: 20),
                SizedBox(width:150,
                    child: FloatingActionButton(
                  onPressed: _onAboutPressed,
                  child: const Icon(Icons.info),
                  backgroundColor: Colors.grey,
                ),
                ),
                if (_isJourneyStarted) ...[
                  const SizedBox(height: 40),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Your Journey',
                        style: TextStyle(fontSize: 20),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _fromValue = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'From',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _toValue = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'To',
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _addJourney();
                        },
                        child: const Text('Add Journey'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            _onItemTapped(index);
            if (index == 2) {
              _showChatbot(); // Show chatbot when Help & Support is tapped
            }
          },
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black,
          selectedLabelStyle: const TextStyle(color: Colors.black),
          unselectedLabelStyle: const TextStyle(color: Colors.black),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help),
              label: 'Help & Support',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper),
              label: 'News',
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == 1
        ? FloatingActionButton(
        onPressed: () {
      // Show the dashboard with journey details
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Journey Dashboard'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: _journeyList.length,
              itemBuilder: (context, index) {
                final journey = _journeyList[index];
                return ListTile(
                  title: Text('${journey['from']} to ${journey['to']}'),
                  subtitle: Text('Date: ${journey['date']}'),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    },
    child: const Icon(Icons.dashboard),
    )
    : null,
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? mapController;
  LatLng? currentPosition;
  LatLng? destinationPosition;
  Set<Marker> markers = {};
  final TextEditingController latController = TextEditingController();
  final TextEditingController lngController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      currentPosition = LatLng(position.latitude, position.longitude);
      markers.add(Marker(
        markerId: MarkerId('currentLocation'),
        position: currentPosition!,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    });
    print('Current Location: $currentPosition');
  }

  void _setDestination() {
    if (latController.text.isEmpty || lngController.text.isEmpty) {
      _showErrorDialog("Please enter both latitude and longitude.");
      return;
    }

    try {
      double lat = double.parse(latController.text);
      double lng = double.parse(lngController.text);

      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        _showErrorDialog("Please enter valid latitude and longitude values.\nLatitude must be between -90 and 90.\nLongitude must be between -180 and 180.");
        return;
      }

      setState(() {
        destinationPosition = LatLng(lat, lng);
        markers.add(Marker(
          markerId: MarkerId('destination'),
          position: destinationPosition!,
          infoWindow: const InfoWindow(title: 'Destination'),
        ));
        mapController?.animateCamera(
          CameraUpdate.newLatLng(destinationPosition!),
        );
      });
      print('Destination Location: $destinationPosition');
    } catch (e) {
      _showErrorDialog("Invalid input. Please enter valid numeric values for latitude and longitude.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map Page')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: currentPosition ?? LatLng(0, 0),
                zoom: 12.0,
              ),
              markers: markers,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
              TextField(
              controller: latController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Latitude',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lngController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter Longitude',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _setDestination,
                child: const Text('Set Destination'),
          ),
        ],
      ),
    ),
    ],
    ),
    );
  }
}

class Chatbot extends StatefulWidget {
  @override
  _ChatbotState createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot> {
  final TextEditingController _messageController = TextEditingController();
  List<String> _messages = [];
  Map<String, dynamic> _carData = {};
  Map<String, String> _responses = {
    "hi": "Hello sir!",
    "do i claim any warrenty": "Yes sir, please give us your registration number",
    // Add more responses here
  };

  @override
  void initState() {
    super.initState();
    _loadCarData();
  }

  Future<void> _loadCarData() async {
    String jsonString = await rootBundle.loadString('assets/volkswagen_data.json');
    setState(() {
      _carData = json.decode(jsonString);
    });
  }

  void _sendMessage() {
    String message = _messageController.text.trim().toLowerCase();
    if (message.isNotEmpty) {
      setState(() {
        _messages.add("You: $message");
        _messageController.clear();
        _respondToMessage(message);
      });
    }
  }

  void _respondToMessage(String message) {
    String response;
    if (_responses.containsKey(message)) {
      response = _responses[message]!;
    } else {
      response = "I'm sorry, I don't have information on that.";
      for (var car in _carData['cars']) {
        if (message.contains(car['model'].toLowerCase())) {
          response = "${car['model']} (${car['year']}): ${car['description']} - Engine: ${car['engine']}, Power: ${car['power']}";
          break;
        }
      }
    }
    setState(() {
      _messages.add("Chatbot: $response");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Text(
                  _messages[index],
                  style: TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[900],
                      labelText: 'Type your message...',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}