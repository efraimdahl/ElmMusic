module Effect exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.ListGroup as ListGroup
import Browser
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick, onInput)
import SingleSlider exposing (..)


-- This file contains the implementation for an effect.
-- Currently, we support distortion, BitCrusher, Chebyshev,
-- frequency shifter, feedback delay, low-pass filter, and
-- high-pass filter.


-- parameters contains a list of sliders, that are adjustable
-- parameterNum is the number of parameters
-- paramNames is a list of the names of the parameters
-- effecting is the name of the effect
-- parameterMinMax contains the min/max values of each param
type alias Effect =
  { parameters : List (SingleSlider.SingleSlider Message)
  , parameterNum : Int
  , paramNames : List String
  , effecting : String
  , parameterMinMax : List ( Float, Float )
  , parameterSettings : List ( Float, Float )
  }


-- Allow a slider to be changed or for an effect to be removed
type Message
  = SliderChange String String Float
  | RemoveEffect String


isRmMessage : Message -> Bool
isRmMessage ms =
  case ms of
    RemoveEffect str ->
      True

    _ ->
      False


-- Helper function for effectToString
makeEffectString : String -> String -> Float -> String
makeEffectString effectName paramName val =
  "#changeFX+" ++ effectName ++ "+" ++ paramName ++ "+" ++ String.fromFloat val


-- Create a string that is sent to JS to load an effect
effectToString : Effect -> String
effectToString effect =
  let
    len =
      effect.parameterNum

    effectName =
      effect.effecting

    paramNames =
      effect.paramNames

    sliders =
      effect.parameters

    sliderValues =
      List.map fetchValue sliders
  in
  "#addFX+" ++ effectName ++ String.concat (List.map2 (makeEffectString effectName) paramNames sliderValues)


-- Send a message to Elm to change a slider
makeEffectMessage : String -> String -> Float -> Message
makeEffectMessage a b c =
  SliderChange a b c


-- Initialize the sliders
buildSliders : String -> List String -> List ( Float, Float ) -> List ( Float, Float ) -> List (SingleSlider.SingleSlider Message)
buildSliders fxName lst values settings =
  case ( lst, values, settings ) of
    ( [], [], [] ) ->
      []

    ( hd :: tail, val :: rest, setting :: moreSettings ) ->
      let
        minFormatter =
          \value -> ""

        valueFormatter =
          \value not_used_value -> hd ++ ": " ++ String.fromFloat value

        maxFormatter =
          \value -> ""

        slider : SingleSlider.SingleSlider Message
        slider =
          SingleSlider.init
            { min = Tuple.first val
            , max = Tuple.second val
            , value = Tuple.first setting
            , step = Tuple.second setting
            , onChange = SliderChange fxName hd
            }
            |> SingleSlider.withMinFormatter minFormatter
            |> SingleSlider.withValueFormatter valueFormatter
            |> SingleSlider.withMaxFormatter maxFormatter
      in
      slider :: buildSliders fxName tail rest moreSettings

    _ ->
      Debug.todo ("Error in initiating effect " ++ fxName)



-- Format the name, number of parameters, names of parameters,
-- range for each parameter, starting value and step size
init : String -> Int -> List String -> List ( Float, Float ) -> List ( Float, Float ) -> Effect
init str num parameterString parameterMinMax parameterSettings =
  { parameters = buildSliders str parameterString parameterMinMax parameterSettings
  , effecting = str
  , parameterNum = num
  , paramNames = parameterString
  , parameterMinMax = parameterMinMax
  , parameterSettings = parameterSettings
  }



-- Change a single parameter from the list of possible parameters
changeParam : String -> Float -> List String -> List (SingleSlider.SingleSlider Message) -> List (SingleSlider.SingleSlider Message)
changeParam name val paramNames sliders =
  case ( paramNames, sliders ) of
    ( [], [] ) ->
      []

    ( p :: pNames, slider :: rest ) ->
      let
        i =
          Debug.log "ELM Names " name ++ Debug.toString val
      in
      if p == name then
        SingleSlider.update val slider :: changeParam name val pNames rest

      else
        slider :: changeParam name val pNames rest

    _ ->
      Debug.todo ("Invalid Prameter Matchup for " ++ name)



-- Helper function that is called in ElmAndTone
getChangedName : Message -> String
getChangedName msg =
  case msg of
    SliderChange name _ _ ->
      name

    RemoveEffect name ->
      name



-- Updates the effect
update : Message -> Effect -> ( Effect, String )
update msg env =
  case msg of
    SliderChange name typ val ->
      let
        newList : List (SingleSlider.SingleSlider Message)
        newList =
          changeParam typ val env.paramNames env.parameters

        newModel : Effect
        newModel =
          { env | parameters = newList }

        message : String
        message =
          name ++ "-" ++ typ ++ "-" ++ Debug.toString val
      in
      ( newModel
      , message
      )

    RemoveEffect str ->
      ( env, str )


-- Display a slider
sliderView : SingleSlider.SingleSlider Message -> ListGroup.Item Message
sliderView slider =
  ListGroup.li [] [ SingleSlider.view slider ]


-- Show cards with sliders on them when an effect is chosen
view : Effect -> Html Message
view env =
  Card.config [ Card.attrs [ style "width" "20rem" ] ]
    |> Card.header [ class "text-center" ] [ Html.h5 [] [ text env.effecting ] ]
    |> Card.listGroup
      (List.map sliderView env.parameters
        ++ [ ListGroup.li []
            [ Button.button [ Button.dark, Button.attrs [ onClick (RemoveEffect env.effecting) ] ] [ text ("Remove" ++ env.effecting) ]
            ]
          ]
      )
    |> Card.view
