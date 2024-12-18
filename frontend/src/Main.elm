module Main exposing (..)
import Browser exposing (..)
import Html exposing (..)
import Html.Attributes as Attr exposing (..)
import Html.Events exposing (..)
import Http exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Maybe exposing (withDefault)
import Time as Time exposing (..)
import Random as Random exposing (..)
import Array as Array exposing (..)
import Dict as D exposing (..)
import Svg as S exposing (..)
import Svg.Attributes as SA exposing (..)



oneToX : Array a -> Random.Generator Int 
oneToX a = Random.int 1 (Array.length a)



pathToMyImage : String -> (Html Msg)
pathToMyImage path = img
         [src path
         ,Attr.style "height"  "80px"
         ,Attr.style "width"    "80px"
         ,Attr.style "margin" "0 auto"
         ] 
         []

myImages : Array (Html Msg)
myImages =  Array.fromList
            [
              pathToMyImage "/images/rootBeerAvatar.png"
            , pathToMyImage "/images/jakeTheDog.jpg"
            , pathToMyImage "/images/marceline.png"
            , pathToMyImage "/images/bubblegum.png"
            , pathToMyImage "/images/fin.png"
            ]
main = 
  Browser.element 
    { init = init
    , update = update 
    , subscriptions = subscriptions
    , view = view
    }
type alias Model =  
           {failure : Bool  
           ,loading : Bool 
           ,textInput   : Request  
           ,success : Maybe ServerResponse 
           ,selectImage : Maybe Int
           ,soundNumber : Maybe Int 
           ,successfulExpression : String
           ,zerosAndOnes : Bool 
           } 
initialModel =  
             {failure = False
             ,loading = False 
             ,textInput = {boolExpr = ""}
             ,success  = Nothing 
             ,selectImage = Just 1
             ,soundNumber = Just 1 
             ,successfulExpression = ""
             ,zerosAndOnes = False
             }
type alias ServerResponse = 
      { parseError   : String 
      , evaluation   : String 
      , gatesAndOuts : List (String,Bool)
      }

init : () -> (Model, Cmd Msg)
init _ = 
  (initialModel, Cmd.none)

type Msg = Post 
         | GotResult (Result Http.Error ServerResponse)
         | TextInput String 
         | Operator Char 
         | Erase String 
         | Symbol Char
         | NewImage 
         | ImageNumber Int
         | IsChecked Bool

binaryify : String -> String 
binaryify s = case s of 
               "True"  -> "1" 
               "False" -> "0"
               _       -> ""
update : Msg -> Model -> (Model, Cmd Msg)
update msg model = 
   case msg of 
    Post -> ({model | loading = True}, postRequest model.textInput)
    (GotResult result) -> case result of 
                            Ok r -> ({model | success = Just r 
                                     , loading = False
                                     , successfulExpression = model.textInput.boolExpr ++ " = " ++ (if r.evaluation == "Nothing" then "" else if model.zerosAndOnes then binaryify r.evaluation else r.evaluation) 
                                     } 
                                     , Cmd.none
                                     )
                            (Err _) ->  ({model | failure = True ,loading = False}, Cmd.none)
    (TextInput s)      -> ({model | textInput = {boolExpr = s }}, Cmd.none)
    (Operator c)       -> ({model | textInput = {boolExpr = model.textInput.boolExpr ++ (String.fromChar c)}}, Cmd.none)
    (Erase st)         -> case st of 
                           "backspace" -> ({model | textInput = {boolExpr = String.dropRight 1 model.textInput.boolExpr}}, Cmd.none)
                           "delete"    -> ({model | textInput = {boolExpr = ""}
                                           , successfulExpression = ""
                                           }
                                           ,Cmd.none
                                           )
                           _           -> (model, Cmd.none)
    (Symbol sy)            -> ({model | textInput = {boolExpr = model.textInput.boolExpr ++ (String.fromChar sy)}}, Cmd.none)
    (NewImage)           -> (model, Random.generate ImageNumber (oneToX myImages))
    (ImageNumber i)      -> ({model | selectImage = Just i}, Cmd.none)
    (IsChecked b)        -> ({model | zerosAndOnes = not (model.zerosAndOnes)},Cmd.none)

        


