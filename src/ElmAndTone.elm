port module ElmAndTone exposing (..)

import Browser
import Browser.Events
--
import Html exposing (Html, Attribute, a, div, pre, p, code, h1, h4, text, main_, button)
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
import Bootstrap.Tab as Tab
import Bootstrap.Utilities.Spacing as Spacing

import Dict

import Envelope
import Effect

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
  , effects : Dict.Dict String Effect.Effect
  , oscillatorDropdown : Dropdown.State
  , effectsDropdown : Dropdown.State
  , oscillatorType : String
  , envelopeTab : Tab.State
  , notes : List Note
  , effectNum : Int
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
        , max = 100
        , value = 0
        , step = 1
        , onChange = SliderChange "partial-"
        }
        |> SingleSlider.withMinFormatter minFormatter
        |> SingleSlider.withValueFormatter partialValueFormatter
        |> SingleSlider.withMaxFormatter maxFormatter
  , oscillatorDropdown =
      Dropdown.initialState
  , effectsDropdown =
      Dropdown.initialState
  , oscillatorType =
      "Triangle"
  , envelopeTab =
      Tab.initialState
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
    , effects=Dict.empty
    , effectNum = 0
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
  | EffectMessage Effect.Message
  --
  | OSCDropdownChange Dropdown.State
  | FXDropdownChange Dropdown.State
  | OscillatorChange String
  | AddFX String
    --
  | TabChange Tab.State


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
--Format Name, Number of parameters, Names of parameters, range for each parameter, starting value and step size, 
addEffect: String -> (Effect.Effect,String)
addEffect str = 
  case str of 
  "Distortion" -> (Effect.init "Distortion" 1 ["Distortion"] [(0,1)] [(0,0.01)],"Distortion")
  "FeedbackDelay" -> (Effect.init "FeedbackDelay" 2 ["Delay","Feedback"] [(0,1),(0,1)] [(0,0.01),(0,0.01)],"FeedbackDelay")
  "FrequencyShifter" ->(Effect.init "FrequencyShifter" 1 ["FrequencyShifter"] [(0,1000)] [(0,2)],"FrequencyShifter")
  "BitCrusher" ->(Effect.init "BitCrusher" 1 ["BitCrusher"] [(1,16)] [(1,1)],"BitCrusher")
  "Chebyshev" ->(Effect.init "Chebyshev" 1 ["Chebyshev"] [(2,100)] [(2,1)],"Chebyshev")
  "HPFilter" ->(Effect.init "HPFilter" 1 ["HPFrequency"] [(1,18000)] [(18000,2)],"HPFilter")
  "LPFilter" ->(Effect.init "LPFilter" 1 ["LPFrequency"] [(1,18000)] [(1,2)],"LPFilter")
  _ -> Debug.todo("Effect needs to be included")

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
    
    EffectMessage fXMsg->
      let 
        name : String
        name = (Debug.log "Effect Name" (Effect.getChangedName fXMsg))
        comp : Maybe Effect.Effect
        comp = Dict.get name model.effects
      in
      case comp of 
        Nothing -> (model, Cmd.none)
        Just effect ->
          let 
            (fx,message) = Effect.update fXMsg effect
          in
          ({model|effects = Dict.insert name fx model.effects}
          ,makeAndSendAudio ("changeFX-"++message))
    OSCDropdownChange state ->
      ({ model | oscillatorDropdown = state }
      , Cmd.none
      )
    FXDropdownChange state ->
      ({ model | effectsDropdown = state }
      , Cmd.none
      )
    AddFX effectName ->
      let
        (newFX,name)  = addEffect effectName
      in
      ({ model | effects = (Dict.insert name newFX model.effects), effectNum = (model.effectNum+1)}
      , makeAndSendAudio ("addFX-"++effectName))
    OscillatorChange st ->
      let 
        message : String 
        message = "oscillator-"++st
      in
      ({model | oscillatorType = st},
      makeAndSendAudio message)
    
    TabChange state ->
      ({ model | envelopeTab = state }
      , Cmd.none
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
        B -> style "" ""--"left" (String.fromInt (((num-1))) ++ "px")
        W -> if (num==28) then style "border-right-width" "1px"
             else style "" "" --"left" (String.fromInt (num) ++ "px")


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

viewEffect: String ->Effect.Effect -> Html Msg
viewEffect str fx = div [] [Effect.view fx |> Html.map EffectMessage]


view : Model -> Html Msg
view model =
  main_ [ class "m-10 body" ]
    [ h1 [ class "text-3xl my-10" ]
        [ text "ElmSynth" ]
    , div [] [ SingleSlider.view model.volumeSlider ]
    , pre [] [ text "" ]
    , p [ class "p-0 my-6" ]
        [ text ("Oscillator selected: " ++ (model.oscillatorType)) ]
    , div [] [ Dropdown.dropdown model.oscillatorDropdown
      { options = [ Dropdown.alignMenuRight ]
      , toggleMsg = OSCDropdownChange
      , toggleButton = Dropdown.toggle [ Button.primary ][ text "Change Oscillator Type" ]
      , items =
        [ Dropdown.buttonItem [ onClick (OscillatorChange "sine") ] [ text "Sine" ]
        , Dropdown.buttonItem [ onClick (OscillatorChange "square") ] [ text "Square" ]
        , Dropdown.buttonItem [ onClick (OscillatorChange "triangle") ] [ text "Triange" ]
        , Dropdown.buttonItem [ onClick (OscillatorChange "sawtooth") ] [ text "Sawtooth" ]
        ]
      }]
    , div [] [ SingleSlider.view model.partialSlider ]
    , pre [] [ text "" ]
    , p [ class "p-0 my-6" ]
        [ text "Type on the keyboard to play notes!" ]
    , div [ class "keaboard" ]
        <| List.indexedMap noteView model.notes
    , div [ class "p-2 my-6" ]
        [ button [ onClick TransposeUp, class "bg-indigo-500 text-black font-bold py-2 px-4 mr-4 rounded" ]
            [ text "Transpose up" ]
        , button [ onClick TransposeDown, class "bg-indigo-500 text-black font-bold py-2 px-4 rounded" ]
            [ text "Transpose down" ]
        ]
    , pre [] [ text "" ]
    , Tab.config TabChange
        |> Tab.items
          [ Tab.item
              { id = "tabItem1"
              , link = Tab.link [] [ text "Preset Envelopes" ]
              , pane =
                  Tab.pane [ Spacing.mt3 ]
                    [ p [] [ text "Choose an instrument" ]
                    ]
              }
          , Tab.item
              { id = "tabItem2"
              , link = Tab.link [] [ text "Create Envelope" ]
              , pane =
                  Tab.pane [ Spacing.mt3 ]
                    [ p [] [ text "Toggle the sliders to create your own envelope" ]
                    , div [] [ Envelope.view model.addEnv |> Html.map EnvMessage ]
                    , p [] [text "Add/Remove Effects here"]
                    , div [] (Dict.values (Dict.map viewEffect model.effects))
                    , div [] [ Dropdown.dropdown model.effectsDropdown
                        { options = [ Dropdown.alignMenuRight ]
                        , toggleMsg = FXDropdownChange
                        , toggleButton = Dropdown.toggle [ Button.primary ][ text "Add Effect" ]
                        , items =
                          [ Dropdown.buttonItem [ onClick (AddFX "Distortion") ] [ text "Distortion" ]
                          , Dropdown.buttonItem [ onClick (AddFX "BitCrusher") ] [ text "BitCrusher" ]
                          , Dropdown.buttonItem [ onClick (AddFX "Chebyshev") ] [ text "Chebyshev" ]
                          , Dropdown.buttonItem [ onClick (AddFX "FrequencyShifter") ] [ text "FrequencyShifter" ]
                          , Dropdown.buttonItem [ onClick (AddFX "FeedbackDelay") ] [ text "FeedbackDelay" ]
                          , Dropdown.buttonItem [ onClick (AddFX "LPFilter") ] [ text "Low Pass Filter" ]
                          , Dropdown.buttonItem [ onClick (AddFX "HPFilter") ] [ text "High Pass Filter" ]
                          ]
                        }]
                    ]
              }
          ]
        |> Tab.view model.envelopeTab
      , pre [] [ text "" ]
      , pre [] [ text "" ]
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
    , Dropdown.subscriptions model.oscillatorDropdown OSCDropdownChange
    , Dropdown.subscriptions model.effectsDropdown FXDropdownChange
    ]
