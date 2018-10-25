
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:side_header_list_view/side_header_list_view.dart';

import 'package:recipe/database/database.dart';
import 'package:recipe/interface/GoogleColors.dart';
import 'package:recipe/model/Recipes.dart';
import 'package:recipe/recipe/recipeDetails.dart';


Future<List<Recipes>> fetchRecipes() async{
  var dbHelper = DBHelper();
  Future<List<Recipes>> recipes = dbHelper.getRecipes();
  return recipes;
}


class Lists extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _List();
  }
}

class _List extends State<Lists>{
  DBHelper db = new DBHelper();
  GoogleMaterialColors colors = new GoogleMaterialColors();
  Random random = new Random(); 
  Color usedColor; 

  @override
    void initState() {
      super.initState();
    }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Container(
        alignment: Alignment.topCenter,
        padding: new EdgeInsets.only(bottom: 16.0, right: 16.0, left: 16.0, top: 0.0),
        child: new FutureBuilder<List<Recipes>>(
          future: fetchRecipes(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              setState(() {});
              return new Text("Zurzeit sind keine Daten vorhanden.");
            }
            else if (snapshot.hasData) {
              return new SideHeaderListView(
                hasSameHeader: (int a, int b){
                  String first = snapshot.data[a].name[0].toUpperCase()..substring(1);
                  String second = snapshot.data[b].name[0].toUpperCase()..substring(1);
                  return first == second;
                },
                itemCount: snapshot.data.length,
                headerBuilder: (BuildContext context, int index){
                  return new Padding(
                    padding: EdgeInsets.only(top: 25.0, right: 35.0),
                    child: Text(
                      snapshot.data[index].name[0],
                      style: TextStyle(
                        color: Color(0xFF0F9D58),                        
                        fontFamily: "Google-Sans",
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  );
                },
                itemExtend: 70.0,
                itemBuilder: (BuildContext context, int index){
                  
                  String stringColor = snapshot.data[index].backgroundColor;
                  String valueString = stringColor.split('(0x')[1].split(')')[0];
                  int value = int.parse(valueString, radix: 16);
                  Color usedColor = new Color(value);

                  int favoriteDB = snapshot.data[index].favorite;
                  bool favorite;
                  if(favoriteDB == 0) favorite = false;
                  else if(favoriteDB == 1) favorite = true;
                  print("Favorite "+favorite.toString());

                  return Container(
                    child: Row(
                          children: <Widget>[
                            CircleAvatar(
                              child: Text(
                                snapshot.data[index].name[0].toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21.0,
                                  fontWeight: FontWeight.w400
                                ),
                              ),
                              backgroundColor: usedColor.withOpacity(0.85)
                            ),
                            InkWell(
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: ()=>Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => RecipeDetails("${snapshot.data[index].name}"))
                              ),
                              child: Padding(
                                padding: EdgeInsets.only(top: 25.0, left: 17.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      "${snapshot.data[index].name}",
                                      style: TextStyle(
                                        fontSize: 15.0,
                                        fontFamily: "Google-Sans",
                                        color: Colors.black
                                      ),
                                    ),                                    
                                  ],
                                ),
                              ),
                            )
                          ],
                      ),
                  );
                },
              );
            }
            return new Container(alignment: AlignmentDirectional.center,child: new CircularProgressIndicator(),);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF0F9D58),
        elevation: 4.0,
        child: Icon(Icons.add),
        onPressed: (){
          Navigator.pushNamed(context, '/add_recipe');
        },
      )
    );
  }

  void showBottomSnack(String value, ToastGravity toastGravity){
    Fluttertoast.showToast(
      msg: value,
      toastLength: Toast.LENGTH_SHORT,
      gravity: toastGravity,
      timeInSecForIos: 2,            
    );
  }
}