port module ElmAndTone exposing (..)

import Effect
import Envelope

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Bootstrap.Accordion as Accordion
import Bootstrap.Button as Button
import Bootstrap.Card.Block as Block
import Bootstrap.Dropdown as Dropdown
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Tab as Tab
import Bootstrap.Utilities.Spacing as Spacing
import SingleSlider exposing (..)
import String.Extra
import Browser
import Browser.Events
import Dict
import Json.Decode as Decode
import Json.Encode as Encode



type alias Flags =
  ()


-- This file replaced our Main.elm file.


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
-- Differentiate between black and white keys
type Color
  = B
  | W


type alias Note =
  { key : String
  , midi : Float
  , triggered : Bool
  , detriggered : Bool
  , clr : Color
  }


-- notes is a list of notes corresponding to the computer keyboard
-- volumeSlider is a slider for volume
-- oscillatorType is a string to keep track of the current oscillator type
-- oscillatorDropdown is a Bootstrap dropdown menu to change the oscillator type
-- partialSlider is a slider for the oscillator partial
-- addEnv is an ADSR envelope, see Envelope.elm
-- effectNum is the number of effects that have been added
-- effects is a dictionary of effects, see Effect.elm
-- effectsDropdown is a Bootstrap dropdown menu to add effects
-- envelopeTab is a Bootstrap tab interface for basic and advanced settings
-- accordionState is a Bootstrap accordion for manual save/load
-- formContent is a string that updates when a user types a load string
-- savedState is a string that stores the current settings, for save/load
type alias Model =
  { notes : List Note
  , volumeSlider : SingleSlider.SingleSlider Msg
  , oscillatorType : String
  , oscillatorDropdown : Dropdown.State
  , partialSlider : SingleSlider.SingleSlider Msg
  , addEnv : Envelope.Envelope
  , effectNum : Int
  , effects : Dict.Dict String Effect.Effect
  , effectsDropdown : Dropdown.State
  , envelopeTab : Tab.State
  , accordionState : Accordion.State
  , formContent : String
  , savedState : Maybe String
  }



-- The computer-key keyboard is implemented according to common DAW practices
-- Type on the keyboard as if it were a piano
initialModel : Model
initialModel =
  let
    minFormatter =
      \value -> ""

    maxFormatter =
      \value -> ""

    volumeValueFormatter =
      \value not_used_value -> "Volume: " ++ String.fromFloat value

    partialValueFormatter =
      \value not_used_value -> "Partial: " ++ String.fromFloat value
  in
  { volumeSlider =
    SingleSlider.init
      { min = 0
      , max = 100
      , value = 50
      , step = 1
      , onChange = SliderChange "volume"
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
      , onChange = SliderChange "partial"
      }
      |> SingleSlider.withMinFormatter minFormatter
      |> SingleSlider.withValueFormatter partialValueFormatter
      |> SingleSlider.withMaxFormatter maxFormatter
  , oscillatorDropdown =
    Dropdown.initialState
  , effectsDropdown =
    Dropdown.initialState
  , oscillatorType =
    "triangle"
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
  , effects = Dict.empty
  , effectNum = 0
  , savedState = Nothing
  , formContent = ""
  , accordionState = Accordion.initialState
  }


init : () -> ( Model, Cmd Msg )
init _ =
  ( initialModel, Cmd.none )



-- UPDATE ---------------------------------------------------------------------


type Msg
  = NoOp
  | NoteOn String
  | NoteOff String
  | TransposeUp
  | TransposeDown
  | SliderChange String Float
  | EnvMessage Envelope.Message
  | EffectMessage Effect.Message
  | OSCDropdownChange Dropdown.State
  | FXDropdownChange Dropdown.State
  | OscillatorChange String
  | AddFX String
  | TabChange Tab.State
  | PresetLoad (Maybe String)
  | Save
  | UpdateContent String
  | AccordionMsg Accordion.State


-- Activate a note when the user types on the keyboard
noteOn : String -> Model -> Model
noteOn key model =
  { model
    | notes =
      List.map
        (\note ->
          if note.key == key then
            { note | triggered = True }

          else
            note
        )
        model.notes
  }


