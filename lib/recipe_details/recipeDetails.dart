import 'dart:async';

import 'package:TimeEater/DialogInterfaces/Dialogs.dart';
import 'package:TimeEater/Export_Import/RecipeToJson.dart';
import 'package:TimeEater/customizedWidgets/RadialMinutes.dart';
import 'package:TimeEater/databaseModel/Recipe_Shopping.dart';
import 'package:TimeEater/databaseModel/Shopping.dart';
import 'package:TimeEater/databaseModel/Shopping_Title.dart';
import 'package:TimeEater/recipe_details/cooking.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../customizedWidgets/Colors.dart';
import '../customizedWidgets/HexToColor.dart';
import '../databaseModel/Ingredients.dart';
import '../databaseModel/Recipes.dart';
import '../recipe/new_recipe.dart';


class RecipeDetails extends StatefulWidget{
  final String recipeName;
  RecipeDetails(this.recipeName);

  @override
    State<StatefulWidget> createState() {
      return new _RecipeDetails();
    }
}

class _RecipeDetails extends State<RecipeDetails> with TickerProviderStateMixin{
  MaterialColors googleMaterialColors = new MaterialColors();
  ConvertColor convertColor = new ConvertColor();
  ExportRecipe recipeToJson;

  //Appbar
  GlobalKey<State<PopupMenuButton>> _buttonKey = new GlobalKey<State<PopupMenuButton>>();

  //Allgemein
  int id;  
  String recipeName = "";
  String description;  
  int peopleDB;
  int currentPeople = 1;
  int favorite;
  String imagePath;
  Color backgroundColor;
  bool titleVisibility = false;  
  Duration preperation_duration;
  Duration creation_duration;
  Duration resting_duration;
  String timestamp;

  double preperation_percentage;
  double creation_percentage;
  double resting_percentage;

  //Zutaten
  List<double> numberList = new List();
  List<String> measureList = new List();
  List<String> nameList = new List();
  List<Widget> ingredients = new List();
  var sample;
  Color textColor = Colors.black;

  //Zubereitung
  List<String> stepsList = new List();

  int ingredientsLength = 0;
  int preperation_minutes;
  int creation_minutes;
  int resting_minutes;

  Widget titleImage;

  bool permissions = false;

  @override
    void initState() {
      super.initState();      
      recipeName = widget.recipeName;

      // Get all data of specific recipe
      getRecipeData();

      //Set ingredients height
      sample = fetchIngredients();
    }

    getRecipeData() async{
      var db = new DBHelper();
      List<Recipes> recipes = await db.getSpecRecipe(widget.recipeName);
      description = recipes[0].definition;
      preperation_duration = new Duration(minutes: int.parse(recipes[0].pre_duration));
      creation_duration = new Duration(minutes:  int.parse(recipes[0].cre_duration));
      resting_duration = new Duration(minutes: int.parse(recipes[0].resting_time));
      var people = recipes[0].people;
      if(people == null) peopleDB = 1;
      else peopleDB = int.parse(people);
      imagePath = recipes[0].image;
      favorite = recipes[0].favorite;
      timestamp = recipes[0].timestamp;


      backgroundColor = convertColor.convertToColor(recipes[0].backgroundColor);        

      setState(() {
        preperation_percentage = (preperation_duration.inMinutes / 60) * 100;
        preperation_minutes = preperation_duration.inMinutes;

        creation_percentage = (creation_duration.inMinutes / 60) *100;
        creation_minutes = creation_duration.inMinutes;

        resting_percentage = (resting_duration.inMinutes / 60)*100;
        resting_minutes = resting_duration.inMinutes;

        if(imagePath == "no image"){
          titleImage = CircleAvatar(
            backgroundColor: backgroundColor,
            child: Text(
                    recipeName[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "Google-Sans",
                      fontSize: 35.0,
                      fontWeight: FontWeight.w400
                    ),
                  ),
            maxRadius: 40.0,
          );
        } else {
          titleImage = Container(
            width: MediaQuery.of(context).size.width,
            height: 200.0,
            decoration: new BoxDecoration(
              image: new DecorationImage(
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              )
            ),
          );
        }
      });
    }

