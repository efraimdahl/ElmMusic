/* global AudioContext */
//Adopted from https://github.com/pd-andy/elm-web-audio/tree/master/example-->

import PolySynthPlayer from './src/ElmAndTone.js'


// Initialize a synthesizer in Tone.js
const audio = new PolySynthPlayer()

const synth = new Tone.PolySynth(Tone.Synth, {
  oscillator: {
    type : "triangle",
    partials: [0, 2, 3, 4],
  }
})

// Plays these notes upon loading the page
synth.triggerAttackRelease(["C4", "E4", "A4"], 1);

// Set an envelope for the starting state
let env = {
	"attack" : 0.0005,
	"decay" : 0.2,
	"sustain" : 1,
	"release" : 0.8,
};

synth.set({"envelope":env})

const App = Elm.ElmAndTone.init({
  node: document.querySelector('#app')
})
let props={activeVoices : [],envelope : env,last:[synth]}
synth.connect(Tone.Destination)
App.ports.updateAudio.subscribe(function(graph){
  audio.update(graph,synth,props)
})
