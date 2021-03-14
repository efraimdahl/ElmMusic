/* global AudioContext */
//Adopted from https://github.com/pd-andy/elm-web-audio/tree/master/example-->

import PolySynthPlayer from './src/ElmAndTone.js'

const audio = new PolySynthPlayer()

const synth = new Tone.PolySynth(Tone.Synth, {
  oscillator: {
    type : "triangle",
    partials: [0, 2, 3, 4],
  }
})

synth.triggerAttackRelease(["C4", "E4", "A4"], 1);

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
let props={activeVoices : [],envelope : env,last:Tone.Destination}
synth.connect(props.last)
props.last=synth
App.ports.updateAudio.subscribe(function(graph){
  audio.update(graph,synth,props)
})
