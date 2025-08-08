import 'package:flutter/material.dart';

class FundJoinSuccess extends StatefulWidget{
  const FundJoinSuccess({super.key});

  @override
  State<StatefulWidget> createState() => FundJoinSuccessState();
}

class FundJoinSuccessState extends State<FundJoinSuccess> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('펀드 가입'),
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back)),
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                  child:
                  Container(

                  ),
              )
            ],
          ),
      ),
    );
  }
}


void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FundJoinSuccess(),
  ));
}