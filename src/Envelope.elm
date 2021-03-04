module Envelope exposing(..)

import Browser
import Browser.Events
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Html.Events

import SingleSlider exposing (..)

type alias Envelope = 
    { 
      attack : SingleSlider.SingleSlider Message
      ,decay : SingleSlider.SingleSlider Message
      ,sustain : SingleSlider.SingleSlider Message
      ,release : SingleSlider.SingleSlider Message
      ,effecting : String
    }

type Message
  = SliderChange String Float
  

init : String -> Envelope
init str = 
  let
    minFormatter = \value -> ""
    valueFormatterAt = \value not_used_value -> "Attack: " ++ (String.fromFloat value)
    valueFormatterDe = \value not_used_value -> "Decay: " ++ (String.fromFloat value)
    valueFormatterSu = \value not_used_value -> "Sustain: " ++ (String.fromFloat value)
    valueFormatterRe = \value not_used_value -> "Release: " ++ (String.fromFloat value)
    maxFormatter = \value -> ""
  in
  {attack =
      SingleSlider.init
        { min = 0.0005
        , max = 3
        , value = 0.0005
        , step = 0.01
        , onChange = SliderChange "attack-"
        }
        |> SingleSlider.withMinFormatter minFormatter
        |> SingleSlider.withValueFormatter valueFormatterAt
        |> SingleSlider.withMaxFormatter maxFormatter
      , decay =
      SingleSlider.init
        { min = 0.0005
        , max = 3
        , value = 0.0005
        , step = 0.01
        , onChange = SliderChange "decay-"
        }
        |> SingleSlider.withMinFormatter minFormatter
        |> SingleSlider.withValueFormatter valueFormatterDe
        |> SingleSlider.withMaxFormatter maxFormatter
      , sustain =
      SingleSlider.init
        { min = 0.0005
        , max = 0.999
        , value = 0.0005
        , step = 0.01
        , onChange = SliderChange "sustain-"
        }
        |> SingleSlider.withMinFormatter minFormatter
        |> SingleSlider.withValueFormatter valueFormatterSu
        |> SingleSlider.withMaxFormatter maxFormatter
      , release =
      SingleSlider.init
        { min = 0.0005
        , max = 3
        , value = 0.0005
        , step = 0.01
        , onChange = SliderChange "releaseEnv-"
        }
        |> SingleSlider.withMinFormatter minFormatter
        |> SingleSlider.withValueFormatter valueFormatterRe
        |> SingleSlider.withMaxFormatter maxFormatter
      , effecting = str
    }


update : Message -> Envelope -> (Envelope,String)
update msg env =
    case msg of
        SliderChange typ val ->
            let 
                newModel : Envelope
                newModel = 
                    case typ of 
                    "attack-" -> {env | attack = (SingleSlider.update val env.attack)}
                    "decay-" -> {env | decay = (SingleSlider.update val env.decay)}
                    "sustain-" -> {env | sustain = (SingleSlider.update val env.sustain)}
                    "releaseEnv-" -> {env | release = (SingleSlider.update val env.release)}
                    _ -> Debug.todo("undefined Slider Changed")

                message : String
                message = env.effecting++"-"++typ++Debug.toString(val)
            in
            ( newModel
            , message )


view : Envelope -> Html Message
view env = 
    div [] [
    div [] [ SingleSlider.view env.attack ]
    , div [] [ SingleSlider.view env.decay ]
    , div [] [ SingleSlider.view env.sustain ]
    , div [] [ SingleSlider.view env.release ]]