-- Deactivate a note when the user lets go of the keyboard
noteOff : String -> Model -> Model
noteOff key model =
  { model
    | notes =
      List.map
        (\note ->
          if note.key == key then
            { note | triggered = False }

          else
            note
        )
        model.notes
  }


-- Transpose up one half-step
transposeUp : Model -> Model
transposeUp model =
  { model
    | notes = List.map (\note -> { note | midi = note.midi + 1 }) model.notes
  }


-- Transpose down one half-step
transposeDown : Model -> Model
transposeDown model =
  { model
    | notes = List.map (\note -> { note | midi = note.midi - 1 }) model.notes
  }


-- Calculate the frequency of the note that needs to be played
findKey : String -> Model -> Float
findKey s m =
  let
    test : Note -> Bool
    test n =
      n.key == s

    mainVal : List Note
    mainVal =
      List.filter test m.notes
  in
  case mainVal of
    [] ->
      0

    hd :: tail ->
      mtof hd.midi


-- Add an effect
addEffect : String -> ( Effect.Effect, String )
addEffect str =
  case str of
    "Distortion" ->
      ( Effect.init "Distortion"
        1
        [ "Distortion" ]
        [ ( 0, 1 ) ]
        [ ( 0, 0.01 ) ]
      , "Distortion"
      )

    "FeedbackDelay" ->
      ( Effect.init "FeedbackDelay"
        2
        [ "Delay", "Feedback", "Wet" ]
        [ ( 0, 1 ), ( 0, 1 ), ( 0, 1 ) ]
        [ ( 0, 0.01 ), ( 0, 0.01 ), ( 1, 0.01 ) ]
      , "FeedbackDelay"
      )

    "FrequencyShifter" ->
      ( Effect.init "FrequencyShifter"
        1
        [ "FrequencyShifter" ]
        [ ( 0, 1000 ) ]
        [ ( 0, 2 ) ]
      , "FrequencyShifter"
      )

    "BitCrusher" ->
      ( Effect.init "BitCrusher"
        1
        [ "BitCrusher" ]
        [ ( 1, 16 ) ]
        [ ( 1, 1 ) ]
      , "BitCrusher"
      )

    "Chebyshev" ->
      ( Effect.init "Chebyshev"
        1
        [ "Chebyshev" ]
        [ ( 2, 100 ) ]
        [ ( 2, 1 ) ]
      , "Chebyshev"
      )

    "HPFilter" ->
      ( Effect.init "HPFilter"
        1
        [ "HPFrequency" ]
        [ ( 1, 18000 ) ]
        [ ( 18000, 2 ) ]
      , "HPFilter"
      )

    "LPFilter" ->
      ( Effect.init "LPFilter"
        1
        [ "LPFrequency" ]
        [ ( 1, 18000 ) ]
        [ ( 1, 2 ) ]
      , "LPFilter"
      )

    _ ->
      Debug.todo "Effect needs to be included"


