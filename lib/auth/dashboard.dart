import 'package:cargo_app_driver/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late GoogleMapController _controller;
  bool isOnline = true;
  bool isRequestAccepted = false;
  bool _isLoading = false;
  bool isDismissed = false;
  bool isRequestCanceled =false;

  void acceptRequest() async {
    _isLoading = true;
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      isRequestAccepted = true;
      _isLoading = false;
    });
  }

  Future<void> cancelClientRequest()async{
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay

    if(isDismissed == true){
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Verify Request action'),
            content: Text('Are you sure you want to cancel this request?'),
            actions: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    isRequestCanceled = true;
                    Navigator.of(context).pop();
                  });
                },
                child: Container(
                  width: 80.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text("Yes",style: TextStyle(color: Colors.white),)
                  ),
                ),
              ),GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();

                },
                child: Container(
                  width: 80.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Center(
                    child: Text("No",style: TextStyle(color: Colors.white),)
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(6.0),
          child: CircleAvatar(
            radius: 7,
          ),
        ),
        actions: [
          (isOnline) ? Text("Online") : Text("Offline"),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Switch(
              value: isOnline,
              onChanged: (value) {
                setState(() {
                  // Update the state of the switch
                  isOnline = value;
                });
              },
              // Optional: Customize the switch appearance
              activeColor: Colors.blue,
              inactiveThumbColor: Colors.grey,
              inactiveTrackColor: Colors.grey.shade300,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications,
              color: Colors.black45,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            // height: MediaQuery.of(context).size.height / 1.3,
            // color: Colors.red,
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: const CameraPosition(
                target: LatLng(37.7749, -122.4194), // San Francisco coordinates
                zoom: 12.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
              child: Container(
                width: double.infinity,
                height: 230,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(10)),
                    border: Border.all(width: 1, color: Colors.black26)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Allen Swai",
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    "Client",
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                        (isRequestAccepted)
                            ? Container(
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(35),
                                  ),
                                  color: Colors.blue,
                                ),
                                child: Icon(
                                  Icons.phone,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              )
                            : Container(),

                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    (!isRequestAccepted)
                        ? CustomePrimaryButton(
                            title: "Accept Request",
                            press: () {
                              acceptRequest();
                            },
                            isWithOnlyBorder: false,
                            isLoading: _isLoading)
                        : CustomePrimaryButton(
                            title: "Confirm Pickup",
                            press: () {},
                            isWithOnlyBorder: false,
                            isLoading: false),
                    SizedBox(height: 5,),
                    Center(
                      child: isRequestCanceled
                          ? Text(
                        'Request Canceled',
                        style: TextStyle(fontSize: 18, color: Colors.red),
                      )
                          : Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.horizontal,
                        onDismissed: (direction) {
                          // Handle the dismissal action
                          setState(() {
                            isDismissed = true;
                            cancelClientRequest();
                          });

                          // Show a snack bar as feedback for the action
                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(
                          //     content: Text('Dismissed!'),
                          //     duration: Duration(seconds: 2),
                          //   ),
                          // );
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          child: Text(
                            'Swipe to cancel!',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        // Customize the background and secondaryBackground
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(
                            Icons.cancel,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        secondaryBackground: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(
                            Icons.cancel,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