subscriptions : Model -> Sub Msg 
subscriptions model = Time.every (15 * 1000) (\_ -> NewImage) 


header : Html Msg 
header = 
     h1 
     [ Attr.style "position" "absolute"
     , Attr.style "top" "0vh" 
     , Attr.style "width" "50vw"
     , Attr.style "height" "5vh"
     , Attr.style "right"  "50vw"
     , Attr.style "background-color" "#eed49f"
      
     ] 
     [i 
      [Attr.style "font-family" "Arial, Helvetica, sans-serif"] 
      [Html.text "Logic Calculator"]
     ] 

binaryBox : Html Msg 
binaryBox = 
    div 
    [Attr.style "position" "absolute"
    ,Attr.style "right" "0vw"
    ,Attr.style "height" "100px"
    ,Attr.style "width" "100px"
    ,Attr.style "background-color" "#a6e3a1"
    ,Attr.style "top" "0vh"
    ]
    [
    Html.input 
    [Attr.type_ "checkbox"
    ,onCheck <| IsChecked 
    ] 
    [Html.text "Switch Booleans to 1s and 0s "]
    ]
display : Model -> Html Msg 
display model = 
   div 
   [Attr.style "position" "absolute"
   ,Attr.style "background-color" "#c6a0f6" 
   ,Attr.style "height" "130px"
   ,Attr.style "width"  "330px"
   ,Attr.style "left" "39vw"
   ,Attr.style "top"  "30vh"
   ,Attr.style "border-style" "solid"
   ,Attr.style "font-size" "15 px"
   ]
   [ Html.text model.textInput.boolExpr
   , br [] []
   , Html.text model.successfulExpression 
   , case model.success of 
      Nothing -> Html.text ""
      (Just response) -> case response.evaluation of 
                          "Nothing" -> Html.text ""
                          _         -> Html.text ""
   ]
   
buttonGrid : Model -> Html Msg 
buttonGrid m = 
   div 
   [ Attr.style "position" "absolute"
   , Attr.style "top" "50vh"
   , Attr.style "left" "39vw"
   , Attr.style "width" "150px"
   , Attr.style "height" "200px"
   , Attr.style "display" "grid"
   , Attr.style "grid-template-columns" "repeat(4,75px)"
   , Attr.style "grid-template-rows"    "repeat(5,60px)"
   , Attr.style "gap" "10px" 
   ]
   [ button 
     [onClick <| if m.zerosAndOnes then Operator '1' else Operator 'T'
     ,Attr.style "background-color" "#a6e3a1"
     ] 
     [if m.zerosAndOnes then Html.text "1" else Html.text "T"]
   , button 
     [onClick <| if m.zerosAndOnes then Operator '0' else Operator 'F'
     ,Attr.style "background-color" "#f38ba8"
     ] 
     [if m.zerosAndOnes then Html.text "0" else Html.text "F"] 
   , button [onClick <| Operator '(', Attr.style "background-color" pink] [Html.text "("]
   , button [onClick <| Operator ')', Attr.style "background-color" sky] [Html.text ")"]
   , button [onClick <| Operator and, Attr.style "background-color" sapphire] [Html.text <| String.fromChar and]
   , button [onClick <| Operator or,Attr.style "background-color" sapphire] [Html.text <| String.fromChar or]
   , button [onClick <| Operator notChar,Attr.style "background-color" sapphire] [Html.text <| String.fromChar notChar]
   , button [onClick <| Operator ifThen,Attr.style "background-color" sapphire] [Html.text <| String.fromChar ifThen]
   , button [onClick <| Operator iff,Attr.style "background-color" sapphire] [Html.text <| String.fromChar iff]
   , button [onClick <| Operator nand,Attr.style "background-color" sapphire] [Html.text <| String.fromChar nand]
   , button [onClick <| Operator nor,Attr.style "background-color" sapphire] [Html.text <| String.fromChar nor]
   , button [onClick <| Operator xor,Attr.style "background-color" sapphire] [Html.text <| String.fromChar xor]
   , button [onClick <| Erase "backspace" , Attr.style "background-color" pink] [Html.text "← DELETE"]
   , button [onClick Post, Attr.style "background-color" sky] [Html.text "← ENTER"]  
   , button [onClick <| Erase "delete", Attr.style "background-color" pink] [Html.text "← ERASE"] 
   , button 
     [onClick <| Operator ' ', Attr.style "background-color" sky] 
     [Html.text "SPACE"]
    
   ]
   