  @override
  Widget build(BuildContext context) {        
    return new Scaffold(
      appBar: AppBar(        
        actions: <Widget>[
          StatefulBuilder(
            builder: (context, update){
              return FutureBuilder(
                future: fetchRecipe(),
                builder: (BuildContext context, AsyncSnapshot snapshot){
                  if(snapshot.hasData){

                    favorite = snapshot.data[0].favorite;

                    return Row(
                      children: <Widget>[
                        IconButton(
                          icon: ( favorite == 0
                            ? Icon(Icons.star_border, color: Colors.black54)
                            : Icon(Icons.star, color: Colors.black54)
                          ),
                          onPressed: (){
                            update(() {
                              updateFavorite(favorite);
                            });
                          },
                        ),
                        PopupMenuButton(
                          key: _buttonKey,
                          icon: Icon(Icons.more_vert, color: Colors.black54),
                          itemBuilder: (_){
                            return <PopupMenuItem>[
                              PopupMenuItem(
                                child: Row(
                                  children: <Widget>[
                                    Icon(OMIcons.create, color: Colors.black54),
                                    Padding(
                                      padding: EdgeInsets.only(top: 3.0, bottom: 3.0, left: 10.0),
                                      child: Text("Bearbeiten"),
                                    )
                                  ],
                                ),
                                value: "bearbeiten",
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: <Widget>[
                                    SvgPicture.asset(
                                      "images/trash.svg",
                                      color: Colors.black54,
                                      height: 24.0,
                                      width: 24.0,
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(top: 3.0, bottom: 3.0, left: 10.0),
                                      child: Text("Löschen"),
                                    )
                                  ],
                                ),
                                value: "löschen",
                              ),
                              PopupMenuItem(
                                child: Row(
                                  children: <Widget>[
                                    Icon(OMIcons.share, color: Colors.black54),
                                    Padding(
                                      padding: EdgeInsets.only(top: 3.0, bottom: 3.0, left: 10.0),
                                      child: Text("Exportieren"),
                                    )
                                  ],
                                ),
                                value: "exportieren",
                              )
                            ];
                          },
                          onSelected: (value){
                            if(value == "löschen"){
                              deleteRecipe();
                            } else if(value == "bearbeiten"){
                              editRecipe();
                            } else if(value == "exportieren"){
                              recipeToJson = ExportRecipe();
                              recipeToJson.exportOneRecipe(recipeName, true, context);
                            }
                          },
                        )
                      ],
                    );
                  } else if(snapshot.hasError){

                    return Text("");
                  }
                  return Icon(Icons.check_box_outline_blank, color: Colors.black54);
                },
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0.0,        
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color:  Colors.black54),
          onPressed: (){
            Navigator.pop(context);
          },
        )
      ),
      body: ListView(
        children: <Widget>[
          titleImage,
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 15.0, left: 5.0),
                child: Container(
                  width: MediaQuery.of(context).size.width/1.05,
                  child: Text(
                    recipeName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Google-Sans",
                        fontSize: 30.0,
                        fontWeight: FontWeight.w300
                    ),
                  ),
                ),
              )
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 10.0, left: 15.0, right: 15.0, bottom: 5.0),
            child: Text(
              (description == "nothing"
                ? "Du hast diesem Rezept leider keine Beschreibung gegeben."
                : description
              ),
              style: TextStyle(
                color: Colors.black.withOpacity(0.3),
                fontFamily: "Google-Sans",
                fontSize: 14.0,
                fontWeight: FontWeight.w500
              ),
            ),
          ),
          Container(            
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.1)
                )                
              ),
            ),
            padding: EdgeInsets.only(top: 15.0),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 10.0, left: 20.0),
                child: Column(
                  children: <Widget>[
                    RadialMinutes(
                      completeColor: Colors.green[400],
                      lineColor: Colors.amber,
                      minutes: double.parse(creation_minutes.toString()),
                      radius: 65.0,
                      center:Text(
                        preperation_minutes.toString()+" Min.",
                        style: TextStyle(
                          fontFamily: "Google-Sans",
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500
                        ),
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Zubereitung",
                        style: TextStyle(
                          fontFamily: "Google-Sans",
                          fontSize: 14.0                        
                        ),                      
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0),
                child: Column(
                  children: <Widget>[
                    RadialMinutes(
                      completeColor: Colors.green[400],
                      lineColor: Colors.amber,
                      minutes: double.parse(creation_minutes.toString()),
                      radius: 65.0,
                      center:Text(
                        creation_minutes.toString()+" Min.",
                        style: TextStyle(
                          fontFamily: "Google-Sans",
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500
                        ),
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Koch-/Backzeit",
                        style: TextStyle(
                          fontFamily: "Google-Sans",
                          fontSize: 14.0                        
                        ),                      
                      ),
                    )
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 10.0, right: 30.0),
                child: Column(
                  children: <Widget>[
                    RadialMinutes(
                      completeColor: Colors.green[400],
                      lineColor: Colors.amber,
                      minutes: double.parse(resting_minutes.toString()),
                      radius: 65.0,
                      center:Text(
                        resting_minutes.toString()+" Min.",
                        style: TextStyle(
                          fontFamily: "Google-Sans",
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500
                        ),
                      )
                    ),
                    _radialText("Ruhezeit")
                  ],
                ),
              )
            ],
          ),
          Container(            
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withOpacity(0.1)
                )                
              ),
            ),
            padding: EdgeInsets.only(top: 15.0),
          ),
          StatefulBuilder(            
            builder: (context, update){
              return Column(
                children: <Widget>[
                  Row(            
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 15.0, left: 15.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black45),
                              borderRadius: BorderRadius.all(Radius.circular(5.0)),
                              shape: BoxShape.rectangle
                            ),
                            child: GestureDetector(
                              child: Padding(
                                padding: EdgeInsets.only(top: 2.0, bottom: 2.0, left: 10.0, right: 10.0),
                                child: Text(
                                  "$peopleDB",
                                  style: TextStyle(
                                    color: MaterialColors().primaryColor().withOpacity(0.9),
                                    fontSize: 15.0
                                  ),
                                ),
                              ),
                                onTap: (){
                                  _selectPortion(update);
                                },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 15.0, left: 5.0),
                        child: Text(
                          (peopleDB == 1
                            ? (peopleDB == 0.5
                              ? "Portion"
                              : "Portion"
                            )
                            : "Portionen"
                          )
                        ),
                      )              
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 15.0, top: 15.0),
                    child: FutureBuilder(
                      future: fetchIngredients(),
                      initialData: [],
                      builder: (BuildContext context, AsyncSnapshot snapshot){
                        if(snapshot.hasData){                            
                          return Column(                              
                            children: <Widget>[
                              Builder(
                                builder: (BuildContext context){
                                  List<Widget> items = new List();

                                  for (var i = 0; i < snapshot.data.length; i++) {

                                    double number = double.parse(snapshot.data[i].number);
                                    String measure = snapshot.data[i].measure;
                                    String name = snapshot.data[i].name;

                                    nameList.add(name);
                                    numberList.add(number);
                                    measureList.add(measure);

                                    items.add(
                                      Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Row(
                                          children: <Widget>[
                                            Text("${number*peopleDB} $measure"),
                                            Padding(
                                              padding: EdgeInsets.only(left: 12.0),
                                              child: Text("$name"),
                                            )
                                          ],
                                        ),
                                      )
                                    );
                                  }
                                  return Container(
                                    child: Column(
                                      children: items,
                                    ),
                                  );
                                },
                              ),
                              /*ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data.length,
                                itemBuilder: (BuildContext context, int index){
                                  double number = double.parse(snapshot.data[index].number);
                                  String measure = snapshot.data[index].measure;
                                  String name = snapshot.data[index].name;

                                  nameList.add(name);
                                  numberList.add(number);
                                  measureList.add(measure);

                                  return Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      children: <Widget>[
                                        Text("${number*peopleDB} $measure"),
                                        Padding(
                                          padding: EdgeInsets.only(left: 12.0),
                                          child: Text("$name"),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),*/
                              StatefulBuilder(
                                builder: (context, update){
                                  return GestureDetector(
                                    child: FlatButton(                        
                                      child: Text("Zur Einkaufsliste hinzufügen"),
                                      onPressed: () => saveShopping(),                        
                                      shape: new RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(5.0)),
                                        side: BorderSide(
                                          color: Colors.amber,
                                          width: 2.0
                                        )
                                      ), 
                                      splashColor: Colors.transparent,    
                                      highlightColor: Colors.amber,  
                                      textColor: textColor,
                                    ),
                                    onTapDown: (TapDownDetails details){
                                      update(() {
                                        textColor = Colors.white;
                                      });
                                    },
                                    onTapUp: (TapUpDetails details){
                                      update(() {
                                        textColor = Colors.black;
                                      });
                                    },
                                    onTapCancel: (){
                                      update(() {
                                        textColor = Colors.black;
                                      });
                                    },
                                  );
                                },
                              )
                            ],
                          );
                          
                        } else if(snapshot.hasError){
                          return new Text("Keine Daten vorhanden.");
                        }
                        return new CircularProgressIndicator();
                      },
                    ),
                  )
                ],
              );
            },
          )
        ],
        physics: AlwaysScrollableScrollPhysics(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: googleMaterialColors.primaryColor(),
        child: Icon(
          Icons.fastfood
        ),
        onPressed: (){
          print("Steps: $stepsList");
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (_) => StartCooking(steps: stepsList, recipe: recipeName,)
            )
          );
        },
        tooltip: "Jetzt kochen",
      ),
      
    );
  }

  _radialText(String value){
    return Padding(
      padding: EdgeInsets.only(top: 10.0),
      child: Text(
        "$value",
        style: TextStyle(
          fontFamily: "Google-Sans",
          fontSize: 14.0                        
        ),                      
      ),
    );
  }

  _selectPortion(StateSetter update) async{
    var portionen = await Dialogs().selectPortions(context, peopleDB);
    if(portionen != null){
      update(() {
        peopleDB = portionen;        
      });
    }
  }


  Future saveTitleShopping(int shoppingID, int titleID, DBHelper dbHelper) async{
    await dbHelper.create();

    ShoppingTitlesDB shoppingTitle = new ShoppingTitlesDB();
    shoppingTitle.idShopping = shoppingID;
    shoppingTitle.idTitles = titleID;

    shoppingTitle = await dbHelper.insertShoppingTitles(shoppingTitle);
  }

  Future saveRecShopping(int shoppingID, DBHelper dbHelper) async{
    await dbHelper.create();

    RecipeShopping recipeShopping = new RecipeShopping();
    recipeShopping.idShopping = shoppingID;
    recipeShopping.idRecipes = id;

    recipeShopping = await dbHelper.insertRecipeShopping(recipeShopping);
  }

  Future saveShopping() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();

    DBHelper dbHelper = new DBHelper();
    ShoppingDB shopping = new ShoppingDB();
    await dbHelper.create();

    int titleCount = await dbHelper.checkListTitle("");
    int titleID = await dbHelper.getTitleID(prefs.getString("currentList"));

    print("TitleCount: "+titleCount.toString());
    

    for (var i = 0; i < ingredientsLength; i++) {
      shopping.item = nameList[i];
      shopping.number = (numberList[i]*peopleDB).toString();
      shopping.checked = 0;
      shopping.measure = measureList[i];
      shopping.timestamp = DateTime.now().toString();
      
      shopping = await dbHelper.linkShoppingTitles(shopping, prefs.getString("currentList"));

      await saveRecShopping(shopping.id, dbHelper);
      await saveTitleShopping(shopping.id, titleID, dbHelper);
    }      
    showBottomSnack("Saved to $titleID: ${prefs.getString("currentList")}", ToastGravity.BOTTOM);
    
  }

  Future<List<Recipes>> fetchRecipe() async{
    DBHelper dbHelper = new DBHelper();
    var parsedRecipe = await dbHelper.getSpecRecipe(recipeName);
    List<Recipes> recipe = List<Recipes>();
    for(int i=0; i < parsedRecipe.length; i++){
      recipe.add(parsedRecipe[i]);
      id = recipe[i].id;
      description = recipe[i].definition;
      preperation_duration = new Duration(minutes: int.parse(recipe[i].pre_duration));
      creation_duration = new Duration(minutes: int.parse(recipe[i].cre_duration));
      resting_duration = new Duration(minutes: int.parse(recipe[i].resting_time));
      if(recipe[i].people == null) peopleDB = 1;
      else peopleDB = int.parse(recipe[i].people);
      imagePath = recipe[i].image;
      backgroundColor = convertColor.convertToColor(recipe[i].backgroundColor);      
    }    
    return recipe;
  }

  Future<int> updateFavorite(int favorite)async{
    if(favorite == 0) favorite = 1;
    else if(favorite == 1) favorite = 0;
    print("Updated favorite("+favorite.toString()+")");
    DBHelper dbHelper = new DBHelper();
    int updated = await dbHelper.updateFavorite(recipeName, favorite);
    return updated;
  }

  Future<List<Ingredients>> fetchIngredients() async{
    DBHelper dbHelper = new DBHelper();
    var parsedIngredients = await dbHelper.getIngredients(recipeName);
    List<Ingredients> ingredients = List<Ingredients>();    
    for(int i=0; i< parsedIngredients.length; i++){
      ingredients.add(parsedIngredients[i]);
    }    

    stepsList = await dbHelper.getStepDescription(recipeName);
    ingredientsLength = ingredients.length;
    print("StepsAnzahl: ${stepsList.length}");
    return ingredients;
  } 

  Future editRecipe() async{
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => new NewRecipe(
          recipeID: id,
          name: recipeName,
          description: description,
          preperation_duration: preperation_duration,
          creation_duration: creation_duration,
          resting_duration: resting_duration,
          backgroundColor: backgroundColor,
          imagePath: imagePath,
          numberList: numberList,
          measureList: measureList,
          nameList: nameList,
          stepsList: stepsList,
          personenAnzahl: peopleDB,
        )
      )
    );
  }

  deleteRecipe() async{
    var delete = await Dialogs().deleteRecipes(context, 1);
    FlutterLocalNotificationsPlugin notificationsPlugin = new FlutterLocalNotificationsPlugin();
    if(delete != null && delete != "abbrechen"){
      int recipeID = await DBHelper().getRecipeID(recipeName);
      await DBHelper().deleteRecipe(recipeName);
      await notificationsPlugin.cancel(recipeID);
      Navigator.pop(context);
      setState(() {
        showBottomSnack("$recipeName wurde gelöscht", ToastGravity.BOTTOM);
      });      
    }
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