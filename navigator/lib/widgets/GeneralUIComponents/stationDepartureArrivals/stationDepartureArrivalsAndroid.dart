import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/widgets/GeneralUIComponents/lineChip/lineChip.dart';

class StationDepartureArrivalsAndroid extends StatelessWidget {
  final ValueChanged<String> onTripSelected; // This takes a trip id;
  final List<DepartureArrival> data;

  const StationDepartureArrivalsAndroid({super.key, required this.onTripSelected, required this.data});

  @override
  Widget build(BuildContext context) {
    if(data.isEmpty)
    {
      return Center(child: Text("No Arrivals/Departures for this station", style: Theme.of(context).textTheme.titleMedium));
    }
    return M3ECardList(
      itemCount: data.length, 
      itemBuilder: (context, index) {
        bool showLineChip = false;
        if(data[index].line != null)
        {
          showLineChip = true;
        }
        return Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                Icon(Icons.train),
                SizedBox(width: 8),
                if(showLineChip)
                LineChip(design: 0, lineName: data[index].line!.name, lineColor: Colors.grey, onLineColor: Colors.black,)
              ],),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                Text("Trip $index"),
                SizedBox(width: 8),
              ],)
            ]
          )); // Placeholder, replace with actual UI
      }) ;// Placeholder, replace with actual UI
  }
}