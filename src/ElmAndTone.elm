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
import SingleSlider exposing (..)
--
import Bootstrap.Button as Button
import Bootstrap.Dropdown as Dropdown

import Envelope

type alias Flags = ()

-- MAIN -----------------------------------------------------------------------
main : Program Flags Model Msg
main =
    Browser.element
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }


-- Send the JSON-encoded audio graph to JavaScript
port updateAudio : String -> Cmd msg


-- MODEL ----------------------------------------------------------------------
--Differentiate between black and white keys
type Color  = B | W
type alias Note =
  { key : String
  , midi : Float
  , triggered : Bool
  , detriggered: Bool
  , clr : Color
  }


type alias Model =
  { volumeSlider : SingleSlider.SingleSlider Msg
  , partialSlider : SingleSlider.SingleSlider Msg
  , addEnv : Envelope.Envelope
  , oscillatorDropdown : Dropdown.State
  , notes : List Note
  }


--The computer-key keyboard is implemented according to common DAW practices
--AKA, type on the keyboard as if it were a piano
initialModel : Model
initialModel =
  let
    minFormatter = \value -> ""
    maxFormatter = \value -> ""
    volumeValueFormatter = \value not_used_value -> "Volume: " ++ (String.fromFloat value)
    partialValueFormatter = \value not_used_value -> "Partial: " ++ (String.fromFloat value)
  in
  { volumeSlider =
      SingleSlider.init
        { min = 0
        , max = 100
        , value = 50
        , step = 1
        , onChange = SliderChange "volume-"
        }
        |> SingleSlider.withMinFormatter minFormatter
        |> SingleSlider.withValueFormatter volumeValueFormatter
        |> SingleSlider.withMaxFormatter maxFormatter
  , partialSlider =
      SingleSlider.init
        { min = 0
        , max = 50
        , value = 0
        , step = 1
        , onChange = SliderChange "partial-"
        }
        |> SingleSlider.withMinFormatter minFormatter
        |> SingleSlider.withValueFormatter partialValueFormatter
        |> SingleSlider.withMaxFormatter maxFormatter
  , oscillatorDropdown =
      Dropdown.initialState
  , notes =
    [ { key = "z", midi = 48, triggered = False, detriggered = False, clr = W }
    , { key = "s", midi = 49, triggered = False, detriggered = False, clr = B }
    , { key = "x", midi = 50, triggered = False, detriggered = False, clr = W }
    , { key = "d", midi = 51, triggered = False, detriggered = False, clr = B }
    , { key = "c", midi = 52, triggered = False, detriggered = False, clr = W }
    , { key = "v", midi = 53, triggered = False, detriggered = False, clr = W }
    , { key = "g", midi = 54, triggered = False, detriggered = False, clr = B }
    , { key = "b", midi = 55, triggered = False, detriggered = False, clr = W }
    , { key = "h", midi = 56, triggered = False, detriggered = False, clr = B }
    , { key = "n", midi = 57, triggered = False, detriggered = False, clr = W }
    , { key = "j", midi = 58, triggered = False, detriggered = False, clr = B }
    , { key = "m", midi = 59, triggered = False, detriggered = False, clr = W }
    , { key = "q", midi = 60, triggered = False, detriggered = False, clr = W }
    , { key = "2", midi = 61, triggered = False, detriggered = False, clr = B }
    , { key = "w", midi = 62, triggered = False, detriggered = False, clr = W }
    , { key = "3", midi = 63, triggered = False, detriggered = False, clr = B }
    , { key = "e", midi = 64, triggered = False, detriggered = False, clr = W }
    , { key = "r", midi = 65, triggered = False, detriggered = False, clr = W }
    , { key = "5", midi = 66, triggered = False, detriggered = False, clr = B }
    , { key = "t", midi = 67, triggered = False, detriggered = False, clr = W }
    , { key = "6", midi = 68, triggered = False, detriggered = False, clr = B }
    , { key = "y", midi = 69, triggered = False, detriggered = False, clr = W }
    , { key = "7", midi = 70, triggered = False, detriggered = False, clr = B }
    , { key = "u", midi = 71, triggered = False, detriggered = False, clr = W }
    , { key = "i", midi = 72, triggered = False, detriggered = False, clr = W }
    , { key = "9", midi = 73, triggered = False, detriggered = False, clr = B }
    , { key = "o", midi = 74, triggered = False, detriggered = False, clr = W }
    , { key = "0", midi = 75, triggered = False, detriggered = False, clr = B }
    , { key = "p", midi = 76, triggered = False, detriggered = False, clr = W }
    ]
    , addEnv = Envelope.init "gainenv"
  }


init : () -> (Model, Cmd Msg)
init _ =
  ( initialModel, Cmd.none )

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
  | SliderChange String Float
  | EnvMessage Envelope.Message
  --
  | DropdownChange Dropdown.State
  | OscillatorSine
  | OscillatorSquare
  | OscillatorTriangle
  | OscillatorSawtooth


noteOn : String -> Model -> Model
noteOn key model =
  { model
  | notes = List.map
    (\note ->
      if note.key == key then
        { note | triggered = True }
      else note
    )
  model.notes
  }