-- Takes messages and updates the model
update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SliderChange typ val ->
      let
        newModel : Model
        newModel =
          case typ of
            "volume" ->
              { model | volumeSlider = SingleSlider.update val model.volumeSlider }

            "partial" ->
              { model | partialSlider = SingleSlider.update val model.partialSlider }

            _ ->
              Debug.todo ("1undefined Slider Changed " ++ typ ++ "," ++ Debug.toString msg)

        message : String
        message =
          typ ++ "-" ++ Debug.toString val
      in
      ( newModel
      , makeAndSendAudio message
      )

    NoOp ->
      Tuple.pair model Cmd.none

    NoteOn key ->
      let
        val =
          findKey key model

        message : String
        message =
          "press-" ++ Debug.toString val
      in
      ( noteOn key model
      , makeAndSendAudio message
      )

    NoteOff key ->
      let
        val =
          findKey key model

        message : String
        message =
          "release-" ++ Debug.toString val
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

    EnvMessage envelopeMsg ->
      let
        ( newEnv, str ) =
          Envelope.update envelopeMsg model.addEnv
      in
      ( { model | addEnv = newEnv }
      , makeAndSendAudio str
      )

    EffectMessage fXMsg ->
      let
        name : String
        name =
          Debug.log "Effect Name" (Effect.getChangedName fXMsg)

        comp : Maybe Effect.Effect
        comp =
          Dict.get name model.effects
      in
      case comp of
        Nothing ->
          ( model, Cmd.none )

        Just effect ->
          let
            ( fx, message ) =
              Effect.update fXMsg effect

            rm : Bool
            rm =
              Effect.isRmMessage fXMsg
          in
          if rm then
            ( { model | effects = Dict.remove name model.effects }, makeAndSendAudio ("removeFX-" ++ name) )

          else
            ( { model | effects = Dict.insert name fx model.effects }, makeAndSendAudio ("changeFX-" ++ message) )

    OSCDropdownChange state ->
      ( { model | oscillatorDropdown = state }
      , Cmd.none
      )

    FXDropdownChange state ->
      ( { model | effectsDropdown = state }
      , Cmd.none
      )

    AddFX effectName ->
      let
        ( newFX, name ) =
          addEffect effectName
      in
      ( { model | effects = Dict.insert name newFX model.effects, effectNum = model.effectNum + 1 }
      , makeAndSendAudio ("addFX-" ++ effectName)
      )

    OscillatorChange st ->
      let
        message : String
        message =
          "oscillator-" ++ st
      in
      ( { model | oscillatorType = st }
      , makeAndSendAudio message
      )

    TabChange state ->
      ( { model | envelopeTab = state }
      , Cmd.none
      )

    PresetLoad str ->
      case str of
        Nothing ->
          ( model
          , Cmd.none
          )

        Just loadString ->
          let
            nModel : Model
            nModel =
              updateModel str model
          in
          ( nModel
          , makeAndSendAudio loadString
          )

    Save ->
      if floor (fetchValue model.partialSlider) == 0 then
        let
          currState : String
          currState =
            Debug.log "Saved String"
              ("loadPreset-#volume+"
                ++ String.fromFloat (fetchValue model.volumeSlider)
                ++ "#oscillator+"
                ++ model.oscillatorType
                ++ "#gainenv+attack+"
                ++ String.fromFloat (fetchValue model.addEnv.attack)
                ++ "#gainenv+decay+"
                ++ String.fromFloat (fetchValue model.addEnv.decay)
                ++ "#gainenv+sustain+"
                ++ String.fromFloat (fetchValue model.addEnv.sustain)
                ++ "#gainenv+release+"
                ++ String.fromFloat (fetchValue model.addEnv.release)
                ++ List.foldl (++) "" (List.map Effect.effectToString (Dict.values model.effects))
              )
        in
        ( { model | savedState = Just currState }
        , Cmd.none
        )

      else
        let
          currState : String
          currState =
            Debug.log "Saved String1"
              ("loadPreset-#volume+"
                ++ String.fromFloat (fetchValue model.volumeSlider)
                ++ "#oscillator+"
                ++ model.oscillatorType
                ++ "#partial+"
                ++ String.fromFloat (fetchValue model.partialSlider)
                ++ "#gainenv+attack+"
                ++ String.fromFloat (fetchValue model.addEnv.attack)
                ++ "#gainenv+decay+"
                ++ String.fromFloat (fetchValue model.addEnv.decay)
                ++ "#gainenv+sustain+"
                ++ String.fromFloat (fetchValue model.addEnv.sustain)
                ++ "#gainenv+release+"
                ++ String.fromFloat (fetchValue model.addEnv.release)
                ++ List.foldl (++) "" (List.map Effect.effectToString (Dict.values model.effects))
              )
        in
        ( { model | savedState = Just currState }
        , Cmd.none
        )

    UpdateContent str ->
      ( { model | formContent = str }
      , Cmd.none
      )

    AccordionMsg state ->
      ( { model | accordionState = state }
      , Cmd.none
      )



-- AUDIO ----------------------------------------------------------------------

