port module Main exposing (..)

import Browser
import Browser.Events
--
import Html exposing (Html, Attribute, a, div, pre, p, code, h1, text, main_, button)
import Html.Attributes exposing (class, href,style)
import Html.Events exposing (onClick)
--
import Json.Decode
import Json.Encode
--
import WebAudio
import WebAudio.Property as Prop
import WebAudio.Program
--
import Time exposing (..)
import Task exposing (..)

-- Send the JSON encoded audio graph to javascript
port updateAudio : Json.Encode.Value -> Cmd msg

-- MAIN -----------------------------------------------------------------------
main : Program () Model Msg
main =
  WebAudio.Program.element
    { init = init
    , update = update
    , audio = audio
    , view = view
    , subscriptions = subscriptions
    , audioPort = updateAudio
    }

-- MODEL ----------------------------------------------------------------------
--
--differenciate between black and white keys
type Color  = B | W
type alias Note =
  { key : String
  , midi : Float
  , triggered : Bool
  , timeTriggered : Int
  , clr : Color
  }

--
type alias Model =
  { time : Time.Posix
  , notes : List Note
  }


initialModel : Model --implemented computer-key keyboard according to common DAW practices
initialModel =
  { time = (Time.millisToPosix 0)
  , notes =
    [ { key = "z", midi = 48, triggered = False, timeTriggered=0, clr=W }
    , { key = "s", midi = 49, triggered = False, timeTriggered=0, clr=B }
    , { key = "x", midi = 50, triggered = False, timeTriggered=0, clr=W }
    , { key = "d", midi = 51, triggered = False, timeTriggered=0, clr=B }
    , { key = "c", midi = 52, triggered = False, timeTriggered=0, clr=W }
    , { key = "v", midi = 53, triggered = False, timeTriggered=0, clr=W }
    , { key = "g", midi = 54, triggered = False, timeTriggered=0, clr=B }
    , { key = "b", midi = 55, triggered = False, timeTriggered=0, clr=W }
    , { key = "h", midi = 56, triggered = False, timeTriggered=0, clr=B }
    , { key = "n", midi = 57, triggered = False, timeTriggered=0, clr=W }
    , { key = "j", midi = 58, triggered = False, timeTriggered=0, clr=B }
    , { key = "m", midi = 59, triggered = False, timeTriggered=0, clr=W }
    , { key = "q", midi = 60, triggered = False, timeTriggered=0, clr=W }
    , { key = "2", midi = 61, triggered = False, timeTriggered=0, clr=B }
    , { key = "w", midi = 62, triggered = False, timeTriggered=0, clr=W }
    , { key = "3", midi = 63, triggered = False, timeTriggered=0, clr=B }
    , { key = "e", midi = 64, triggered = False, timeTriggered=0, clr=W }
    , { key = "r", midi = 65, triggered = False, timeTriggered=0, clr=W }
    , { key = "5", midi = 66, triggered = False, timeTriggered=0, clr=B }
    , { key = "t", midi = 67, triggered = False, timeTriggered=0, clr=W }
    , { key = "6", midi = 68, triggered = False, timeTriggered=0, clr=B }
    , { key = "y", midi = 69, triggered = False, timeTriggered=0, clr=W }
    , { key = "7", midi = 70, triggered = False, timeTriggered=0, clr=B }
    , { key = "u", midi = 71, triggered = False, timeTriggered=0, clr=W }
    , { key = "i", midi = 72, triggered = False, timeTriggered=0, clr=W }
    , { key = "9", midi = 73, triggered = False, timeTriggered=0, clr=B }
    , { key = "o", midi = 74, triggered = False, timeTriggered=0, clr=W }
    , { key = "0", midi = 75, triggered = False, timeTriggered=0, clr=B }
    , { key = "p", midi = 76, triggered = False, timeTriggered=0, clr=W }
    ]
  }



--
init : () -> (Model, Cmd Msg)
init _ =
  ( initialModel
  , Task.perform Tick Time.now
  )

-- UPDATE ---------------------------------------------------------------------
type Msg
  = NoOp
  --
  | NoteOn String
  | NoteOff String
  --
  | TransposeUp
  | TransposeDown
  --
  | Tick Time.Posix

