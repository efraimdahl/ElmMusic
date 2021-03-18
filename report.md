Efraim Dahl and Ellyn Liu
17 March 2021
ElmSynth Report

In this project, we created an online synthesizer using Elm, Tone.js, Elm-Web-Audio, and Elm-Bootstrap. There are several features to explore on the website, including the ability to:
* type on the keyboard to play notes,
* transpose the music up or down to adjust the range of notes,
* try different preset instruments sounds,
* experiment with advanced settings such as:
  * picking an oscillator to change the waveform: sine, square, triangle, or sawtooth,
  * choosing a partial value for the oscillator, which will change the amplitude at a harmonic
  * setting your own ADSR envelope (attack-decay-sustain-release) to further shape your sound, by customizing its changes over time.
  * adding and removing special effects: distortion, BitCrusher, Chebyshev, frequency shifter, feedback delay, low-pass filter, high-pass filter,
* and save and load your current state:
  * with the buttons, the most recently saved state will be loaded back in,
  * with manual save/load, copy and paste the saved strings so you can go back to a previous saved state.

Implementation Details

The keyboard was implemented using standard DAW practices, where letters on the computer keyboard correspond to specific keys on the piano. Transposing will shift all of the notes up or down one step. The preset instruments are implemented using a load function, where the oscillator type, partial value, ADSR envelope, and effects are stored as a string and loaded upon selecting a preset. For more advanced settings, there are sliders for the ADSR envelope and each effect.

The front-end buttons, dropdown menus, cards, tabs, and dropdown accordion were all implemented using Elm-Bootstrap. The sliders were implemented using Elm-Slider.

In this project, we found Elm’s type-checking and MVC useful, but using a functional language in tandem with JavaScript posed some challenges. Because we were using Tone.js to control the sound, the parts that the user interacted with in Elm had to be sent over a port into JavaScript. We sent strings to JavaScript, parsed them using special characters, and had a large case-switch statement to handle those changes. At first, we only changed values in JavaScript, which changed the audio state, but didn’t update the Elm model. But as the project expanded, we wanted to allow for saving and loading. In order to implement a save function in Elm, we had to continuously update the Elm model instead of only changing values in JavaScript. Similarly, we had to route updates through the main model in order to make effects and envelopes modular, so that any number of effects could be added.

Data structures used in this project include lists, dictionaries, and custom types for the envelope and effects. These were used to store values and sliders that the user would interact with.

If we wanted to expand upon this project, we could add more types of waveforms or allow for custom ones. Also, there are many more Tone.js effects that could be explored. The current envelope will only change the volume, but other envelopes could be implemented to change other parameters, such as an effect. There are other modes of sound synthesis, such as FM, AM, Subtractive, Additive and Granular synthesis that could also be explored.
