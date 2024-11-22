module Main exposing (..)
import Browser exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http exposing (..)
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode exposing (..)
import Maybe exposing (withDefault)
import Time as Time exposing (..)
import Random as Random exposing (..)
import Array as Array exposing (..)



oneToX : Array a -> Random.Generator Int 
oneToX a = Random.int 1 (Array.length a)

pathToMyImage : String -> (Html Msg)
pathToMyImage path = img
         [src path
         ,style "border-radius" "4px"
         ,style "border" "1px solid #ddd"
         ,style "height"  "80px"
         ,style "width"    "80px"
         ,style "margin" "0 auto"
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
           ,switchImage : Maybe Int
           } 
initialModel =  
             {failure = False
             ,loading = False 
             ,textInput = {boolExpr = ""}
             ,success  = Nothing 
             ,switchImage = Just 1
             }
type alias ServerResponse = 
      { parseError : String 
      , evaluation : String 
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

update : Msg -> Model -> (Model, Cmd Msg)
update msg model = 
   case msg of 
    Post -> ({model | loading = True}, postRequest model.textInput)
    (GotResult result) -> case result of 
                            Ok r -> ({model | success = Just r , loading = False}, Cmd.none)
                            (Err _) ->  ({model | failure = True ,loading = False}, Cmd.none)
    (TextInput s)      -> ({model | textInput = {boolExpr = s }}, Cmd.none)
    (Operator c)       -> ({model | textInput = {boolExpr = model.textInput.boolExpr ++ (String.fromChar c)}}, Cmd.none)
    (Erase st)         -> case st of 
                           "backspace" -> ({model | textInput = {boolExpr = String.dropRight 1 model.textInput.boolExpr}}, Cmd.none)
                           "delete"    -> ({model | textInput = {boolExpr = ""}},Cmd.none)
                           _           -> (model, Cmd.none)
    (Symbol sy)            -> ({model | textInput = {boolExpr = model.textInput.boolExpr ++ (String.fromChar sy)}}, Cmd.none)
    (NewImage)           -> (model, Random.generate ImageNumber (oneToX myImages))
    (ImageNumber i)      -> ({model | switchImage = Just i}, Cmd.none)
        


subscriptions : Model -> Sub Msg 
subscriptions model = Time.every (15 * 1000) (\_ -> NewImage) 

myHeader : Html Msg 
myHeader = 
    Html.header 
    [id "title"
    ,style "text-align" "center"
    ,style "color" "black"
    ] 
    [ h2 
       [ style "text-align" "center"
       ,style "color" "black"
       ] 
     [text "Logic Calcluator"] 
    ]
view : Model -> Html Msg 
view model = 
  div []
  [ myHeader
  ,div 
    [id "div1"
    ,style "padding" "0 auto"
    ,style "max-width" "600px"
    ,style "margin" "0 auto" -- Center
    ,style "background-color" "#332"
    ] 
    [ viewServerResponse model 
    ]
  
  
  , case model.switchImage of
     Nothing  -> text ""
     (Just i) -> case Array.get (i - 1) myImages of 
                  Nothing  -> text ""
                  (Just im) -> im
  ]
calculator : Model -> Html Msg 
calculator m = 
            div 
            [id "calculator"
            ,style "background-color" "#333"
            ,style "padding" "20px"
            ,style "border-raidus" "20px" --rounded corners
            ,style "box-shadow" "0 4px 8px rgba(0,0,0,0.2)"
            ]
            [
             div 
             [id "display"]
             [ourTextArea m]
            ,div 
             [id "button grid"
             ,style "display" "grid"
             ,style "grid-template-columns" "auto auto auto auto"
             ,style "gap" "10px"
             ]
             [button [onClick <| (Operator 'T')]   [text "T"]
             ,button [onClick <| (Operator 'F')]   [text "F"]
             ,button [onClick <| (Operator notChar)] [text "\u{00AC}"]
             ,button [onClick <| (Operator and)] [text "\u{2227}"]
             ,button [onClick <| (Operator or)] [text "\u{2228}"] 
             ,button [onClick <| (Operator ifThen)] [text "\u{2192}"] 
             ,button [onClick <| (Operator iff)] [text "\u{2194}"]
             ,button [onClick <| (Symbol '(')] [text "("]
             ,button [onClick <| (Symbol ')')] [text ")"]
             ,button [onClick <| (Erase "backspace")] [text "backspace"]
             ,button [onClick <| (Erase "delete")]    [text "delete"]
             ,button [onClick <| (Symbol ' ')] [text "_______________"]
             , button 
                [onClick Post
                ,style "background-color" "blue"
                ,style "color" "white"
                ,style "border" "none"
                ] 
                [text "Enter"]
            ]
            ]

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

ourTextArea : Model -> Html Msg 
ourTextArea model = 
              div 
              [id "div2"
              ,style "background-color" "lightgray"
              ,style "padding" "16px"
              ]
              [ div
                [ onInput TextInput
                , title "Enter Expression Here"
                , style "width" "100%"
                , style "padding" "10px"
                , style "height" "100px"
                ]
                [i [style "color" "black"] [text model.textInput.boolExpr]
                , br [] []
                , br [] []
                ,case model.success of 
                  Nothing -> text ""
                  (Just r)-> case r.evaluation of 
                              "Nothing" -> text r.parseError
                              _         -> text r.evaluation
                ]
              ]   
      
viewServerResponse : Model -> Html Msg 
viewServerResponse model = 
   case model.success of 
    Nothing -> div 
               [style "color" "white"]
               [case model.loading of 
                 True  -> text "Loading"
                 False -> text ""
               ,calculator model
               ]
    (Just s) -> case s.evaluation of 
                 "Nothing" -> div 
                              [style "color" "white"]
                              [ case model.loading of 
                                 True -> text "Loading"
                                 False -> text ""
                              ,calculator model
                              ]
                 _         -> div 
                              [style "color" "white"]
                              [case model.loading of 
                                True  -> text "Loading"
                                False -> text ""
                              ,calculator model
                              ]
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
  Decode.map2 ServerResponse
   (field "parseError" Decode.string)
   (field "evaluation" Decode.string)