-- Super simple utility function that takes a MIDI note number like 60 and
-- converts it to the corresponding frequency in Hertz. We use Float for the
-- MIDI number to allow for detuning, and we assume A4 is MIDI note number 69.
mtof : Float -> Float
mtof midi =
  440 * 2 ^ ((midi - 69) / 12)


-- Helper function to make black keys look pretty
getBlackOffset : Int -> Color -> Attribute msg
getBlackOffset num clr =
  case clr of
    B ->
      style "" ""

    W ->
      if num == 28 then
        style "border-right-width" "1px"

      else
        style "" ""


-- Used to load a saved string
-- Helper function for updateModel
fourWordParse : String -> String -> String -> String -> List Msg
fourWordParse a b c d =
  case a of
    "changeFX" ->
      let
        floatd : Maybe Float
        floatd =
          String.toFloat d
      in
      case floatd of
        Nothing ->
          [ NoOp ]

        Just z ->
          [ EffectMessage (Effect.makeEffectMessage b c z) ]

    _ ->
      [ NoOp ]


-- Used to load a saved string
-- Helper function for updateModel
threeWordParse : String -> String -> String -> List Msg
threeWordParse a b c =
  case a of
    "gainenv" ->
      let
        floatd : Maybe Float
        floatd =
          String.toFloat c
      in
      case floatd of
        Nothing ->
          [ NoOp ]

        Just z ->
          [ EnvMessage (Envelope.makeEnvMessage b z) ]

    _ ->
      [ NoOp ]


-- Used to load a saved string
-- Helper function for updateModel
twoWordParse : String -> String -> List Msg
twoWordParse a b =
  let
    floatd : Maybe Float
    floatd =
      String.toFloat b
  in
  case ( floatd, a ) of
    ( _, "oscillator" ) ->
      [ OscillatorChange b ]

    ( Just z, "volume" ) ->
      [ SliderChange "volume" z ]

    ( Just z, "partial" ) ->
      [ SliderChange "partial" z ]

    ( _, "addFX" ) ->
      [ AddFX b ]

    _ ->
      [ NoOp ]


-- Update the model so that the front-end displays the
-- changes that have occured in JS
updateModel : Maybe String -> Model -> Model
updateModel str model =
  case str of
    Nothing ->
      model

    Just updateString ->
      let
        sList : List String
        sList =
          Debug.log "String" (String.split "#" updateString)

        mapfunc : String -> List Msg
        mapfunc st =
          let
            s =
              Debug.log "StringParse" (String.split "+" st)
          in
          case s of
            [ a, b, c, d ] ->
              fourWordParse a b c d

            [ a, b, c ] ->
              threeWordParse a b c

            [ a, b ] ->
              twoWordParse a b

            _ ->
              Debug.log "No operation" [ NoOp ]

        foldfunc : Msg -> Model -> Model
        foldfunc ms ml =
          let
            ( newModel, backms ) =
              update ms ml
          in
          newModel

        prelis : List (List Msg)
        prelis =
          List.map mapfunc sList

        lis : List Msg
        lis =
          Debug.log "Semifinal List" (List.concat prelis)

        defModel : Model
        defModel =
          initialModel

        x : Model
        x =
          List.foldl foldfunc defModel lis
      in
      x



-- VIEW -----------------------------------------------------------------------


-- Use this to toggle the main styling on a note based on wheter it is currently
-- active or note. Basically just changes the background and font colour.
noteCSS : Int -> Bool -> Color -> String
noteCSS i active clr =
  case clr of
    W ->
      if active then
        "WhiteKeyActive"

      else
        "WhiteKey"

    B ->
      if active then
        "BlackKeyActive "

      else
        "BlackKey "



-- This takes a Note (as defined above) and converts that to some Notice
-- how we use the data for both the `voice` function and this `noteView` function.
-- Our audio graph should never become out of sync with our view!
noteView : Int -> Note -> Html Msg
noteView i note =
  div [ class <| noteCSS i note.triggered note.clr, class "Key", getBlackOffset i note.clr ]
    [ text note.key ]


