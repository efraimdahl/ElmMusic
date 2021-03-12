//Adopted from https://github.com/pd-andy/elm-web-audio/tree/master/example-->


/*
The variable prevOscType keeps track of the previous oscillator type that
was selected by the user. It will default to triangle if the user does
not input anything.
*/
var prevVolume = "50"
var prevOscType = "triangle"
var prevPartial = "0"
var prevGainEnv = ""

var savedStr = ""

export default class PolySynthPlayer {
  // Static Methods ============================================================
  static prepare (graph = []) {
      return graph
    }

  // Constructor ===============================================================
  constructor () {
  }


  addFX(synth, props, type){
    switch(type){
      case "Distortion":
        props.Distortion = new Tone.Distortion(0).toDestination()
        props.last.disconnect()
        props.last.connect(props.Distortion)
        props.last=props.Distortion
        break;
      case "Chebyshev":
        props.Chebyshev = new Tone.Chebyshev(1).toDestination()
        props.last.disconnect()
        props.last.connect(props.Chebyshev)
        props.last=props.Chebyshev
        break;
      case "BitCrusher":
        props.last.disconnect()
        props.BitCrusher = new Tone.BitCrusher(1).toDestination()
        props.last.connect(props.BitCrusher)
        props.last=props.BitCrusher
        break;
      case "FeedbackDelay":
        props.last.disconnect()
        props.FeedbackDelay = new Tone.FeedbackDelay(0, 0).toDestination()
        props.last.connect(props.FeedbackDelay)
        props.last=props.FeedbackDelay
        break;
      case "FrequencyShifter":
        props.last.disconnect()
        props.FrequencyShifter = new Tone.FrequencyShifter(0).toDestination()
        props.last.connect(props.FrequencyShifter)
        props.last=props.FrequencyShifter
        break;
     case "LPFilter":
        props.last.disconnect()
        props.LPFilter = new Tone.Filter(100, "lowpass").toDestination();
        props.last.connect(props.LPFilter)
        props.last=props.LPFilter
        break;
     case "HPFilter":
        props.last.disconnect()
        props.HPFilter =new Tone.Filter(100, "highpass").toDestination();
        props.last.connect(props.HPFilter)
        props.last=props.HPFilter
        break;
    }
  }
  changeFX(props, name, param, value){
    switch(name){
      case "Distortion":
        switch (param){
          case "Distortion":
            //console.log("changing distortion to: " + String(value))
            props.Distortion.distortion = value
            break;
        }
        break;
      case "FeedbackDelay":
        switch (param){
          case "Delay":
            props.FeedbackDelay.set({delayTime: value})
            break;
          case "Feedback":
            props.FeedbackDelay.set({feedback:value})
            break;
        }
        break;
      case "FrequencyShifter":
        switch (param){
          case "FrequencyShifter":
            props.FrequencyShifter.set({
              frequency: value,
            });
            break;
        }
        break;
      case "BitCrusher":
        switch (param){
          case "BitCrusher":
            props.BitCrusher.set({
              bits:value
            })
          break;
        }
        break;
      case "Chebyshev":
        switch (param){
          case "Chebyshev":
            console.log("changing Chebyshev to: " + String(value))
            props.Chebyshev.order = value
        }
        break;
      case "LPFilter":
        switch (param){
          case "LPFrequency":
            props.LPFilter.set({
              frequency: value,
            });
        }
        break;
      case "HPFilter":
        switch(param){
          case "HPFrequency":
            props.HPFilter.set({
              frequency: value,
            });
            break;
        }
        break;
      }
  }


  load (cmds, graph, synth, props) {
    let cmdAll = cmds.split('#');
    for (let i = 0; i < cmdAll.length; i++) {
      this.update (cmdAll[i], synth, props)
    }
  }


  // Public Methods ============================================================
  update (graph, synth, props) {
    //console.log(graph)
    //console.log(props)
    graph = graph.replace(/[&\/\\,()$~%'":*?<>{}]/g, '');
    let cmdLst = graph.split('-');
    //console.log(cmdLst[0],cmdLst.slice(1,))
    let pre = 0

    switch(cmdLst[0]){
      case 'press':
        //synth.triggerAttackRelease("420", "8n");
        pre = cmdLst[1].split('.')[0]
        //console.log(props.activeVoices)
        if (props.activeVoices.find(element => element==pre)){
          break;
        }
        else {
          synth.triggerAttack(pre, Tone.now(), 0.2)
          props.activeVoices.push(pre)
        }
        break;

      case 'release':
        pre = cmdLst[1].split('.')[0]
        props.activeVoices.splice(props.activeVoices.indexOf(pre), 1)
        synth.triggerRelease(pre, Tone.now())
        break;

      case 'volume':
        pre = cmdLst[1].split('.')[0]
        prevVolume = pre
        if (pre == 0) {
          synth.volume.value = -100
        }
        else {
          synth.volume.value = Math.log10(pre) * 9 - 18
        }
        break;

      case 'oscillator':
        synth.set({oscillator:{type:cmdLst[1]}})
        prevOscType = cmdLst[1]
        break;

      case 'partial':
        let num = cmdLst[1].split('.')[0]
        prevPartial = num
        let newType = ""
        newType = prevOscType.concat(num)
        synth.set({oscillator:{type:newType}})
        break;

      case 'gainenv':
        switch(cmdLst[1]) {
          case 'attack':
            pre = parseFloat(cmdLst[2])
            props.envelope.attack=pre
            //console.log(props.envelope)
            synth.set({"envelope":props.envelope})
            break;
          case 'decay':
            pre = parseFloat(cmdLst[2])
            props.envelope.decay=pre
            //console.log(props.envelope)
            synth.set({"envelope":props.envelope})
            break;
          case 'sustain':
            pre = parseFloat(cmdLst[2])
            props.envelope.sustain=pre
            //console.log(props.envelope)
            synth.set({"envelope":props.envelope})
            break;
          case 'releaseEnv':
            pre = parseFloat(cmdLst[2])
            props.envelope.release=pre
            //console.log(props.envelope)
            synth.set({"envelope":props.envelope})
            break;
        }
        break;

      case 'addFX':
        this.addFX(synth, props, cmdLst[1])
        break;

      case 'changeFX':
        this.changeFX(props, cmdLst[1], cmdLst[2], cmdLst[3])
        break;

      case 'loadPreset':
        //console.log("cmdLst[1]: ", cmdLst[1])
        let remakeCmds = cmdLst[1].split('+').join('-') //slice(1,).join('#')
        //console.log("remakeCmds: ", remakeCmds)
        this.load(remakeCmds, graph, synth, props)
        break;

    }
  }
}
