import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unsplash_row/utils/constants.dart';

void showNetworkErrorDailog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text("Connectivity Issue"), Icon(Icons.wifi_off_outlined)],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Once you have stronger internet connection, we'll automatically show you stuffs.",
              style: TextStyle(fontSize: 14.0)),
          SizedBox(
            height: 16.0,
          ),
          SizedBox(
            width: double.maxFinite,
            child: RaisedButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: Text(
                  "Close this Application",
                  style: TextStyle(color: Colors.white),
                ),
                color: AppColors.black,
                elevation: 10.0),
          )
        ],
      ),
    ),
  );
}
