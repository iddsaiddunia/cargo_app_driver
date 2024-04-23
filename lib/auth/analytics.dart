import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<_SalesData> data = [
    _SalesData('Jan', 35),
    _SalesData('Feb', 28),
    _SalesData('Mar', 34),
    _SalesData('Apr', 32),
    _SalesData('May', 40),
    _SalesData('july', 40),
    _SalesData('Aug', 100),
    _SalesData('Sep', 700),
    _SalesData('Oct', 1000),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height/2.7,
          color: Colors.blue,
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0,horizontal: 20),
            child: ListView(
              children: [
              Container(
                width: double.infinity,
                height: 100,
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Total Earnings",style: TextStyle(fontSize: 18),),
                    Text("5,000,000 Tsh",style: TextStyle(fontSize: 28,fontWeight: FontWeight.w600),)
                  ],
                ),
              ),
                SizedBox(height: 20,),
                Container(
                width: double.infinity,
              height: MediaQuery.of(context).size.height/2.3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(7)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12
                        ,
                        blurRadius: 1.0,
                        spreadRadius: 1.0,
                      ),
                    ],

                ),
                  child: Column(children: [
                    // Container(
                    //   width: double.infinity,
                    //   height: 65,
                    //   color: Colors.white,
                    // ),
                    SizedBox(
                      // height: 500.0,
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              //Initialize the chart widget
                              SfCartesianChart(
                                  primaryXAxis: CategoryAxis(),
                                  // Chart title
                                  title: ChartTitle(text: 'Yearly sales analysis'),
                                  // Enable legend
                                  legend: Legend(isVisible: true),
                                  // Enable tooltip
                                  tooltipBehavior: TooltipBehavior(enable: true),
                                  series: <CartesianSeries<_SalesData, String>>[
                                    LineSeries<_SalesData, String>(
                                        dataSource: data,
                                        xValueMapper: (_SalesData sales, _) => sales.year,
                                        yValueMapper: (_SalesData sales, _) => sales.sales,
                                        name: 'Sales',
                                        // Enable data label
                                        dataLabelSettings:
                                        DataLabelSettings(isVisible: true))
                                  ]),
                              // Expanded(
                              //   child: Padding(
                              //     padding: const EdgeInsets.all(8.0),
                              //     //Initialize the spark charts widget
                              //     child: SfSparkLineChart.custom(
                              //       //Enable the trackball
                              //       trackball: SparkChartTrackball(
                              //           activationMode: SparkChartActivationMode.tap),
                              //       //Enable marker
                              //       marker: SparkChartMarker(
                              //           displayMode: SparkChartMarkerDisplayMode.all),
                              //       //Enable data label
                              //       labelDisplayMode: SparkChartLabelDisplayMode.all,
                              //       xValueMapper: (int index) => data[index].year,
                              //       yValueMapper: (int index) => data[index].sales,
                              //       dataCount: 5,
                              //     ),
                              //   ),
                              // )
                            ],
                          ),),
                    ),
                  ],),
              ),
                SizedBox(height: 15,),
                Container(
                  // width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(7)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12
                        ,
                        blurRadius: 1.0,
                        spreadRadius: 1.0,
                      ),
                    ],

                  ),
                )
            ],),
          ),
        )
      ],),
    );
  }
}

class _SalesData {
  _SalesData(this.year, this.sales);

  final String year;
  final double sales;
}
