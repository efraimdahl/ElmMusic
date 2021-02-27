port module ElmAndTone exposing (..)

import Browser
import Browser.Events
--
import Html exposing (Html, Attribute, a, div, pre, p, code, h1, text, main_, button)
import Html.Attributes exposing (class, href,style)
import Html.Events exposing (onClick)
--
import Json.Decode as Decode
import Json.Encode as Encode
--
import Time exposing (..)
import Task exposing (..)
--
import SingleSlider exposing (..)

type alias Flags =
  ()

-- MAIN -----------------------------------------------------------------------
main : Program Flags Model Msg
main =
    Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }


-- Send the JSON encoded audio graph to javascript
port updateAudio : String -> Cmd msg

-- MODEL ----------------------------------------------------------------------
--
--differenciate between black and white keys
type Color  = B | W
type alias Note =
  { key : String
  , midi : Float
  , triggered : Bool
  , detriggered: Bool
  , timeTriggered : Int
  , clr : Color
  }

--
type alias Model =
  { time : Time.Posix
  , volumeSlider : SingleSlider.SingleSlider Msg
  , notes : List Note
  }

initialModel : Model --implemented computer-key keyboard according to common DAW practices
initialModel =
  let
    minFormatter = \value -> ""
    valueFormatter = \value not_used_value -> "Volume: " ++ (String.fromFloat value)
    maxFormatter = \value -> ""
  in
  { time = (Time.millisToPosix 0)
  , volumeSlider =
      SingleSlider.init
        { min = 0
        , max = 100
        , value = 50
        , step = 1
        , onChange = VolumeSliderChange
        }
        |> SingleSlider.withMinFormatter minFormatter
        |> SingleSlider.withValueFormatter valueFormatter
        |> SingleSlider.withMaxFormatter maxFormatter
  , notes =
    [ { key = "z", midi = 48, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "s", midi = 49, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "x", midi = 50, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "d", midi = 51, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "c", midi = 52, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "v", midi = 53, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "g", midi = 54, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "b", midi = 55, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "h", midi = 56, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "n", midi = 57, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "j", midi = 58, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "m", midi = 59, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "q", midi = 60, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "2", midi = 61, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "w", midi = 62, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "3", midi = 63, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "e", midi = 64, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "r", midi = 65, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "5", midi = 66, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "t", midi = 67, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "6", midi = 68, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "y", midi = 69, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "7", midi = 70, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "u", midi = 71, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "i", midi = 72, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "9", midi = 73, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "o", midi = 74, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    , { key = "0", midi = 75, triggered = False, detriggered = False, timeTriggered = 0, clr = B }
    , { key = "p", midi = 76, triggered = False, detriggered = False, timeTriggered = 0, clr = W }
    ]
  }



--
init : () -> (Model, Cmd Msg)
init _ =
  ( initialModel
  , Cmd.none
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
  | VolumeSliderChange Float

--
noteOn : String -> Model -> Model
noteOn key model =
  { model
  | notes = List.map (\note ->
    if note.key == key then
      let
        m = Debug.log "model" (toSecond utc model.time)
      in
      { note | triggered = True
      , timeTriggered = (Debug.log "time" (toSecond utc model.time))} --number of seconds
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

findKey: String -> Model -> Float
findKey s m =
  let
    test : Note -> Bool
    test n = (n.key==s)
    mainVal : List Note
    mainVal =  List.filter test m.notes
  in
  case mainVal of
    [] -> 0
    hd::tail -> mtof (hd.midi)

--
update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Tick newTime ->
        let
          m:Model
          m ={time=newTime, volumeSlider = model.volumeSlider, notes=model.notes}
        in
        ( m
        , Cmd.none
        )

    VolumeSliderChange str ->
      let
          newSlider = SingleSlider.update str model.volumeSlider
          message : String
          message = "volume-"++Debug.toString(str)
      in
      ( { model | volumeSlider = newSlider }
      , makeAndSendAudio message )

    NoOp ->
      Tuple.pair model Cmd.none

    NoteOn key ->
      let
        val = findKey key model
        message : String
        message = "press-"++Debug.toString(val)
      in
      ( noteOn key model
      , makeAndSendAudio message--(Debug.log "message-string " message)
      )

    NoteOff key ->
      let
        val = findKey key model
        message : String
        message = "release-"++Debug.toString(val)
      in
      ( noteOff key model
      , makeAndSendAudio message--(Debug.log "message-string " message)
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
    --This displays the clock, just for debugging
    , h1 [] [ text (hour ++ ":" ++ minute ++ ":" ++ second) ]
    , div [ class "p-2 my-6" ]
        [ button [ onClick TransposeUp, class "bg-indigo-500 text-white font-bold py-2 px-4 mr-4 rounded" ]
            [ text "Transpose up" ]
        , button [ onClick TransposeDown, class "bg-indigo-500 text-white font-bold py-2 px-4 rounded" ]
            [ text "Transpose down" ]
        ]
    , div [ class "keaboard" ]
        <| List.indexedMap noteView model.notes
    , div [] [ SingleSlider.view model.volumeSlider ]
    ]

-- SUBSCRIPTIONS --------------------------------------------------------------
--
makeAndSendAudio: String -> Cmd msg
makeAndSendAudio lst = updateAudio (Encode.encode 0 (Encode.string lst))


keyDecoder : Decode.Decoder String
keyDecoder =
  Decode.field "key" Decode.string

--
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Browser.Events.onKeyDown
    (Decode.map (\key -> NoteOn key) keyDecoder)
    , Browser.Events.onKeyUp
    (Decode.map (\key -> NoteOff key) keyDecoder)
    , Time.every 1000 Tick
    ]