--
noteOn : String -> Model -> Model
noteOn key model =
  { model
  | notes = List.map (\note ->
    if note.key == key then
      { note | triggered = True
      , timeTriggered = (toMillis utc model.time) // 1000 } --number of seconds
      else note) model.notes
  }

--
noteOff : String -> Model -> Model
noteOff key model =
  { model
  | notes = List.map (\note ->
    if note.key == key then
      { note | triggered = False
      , timeTriggered = 0 }
      else note) model.notes
  }

transposeUp : Model -> Model
transposeUp model =
  { model
  | notes = List.map (\note -> { note | midi = note.midi + 1 }) model.notes
  }

transposeDown : Model -> Model
transposeDown model =
  { model
  | notes = List.map (\note -> { note | midi = note.midi - 1 }) model.notes
  }

--
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Tick newTime ->
      ( { model | time = newTime }
      , Cmd.none
      )

    NoOp ->
      Tuple.pair model Cmd.none

    NoteOn key ->
      ( noteOn key model
      , Cmd.none
      )

    NoteOff key ->
      ( noteOff key model
      , Cmd.none
      )

    TransposeUp ->
      ( transposeUp model
      , Cmd.none
      )

    TransposeDown ->
      ( transposeDown model
      , Cmd.none
      )




-- AUDIO ----------------------------------------------------------------------
-- Super simple utility function that takes a MIDI note number like 60 and
-- converts it to the corresponding frequency in Hertz. We use Float for the
-- MIDI number to allow for detuning, and we assume A4 is MIDI note number
-- 69.
mtof : Float -> Float
mtof midi =
  440 * 2 ^ ((midi - 69) / 12)

-- This takes a Note (as defined above) and converts that to a synth voice.
voice : Note -> WebAudio.Node
voice note =
  WebAudio.oscillator [ Prop.frequency (mtof note.midi), Prop.type_ "triangle"]
    [ WebAudio.gain (gainer note.triggered)
      [ WebAudio.dac ]
    ]

--ADSR envolope:
{-
adsr : Property -> Float -> Float -> Float -> Float-> Float -> Float-> Float -> Property
adsr val a aval d dval s sval r rval=
    linearRampToValueAtTime (val 440) 1
-}

gainer : Bool-> List Prop.Property
gainer triggered =
    if triggered then
        --[Prop.linearRampToValueAtTime (Prop.gain 0.2) 1]++
        --[Prop.linearRampToValueAtTime (Prop.gain 0.1) 2]++
        --[Prop.linearRampToValueAtTime (Prop.gain 0.1) 2.5]++
        --[Prop.linearRampToValueAtTime (Prop.gain 0.1) 2]++
        [(Prop.gain 0.1)]

    else
        [Prop.gain 0]
        --[Prop.exponentialRampToValueAtTime (Prop.gain 0.1) 3]++
        --[Prop.exponentialRampToValueAtTime (Prop.gain 0.0001) 6]
-- On the js side, the virtual audio graph is expecting an array of virtual
-- nodes. This plays nicely with our list of Notes, we can simply map the
-- Notes to synth voices and encode the new list.
-- Returns a Cmd Msg as we call the port from within this function (rather
-- than returning the encoded JSON).
audio : Model -> WebAudio.Graph
audio model =
  List.map voice model.notes

--Math.floor(((white_key_width + 1) * (key.noteNumber + 1)) - (black_key_width / 2)) + 'px';*/
--helper function for making black keys look pretty
getBlackOffset: Int -> Color -> Attribute msg
getBlackOffset num clr =
    case clr of
        B -> style "" ""--"left" (String.fromInt ((48*(num+1))-12) ++ "px")
        W -> if (num==28) then style "border-right-width" "1px"
             else style "" ""

-- VIEW -----------------------------------------------------------------------
-- Use this to toggle the main styling on a note based on wheter it is currently
-- active or note. Basically just changes the background and font colour.
noteCSS : Int-> Bool -> Color-> String
noteCSS i active clr =
  case clr of
    W -> if active then
        "WhiteKeyActive"
        else
        "WhiteKey"
    B -> if active then
        "BlackKeyActive "
        else
        "BlackKey "


-- This takes a Note (as defined above) and converts that to some  Notice
-- how we use the data for both the `voice` function and this `noteView` function.
-- Our audio graph should never become out of sync with our view!
noteView : Int -> Note -> Html Msg
noteView i note =
  div [ class <| noteCSS i note.triggered note.clr, class "Key", (getBlackOffset i note.clr)]
    [ text note.key ]

audioView : List Note -> List (Html Msg)
audioView =
  List.map (\note ->
    voice note |> WebAudio.encode |> Json.Encode.encode 2 |> (\json ->
      pre [ class "text-xs", class <| if note.triggered then "text-gray-800" else "text-gray-500" ]
        [ code [ class "my-2" ]
          [ text json ]
        ]
    )
  )

--
view : Model -> Html Msg
view model =
  let
    hour   = String.fromInt (Time.toHour   utc model.time)
    minute = String.fromInt (Time.toMinute utc model.time)
    second = String.fromInt (Time.toSecond utc model.time)
  in
  main_ [ class "m-10 body" ]
    [ h1 [ class "text-3xl my-10" ]
        [ text "ElmSynth" ]
    , p [ class "p-2 my-6" ]
        [ text """Click to activate Web Audio context""" ]
    , h1 [] [ text (hour ++ ":" ++ minute ++ ":" ++ second) ]
    , div [ class "p-2 my-6" ]
        [ button [ onClick TransposeUp, class "bg-indigo-500 text-white font-bold py-2 px-4 mr-4 rounded" ]
            [ text "Transpose up" ]
        , button [ onClick TransposeDown, class "bg-indigo-500 text-white font-bold py-2 px-4 rounded" ]
            [ text "Transpose down" ]
        ]
    , div [ class "keaboard" ]
        <| List.indexedMap noteView model.notes
    , div [ class "p-2 my-10" ]
        [ text """Below is the json send via ports to javascript. Active notes
          are highlighted.""" ]
    , div [ class "bg-gray-200 p-2 my-10 rounded h-64 overflow-scroll"]
        <| audioView model.notes
    ]

-- SUBSCRIPTIONS --------------------------------------------------------------
--
noteOnDecoder : List Note -> Json.Decode.Decoder Msg
noteOnDecoder notes =
  Json.Decode.field "key" Json.Decode.string
    |> Json.Decode.andThen (\key ->
      case List.any (\note -> note.key == key) notes of
        True ->
          Json.Decode.succeed (NoteOn key)
        False ->
          Json.Decode.fail ""
    )

--
noteOffDecoder : List Note -> Json.Decode.Decoder Msg
noteOffDecoder notes =
  Json.Decode.field "key" Json.Decode.string
    |> Json.Decode.andThen (\key ->
      case List.any (\note -> note.key == key) notes of
        True ->
          Json.Decode.succeed (NoteOff key)
        False ->
          Json.Decode.fail ""
    )

--
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Browser.Events.onKeyDown <| noteOnDecoder model.notes
    , Browser.Events.onKeyUp <| noteOffDecoder model.notes
    , Time.every 1000 Tick
    ]
