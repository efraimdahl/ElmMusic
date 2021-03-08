//Adopted from https://github.com/pd-andy/elm-web-audio/tree/master/example-->


/*
The variable prev_osc_type keeps track of the previous oscillator type that
was selected by the user. It will default to triangle if the user does
not input anything.
*/
var prev_osc_type = "triangle"

export default class PolySynthPlayer {
  // Static Methods ============================================================
  static prepare (graph = []) {
      return graph
    }

  // Constructor ===============================================================
  constructor () {
  }


  addFX(synth,props,type){
    switch(type){
      case "Distortion":
        props.Distortion = new Tone.Distortion(0).toDestination()
        synth.connect(props.Distortion)
        break;
      case "Chebyshev":
        props.Chebyshev = new Tone.Chebyshev(1).toDestination()
        synth.connect(props.Chebyshev)
        break;
      case "BitCrusher":
        props.BitCrusher = new Tone.BitCrusher(1).toDestination()
        synth.connect(props.BitCrusher)
        break;
      case "FeedbackDelay":
        props.FeedbackDelay = new Tone.FeedbackDelay(0,0).toDestination()
        synth.connect(props.FeedbackDelay)
        break;
      case "FrequencyShifter":
        props.FrequencyShifter = new Tone.FrequencyShifter(0).toDestination()
        synth.connect(props.FrequencyShifter)
        break;
    }
  }
  changeFX(props,name,param,value){
    switch(name){
      case "Distortion":
        switch (param){
          case "Distortion":
            console.log("changing distortion to: " + String(value))
            props.Distortion.distortion = value
            break;
        }
        break;
      case "FeedbackDelay":
        switch (param){
          case "Delay":
            console.log("changing distortion to: " + String(value))
            props.FeedbackDelay.delayTime = value
            break;
          case "Feedback":
            props.FeedbackDelay.feedback = value
            break;
        }
        break;
      case "FrequencyShifter":
        switch (param){
          case "FrequencyShifter":
            props.FrequencyShifter.frequency = value
            break;
        }
        break;
      case "BitCrusher":
        switch (param){
          case "BitCrusher":
            props.BitCrusher.bits = value
        }
        break;
      case "Chebyshev":
        switch (param){
          case "Chebyshev":
            console.log("changing Chebyshev to: " + String(value))
            props.Chebyshev.order = value
        }
        break;
  }
}
  // Public Methods ============================================================
  update (graph,synth,props,osc) {
    console.log(graph)
    console.log(props)
    graph = graph.replace(/[&\/\\#,+()$~%'":*?<>{}]/g, '');
    let cmdLst = graph.split('-');
    console.log(cmdLst[0],cmdLst[1])
    let pre = 0

    switch(cmdLst[0]){
      case 'press':
        //synth.triggerAttackRelease("420", "8n");
        pre = cmdLst[1].split('.')[0]
        console.log(props.activeVoices)
        if(props.activeVoices.find(element => element==pre)){
          break;
        }
        else {
          synth.triggerAttack(pre,Tone.now(),0.2)
          props.activeVoices.push(pre)
        }
        break;
      case 'release':
        pre = cmdLst[1].split('.')[0]
        props.activeVoices.splice(props.activeVoices.indexOf(pre),1)
        synth.triggerRelease(pre,Tone.now())
        break;
      case 'volume':
        pre = cmdLst[1].split('.')[0]
        if (pre == 0) {
          synth.volume.value = -100
        }
        else {
          synth.volume.value = Math.log10(pre) * 9 - 18
        }
        break;
      case 'partial':
        let num = cmdLst[1].split('.')[0]
        let new_type = ""
        new_type = prev_osc_type.concat(num)
        synth.set({oscillator:{type:new_type}})
        break;
      case 'gainenv':
        switch(cmdLst[1]) {
          case 'attack':
            pre = parseFloat(cmdLst[2])
            props.envelope.attack=pre
            console.log(props.envelope)
            synth.set({"envelope":props.envelope})
            break;
          case 'decay':
            pre = parseFloat(cmdLst[2])
            props.envelope.decay=pre
            console.log(props.envelope)
            synth.set({"envelope":props.envelope})
            break;
          case 'sustain':
            pre = parseFloat(cmdLst[2])
            props.envelope.sustain=pre
            console.log(props.envelope)
            synth.set({"envelope":props.envelope})
            break;
          case 'releaseEnv':
            pre = parseFloat(cmdLst[2])
            props.envelope.release=pre
            console.log(props.envelope)
            synth.set({"envelope":props.envelope})
            break;
        }
        break;
      case 'oscillator':
        synth.set({oscillator:{type:cmdLst[1]}})
        prev_osc_type = cmdLst[1]
        break;
      case 'addFX':
        this.addFX(synth,props,cmdLst[1])
        break;
      case 'changeFX':
        this.changeFX(props,cmdLst[1],cmdLst[2],cmdLst[3])
        break;
    }
    }
  }

