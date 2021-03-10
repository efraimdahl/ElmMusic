module Effect exposing(..)

import Browser
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Html.Events

import SingleSlider exposing (..)
import Bootstrap.Table as Table

type alias Effect =
  { parameters :List (SingleSlider.SingleSlider Message)
  , parameterNum : Int
  , paramNames : List String
  , effecting : String
  , parameterMinMax: List (Float,Float)
  , parameterSettings: List (Float,Float)
  }

type Message
  = SliderChange String String Float

buildSliders: String-> List String ->List (Float,Float)->List (Float,Float) -> List (SingleSlider.SingleSlider Message)
buildSliders fxName lst values settings =
  case (lst,values,settings) of
    ([],[],[]) -> []
    (hd::tail,val::rest,setting::moreSettings)->
      let
        minFormatter = \value -> ""
        valueFormatter = \value not_used_value ->hd++": " ++ (String.fromFloat value)
        maxFormatter = \value -> ""
        slider:SingleSlider.SingleSlider Message
        slider =
          SingleSlider.init
            { min = Tuple.first val
            , max = Tuple.second val
            , value = Tuple.first setting
            , step = Tuple.second setting
            , onChange = SliderChange (fxName) hd
            }
            |> SingleSlider.withMinFormatter minFormatter
            |> SingleSlider.withValueFormatter valueFormatter
            |> SingleSlider.withMaxFormatter maxFormatter
      in
      slider::(buildSliders fxName tail rest moreSettings)
    _ -> Debug.todo("Error in initiating effect "++fxName)
  

init : String -> Int-> List String ->List (Float,Float) -> List (Float, Float)-> Effect
init str num parameterString parameterMinMax parameterSettings=
  {parameters=(buildSliders str parameterString parameterMinMax parameterSettings)
  ,effecting = str
  ,parameterNum = num
  ,paramNames = parameterString
  ,parameterMinMax = parameterMinMax
  ,parameterSettings= parameterSettings
  }

changeParam: String->Float->List String -> List (SingleSlider.SingleSlider Message) -> List (SingleSlider.SingleSlider Message) 
changeParam name val paramNames sliders = 
  case (paramNames,sliders) of 
  ([],[])->[]
  (p::pNames,slider::rest)->
    let 
      i = Debug.log "ELM Names " name ++ (Debug.toString val)
    in
    if (p==name) then (SingleSlider.update val slider)::(changeParam name val pNames rest)
    else slider::(changeParam name val pNames rest)
  _ -> Debug.todo("Invalid Prameter Matchup for "++name)

getChangedName: Message -> String
getChangedName msg = 
  case msg of 
    SliderChange name _ _ -> name
  
update : Message -> Effect -> (Effect,String)
update msg env =
  case msg of
    SliderChange name typ val ->
      let
        newList : List (SingleSlider.SingleSlider Message)
        newList = changeParam typ val env.paramNames env.parameters 
        newModel : Effect 
        newModel = {env | parameters = newList}
        message : String
        message = name++"-"++typ++"-"++Debug.toString(val)
      in
      ( newModel
      , message )

sliderView : SingleSlider.SingleSlider Message -> Html Message
sliderView slider =
  div [] [ SingleSlider.view slider]


view : Effect -> Html Message
view env = div []
        <| List.map sliderView env.parameters