noteOff : String -> Model -> Model
noteOff key model =
  { model
  | notes = List.map
    (\note ->
      if note.key == key then
        { note | triggered = False }
      else note
    )
  model.notes
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


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    SliderChange typ val ->
      let
        newModel : Model
        newModel =
          case typ of
            "volume-" ->
              { model | volumeSlider = (SingleSlider.update val model.volumeSlider) }
            "partial-" ->
              { model | partialSlider = (SingleSlider.update val model.partialSlider) }
            _ -> Debug.todo("undefined Slider Changed")
        message : String
        message = typ ++ Debug.toString(val)
      in
      ( newModel
      , makeAndSendAudio message
      )

    NoOp ->
      Tuple.pair model Cmd.none

    NoteOn key ->
      let
        val = findKey key model
        message : String
        message = "press-" ++ Debug.toString(val)
      in
      ( noteOn key model
      , makeAndSendAudio message
      )

    NoteOff key ->
      let
        val = findKey key model
        message : String
        message = "release-" ++ Debug.toString(val)
      in
      ( noteOff key model
      , makeAndSendAudio message
      )

    TransposeUp ->
      ( transposeUp model
      , Cmd.none
      )

    TransposeDown ->
      ( transposeDown model
      , Cmd.none
      )

    EnvMessage envelopeMsg->
      let
        (newEnv,str) = Envelope.update envelopeMsg model.addEnv
      in
      ({ model | addEnv = newEnv }
      , makeAndSendAudio str
      )

    DropdownChange state ->
      ({ model | oscillatorDropdown = state }
      , Cmd.none
      )

    OscillatorSine ->
      let
        message : String
        message = "oscillator-sine"
      in
      ( model
      , makeAndSendAudio message
      )

    OscillatorSquare ->
      let
        message : String
        message = "oscillator-square"
      in
      ( model
      , makeAndSendAudio message
      )

    OscillatorTriangle ->
      let
        message : String
        message = "oscillator-triangle"
      in
      ( model
      , makeAndSendAudio message
      )

    OscillatorSawtooth ->
      let
        message : String
        message = "oscillator-sawtooth"
      in
      ( model
      , makeAndSendAudio message
      )


-- AUDIO ----------------------------------------------------------------------
-- Super simple utility function that takes a MIDI note number like 60 and
-- converts it to the corresponding frequency in Hertz. We use Float for the
-- MIDI number to allow for detuning, and we assume A4 is MIDI note number 69.
mtof : Float -> Float
mtof midi =
  440 * 2 ^ ((midi - 69) / 12)


--Math.floor(((white_key_width + 1) * (key.noteNumber + 1)) - (black_key_width / 2)) + 'px';*/
--Helper function to make black keys look pretty
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


view : Model -> Html Msg
view model =
  main_ [ class "m-10 body" ]
    [ h1 [ class "text-3xl my-10" ]
        [ text "ElmSynth" ]
    , p [ class "p-2 my-6" ]
        [ text """Click to activate Web Audio context""" ]
    , div [ class "p-2 my-6" ]
        [ button [ onClick TransposeUp, class "bg-indigo-500 text-white font-bold py-2 px-4 mr-4 rounded" ]
            [ text "Transpose up" ]
        , button [ onClick TransposeDown, class "bg-indigo-500 text-white font-bold py-2 px-4 rounded" ]
            [ text "Transpose down" ]
        ]
    , div [ class "keaboard" ]
        <| List.indexedMap noteView model.notes
    , div [] [ SingleSlider.view model.volumeSlider ]
    , div [] [ Envelope.view model.addEnv |> Html.map EnvMessage ]
    , div [] [ Dropdown.dropdown model.oscillatorDropdown
      { options = [ Dropdown.alignMenuRight ]
      , toggleMsg = DropdownChange
      , toggleButton = Dropdown.toggle [ Button.primary ][ text "Change Oscillator Type" ]
      , items =
        [ Dropdown.buttonItem [ onClick OscillatorSine ] [ text "Sine" ]
        , Dropdown.buttonItem [ onClick OscillatorSquare ] [ text "Square" ]
        , Dropdown.buttonItem [ onClick OscillatorTriangle ] [ text "Triange" ]
        , Dropdown.buttonItem [ onClick OscillatorSawtooth ] [ text "Sawtooth" ]
        ]
      }]
    , div [] [ SingleSlider.view model.partialSlider ]
    ]

-- SUBSCRIPTIONS --------------------------------------------------------------

makeAndSendAudio: String -> Cmd msg
makeAndSendAudio lst = updateAudio (Encode.encode 0 (Encode.string lst))


keyDecoder : Decode.Decoder String
keyDecoder =
  Decode.field "key" Decode.string


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Browser.Events.onKeyDown (Decode.map (\key -> NoteOn key) keyDecoder)
    , Browser.Events.onKeyUp (Decode.map (\key -> NoteOff key) keyDecoder)
    , Dropdown.subscriptions model.oscillatorDropdown DropdownChange
    ]
