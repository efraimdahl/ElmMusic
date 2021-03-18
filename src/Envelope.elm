module Envelope exposing (..)

import Bootstrap.Table as Table
import Browser
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Html.Events
import SingleSlider exposing (..)


-- An envelope with have sliders for attack, decay,
-- sustain, and release.
-- effecting is 'gainenv', the string that we use to identify
-- an envelope
type alias Envelope =
  { attack : SingleSlider.SingleSlider Message
  , decay : SingleSlider.SingleSlider Message
  , sustain : SingleSlider.SingleSlider Message
  , release : SingleSlider.SingleSlider Message
  , effecting : String
  }


type Message
  = SliderChange String Float


makeEnvMessage : String -> Float -> Message
makeEnvMessage n f =
  SliderChange n f


-- Initialize the sliders
init : String -> Envelope
init str =
  let
    minFormatter =
      \value -> ""

    valueFormatterAt =
      \value not_used_value -> "Attack: " ++ String.fromFloat value

    valueFormatterDe =
      \value not_used_value -> "Decay: " ++ String.fromFloat value

    valueFormatterSu =
      \value not_used_value -> "Sustain: " ++ String.fromFloat value

    valueFormatterRe =
      \value not_used_value -> "Release: " ++ String.fromFloat value

    maxFormatter =
      \value -> ""
  in
  { attack =
    SingleSlider.init
      { min = 0.0005
      , max = 3
      , value = 0.0005
      , step = 0.01
      , onChange = SliderChange "attack"
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
      , onChange = SliderChange "decay"
      }
      |> SingleSlider.withMinFormatter minFormatter
      |> SingleSlider.withValueFormatter valueFormatterDe
      |> SingleSlider.withMaxFormatter maxFormatter
  , sustain =
    SingleSlider.init
      { min = 0.0005
      , max = 0.999
      , value = 0.9905
      , step = 0.01
      , onChange = SliderChange "sustain"
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
      , onChange = SliderChange "release"
      }
      |> SingleSlider.withMinFormatter minFormatter
      |> SingleSlider.withValueFormatter valueFormatterRe
      |> SingleSlider.withMaxFormatter maxFormatter
  , effecting = str
  }


-- Update the sliders when the user interacts with them
update : Message -> Envelope -> ( Envelope, String )
update msg env =
  case msg of
    SliderChange typ val ->
      let
        newModel : Envelope
        newModel =
          case typ of
            "attack" ->
              { env | attack = SingleSlider.update val env.attack }

            "decay" ->
              { env | decay = SingleSlider.update val env.decay }

            "sustain" ->
              { env | sustain = SingleSlider.update val env.sustain }

            "release" ->
              { env | release = SingleSlider.update val env.release }

            _ ->
              Debug.todo ("2undefined Slider Changed " ++ typ)

        message : String
        message =
          env.effecting ++ "-" ++ typ ++ "-" ++ Debug.toString val
      in
      ( newModel
      , message
      )


-- Display the sliders in a table
view : Envelope -> Html Message
view env =
  Table.simpleTable
    ( Table.simpleThead
      [ Table.th [] [ text "Attack/Decay" ]
      , Table.th [] [ text "Sustain/Release" ]
      ]
    , Table.tbody []
      [ Table.tr []
        [ Table.td [] [ SingleSlider.view env.attack ]
        , Table.td [] [ SingleSlider.view env.sustain ]
        ]
      , Table.tr []
        [ Table.td [] [ SingleSlider.view env.decay ]
        , Table.td [] [ SingleSlider.view env.release ]
        ]
      ]
    )
