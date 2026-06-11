import 'package:flutter/material.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:navigator/models/departureArrival.dart';
import 'package:navigator/widgets/GeneralUIComponents/generalUiUtilities.dart';
import 'package:navigator/widgets/GeneralUIComponents/lineChip/lineChip.dart';
import 'package:navigator/widgets/GeneralUIComponents/stationDepartureArrivals/departureChip/departureChip.dart';

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
        Icon icon = Icon(Icons.directions_walk);
        if(data[index].line != null)
        {
          showLineChip = true;
          icon = GeneralUIUtilities().getIconFromLine(data[index].line!);
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                icon,
                SizedBox(width: 8),
                if(showLineChip)
                LineChip(
                  design: 0, 
                  lineName: data[index].line!.name, 
                  lineColor: Colors.grey, 
                  onLineColor: Colors.black,
                  ),
                SizedBox(width: 8,),
                if(data[index].direction != null)
                Flexible(child: Text(data[index].direction!, overflow: TextOverflow.ellipsis, maxLines: 5,))
              ],),
            ),
            SizedBox(width: 8,),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
              DepartureChip(
                design: 0, 
                newTime: data[index].when, 
                origTime: data[index].plannedWhen,
                newPlatform: data[index].platform,
                origPlatform: data[index].plannedPlatform,
                ),
              //Departure Chip
              if(data[index].remarks.isNotEmpty)
              IconButton(onPressed: (){}, icon: Icon(Icons.error))
            ],)
          ]
        );
      });
  }
}