-- Shows a card for an effect
viewEffect : String -> Effect.Effect -> Html Msg
viewEffect str fx =
  div [] [ Effect.view fx |> Html.map EffectMessage ]


-- Helper funciton for view to display a saved string, if there is one
maybeStringToString : Maybe String -> String
maybeStringToString s =
  case s of
    Nothing ->
      "Nothing saved."

    Just str ->
      str


-- The home page
view : Model -> Html Msg
view model =
  main_ []
    [ h1 []
      [ text "ElmSynth" ]
    , div [] [ SingleSlider.view model.volumeSlider ]
    , pre [] [ text "" ]
    , p []
      [ text "Type on the keyboard to play notes!" ]
    , div [] <|
      List.indexedMap noteView model.notes
    , pre [] [ text "" ]
    , div []
      [ Button.button [ Button.dark, Button.attrs [ Spacing.mr3, onClick TransposeUp ] ]
        [ text "Transpose up" ]
      , Button.button [ Button.dark, Button.attrs [ onClick TransposeDown ] ]
        [ text "Transpose down" ]
      ]
    , pre [] [ text "" ]
    , Tab.config TabChange
      |> Tab.items
        [ Tab.item
          { id = "tabItem1"
          , link = Tab.link [] [ text "Presets" ]
          , pane =
            Tab.pane [ Spacing.mt3 ]
              [ p [] [ text "Choose an instrument:" ]
              , Button.button
                [ Button.primary
                , Button.attrs
                  [ Spacing.mr3
                  , onClick (PresetLoad (Just "loadPreset-#gainenv+attack+0.0005#gainenv+decay+0.0005#gainenv+sustain+1#gainenv+release+0.7705#oscillator+sine#partial+0"))
                  ]
                ]
                [ text "Piano" ]
              , Button.button
                [ Button.primary
                , Button.attrs
                  [ Spacing.mr3
                  , onClick (PresetLoad (Just "loadPreset-#gainenv+attack+0.0005#gainenv+decay+0.4905#gainenv+sustain+0.2405#gainenv+release+1.8705#oscillator+sine#partial+1"))
                  ]
                ]
                [ text "Xylophone" ]
              , Button.button
                [ Button.primary
                , Button.attrs
                  [ Spacing.mr3
                  , onClick (PresetLoad (Just "loadPreset-#gainenv+attack+0.0005#gainenv+decay+0.5905#gainenv+sustain+0.1705#gainenv+release+0.0005#oscillator+square#partial+50"))
                  ]
                ]
                [ text "Bright" ]
              , Button.button
                [ Button.primary
                , Button.attrs
                  [ Spacing.mr3
                  , onClick (PresetLoad (Just "loadPreset-#gainenv+attack+0.0005#gainenv+decay+0.5905#gainenv+sustain+0.1705#gainenv+release+0.0005#oscillator+sawtooth#partial+50"))
                  ]
                ]
                [ text "Plucky" ]
              , Button.button
                [ Button.primary
                , Button.attrs
                  [ Spacing.mr3
                  , onClick (PresetLoad (Just "loadPreset-#gainenv+attack+0.0505#gainenv+decay+0.3705#gainenv+sustain+0.1405#gainenv+release+0.8905#oscillator+square#partial+50"))
                  ]
                ]
                [ text "Accordion" ]
              ]
          }
        , Tab.item
          { id = "tabItem2"
          , link = Tab.link [] [ text "Advanced Settings" ]
          , pane =
            Tab.pane [ Spacing.mt3 ]
              [ p []
                [ text ("Oscillator selected: " ++ String.Extra.toSentenceCase model.oscillatorType) ]
              , div []
                [ Dropdown.dropdown model.oscillatorDropdown
                  { options = [ Dropdown.alignMenuRight ]
                  , toggleMsg = OSCDropdownChange
                  , toggleButton = Dropdown.toggle [ Button.primary ] [ text "Change Oscillator Type" ]
                  , items =
                    [ Dropdown.buttonItem [ onClick (OscillatorChange "sine") ] [ text "Sine" ]
                    , Dropdown.buttonItem [ onClick (OscillatorChange "square") ] [ text "Square" ]
                    , Dropdown.buttonItem [ onClick (OscillatorChange "triangle") ] [ text "Triange" ]
                    , Dropdown.buttonItem [ onClick (OscillatorChange "sawtooth") ] [ text "Sawtooth" ]
                    ]
                  }
                ]
              , div [] [ SingleSlider.view model.partialSlider ]
              , pre [] [ text "" ]
              , p [] [ text "Toggle the sliders to create your own envelope:" ]
              , div [] [ Envelope.view model.addEnv |> Html.map EnvMessage ]
              , pre [] [ text "" ]
              , p [] [ text "Add/Remove Effects" ]
              , div [] (Dict.values (Dict.map viewEffect model.effects))
              , div []
                [ Dropdown.dropdown model.effectsDropdown
                  { options = [ Dropdown.alignMenuRight ]
                  , toggleMsg = FXDropdownChange
                  , toggleButton = Dropdown.toggle [ Button.primary ] [ text "Add Effect" ]
                  , items =
                    [ Dropdown.buttonItem [ onClick (AddFX "Distortion") ] [ text "Distortion" ]
                    , Dropdown.buttonItem [ onClick (AddFX "Chebyshev") ] [ text "Chebyshev" ]
                    , Dropdown.buttonItem [ onClick (AddFX "FrequencyShifter") ] [ text "FrequencyShifter" ]
                    , Dropdown.buttonItem [ onClick (AddFX "FeedbackDelay") ] [ text "FeedbackDelay" ]
                    , Dropdown.buttonItem [ onClick (AddFX "LPFilter") ] [ text "Low Pass Filter" ]
                    , Dropdown.buttonItem [ onClick (AddFX "HPFilter") ] [ text "High Pass Filter" ]
                    ]
                  }
                ]
              ]
          }
        ]
      |> Tab.view model.envelopeTab
    , pre [] [ text "" ]
    , p [] [ text "Save your current state and load it back in:" ]
    , Button.button [ Button.dark, Button.attrs [ Spacing.mr3, onClick Save ] ]
      [ text "Save" ]
    , Button.button [ Button.dark, Button.attrs [ Spacing.mr3, onClick (PresetLoad model.savedState) ] ]
      [ text "Load" ]
    , pre [] [ text "" ]
    , Accordion.config AccordionMsg
      |> Accordion.withAnimation
      |> Accordion.cards
        [ Accordion.card
          { id = "card1"
          , options = []
          , header =
            Accordion.header [] <| Accordion.toggle [] [ text "Manual Save/Load" ]
          , blocks =
            [ Accordion.block []
              [ Block.text []
                [ pre [] [ text "Saved state: " ]
                , p [] [ text (maybeStringToString model.savedState) ]
                , pre [] [ text "Manual load: " ]
                , input [ type_ "text", placeholder "loadPreset-#", value model.formContent, onInput UpdateContent ] []
                , Button.button [ Button.primary, Button.attrs [ onClick (PresetLoad (Just model.formContent)) ] ] [ text "Load" ]
                ]
              ]
            ]
          }
        ]
      |> Accordion.view model.accordionState
    , pre [] [ text "" ]
    ]



-- SUBSCRIPTIONS --------------------------------------------------------------


-- Send a string to JS to change the audio state
makeAndSendAudio : String -> Cmd msg
makeAndSendAudio lst =
  updateAudio (Encode.encode 0 (Encode.string lst))


-- Recognize what a user is typing on the keyboard
keyDecoder : Decode.Decoder String
keyDecoder =
  Decode.field "key" Decode.string


-- Respond to changes on the page
subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
    [ Browser.Events.onKeyDown (Decode.map (\key -> NoteOn key) keyDecoder)
    , Browser.Events.onKeyUp (Decode.map (\key -> NoteOff key) keyDecoder)
    , Dropdown.subscriptions model.oscillatorDropdown OSCDropdownChange
    , Dropdown.subscriptions model.effectsDropdown FXDropdownChange
    ]