{-
calculatorDisplay : Html Msg
calculatorDisplay = 
-}
sapphire : String 
sapphire = "#74c7ec"
pink : String 
pink = "#f5bde6"
sky : String 
sky = "#91d7e3"

view : Model -> Html Msg 
view model = 
     div 
     [ 
      Attr.style "width" "100vw"
     ,Attr.style "height" "100vh"
     ,Attr.style "background-color" "#f5a97f"
     ,Attr.style "position" "relative"
      
     ] 
     [ header
     , binaryBox 
     , display model
     , buttonGrid model 
     , myDivPicture model
     , case model.success of 
        Nothing -> Html.text ""
        (Just r) -> makeGates r.gatesAndOuts
     ]


makeGates : List (String, Bool) -> Html Msg 
makeGates l = 
    div
        [ Attr.style "position" "absolute"
        , Attr.style "bottom" "0"
        , Attr.style "left" "100%"
        , Attr.style "transform" "translateX(-100%)"
        ]
        (
            List.concat
                (List.map 
                    (\t -> 
                        [ Html.text <| fromBool (Tuple.second t)
                        , br [] []
                        , i [Attr.style "background-color" sky] [Html.text <| (if (Tuple.first t) == "wire" then "" else Tuple.first t)]
                        , br [] []
                        ]
                    ) 
                    l
                )
        )

myDivPicture : Model -> Html Msg
myDivPicture model = 
    div 
    [Attr.style "position" "relative"
    ,Attr.style "top" "10vh"
    ,Attr.style "left" "0"]
    [
      case selectPicture model of 
       Nothing          -> Html.text "Error cannot find image"
       (Just im)       -> im 
    ]
selectPicture : Model -> Maybe (Html Msg)
selectPicture model = 
     case model.selectImage of
        Nothing       -> Nothing
        (Just number) -> Array.get number myImages

ifThen : Char 
ifThen = '\u{2192}'
iff : Char
iff = '\u{2194}'
notChar : Char
notChar = '\u{00AC}'
and : Char
and = '\u{2227}'
or : Char 
or = '\u{2228}'
xor : Char 
xor = '\u{2295}'
nand = '\u{22BC}'
nor = '\u{22BD}'





{- 
     S.svg
     [SA.viewBox  "0 0 200 150"
     ,SA.width "400px"
     ,SA.height "400px"
     ]

-}

                        
fromBool  : Bool -> String 
fromBool b = case b of 
              True  -> "True"  
              False -> "False" 

      
postRequest : Request -> Cmd Msg 
postRequest request = 
   Http.post 
     {  url     = "/upload"
     ,  body    = jsonBody <| fromRequest<| request 
     ,  expect  = Http.expectJson GotResult resultDecoder
     }
type alias Request = 
          { boolExpr : String
          }

fromRequest : Request -> Encode.Value
fromRequest request =  
             Encode.object 
             [("booleanExpression", Encode.string request.boolExpr)]
 
    
resultDecoder : Decoder ServerResponse
resultDecoder = 
  Decode.map3 ServerResponse
   (field "parseError" Decode.string)
   (field "evaluation" Decode.string)
   (field "gatesAndOuts" gatesAndOutsDecoder)
gateAndOutDecoder : Decoder (String,Bool)
gateAndOutDecoder = 
    Decode.map2 Tuple.pair 
      (Decode.index 0 Decode.string)
      (Decode.index 1 Decode.bool)
gatesAndOutsDecoder : Decoder (List (String,Bool))
gatesAndOutsDecoder = 
    Decode.list gateAndOutDecoder