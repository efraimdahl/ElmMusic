//Adopted from https://github.com/pd-andy/elm-web-audio/tree/master/example-->


/*
The variable prevOscType keeps track of the previous oscillator type that
was selected by the user. It will default to triangle if the user does
not input anything.
*/

var prevOscType = "triangle"


export default class PolySynthPlayer {
  // Static Methods ============================================================
  static prepare (graph = []) {
      return graph
    }

  // Constructor ===============================================================
  constructor () {
  }

  getAssoc(props,str){
    switch(str){
      case "Distortion":
        return props.Distortion
      case "Chebyshev":
        return props.Chebyshev
      case "BitCrusher":
        return props.BitCrusher
      case "FeedbackDelay":
        return props.FeedbackDelay
      case "FrequencyShifter":
        return props.FrequencyShifter
     case "LPFilter":
        return props.LPFilter
     case "HPFilter":
        return props.HPFilter
    }
  }

  addFX(synth, props, type){
    let dex = props.last.length-1
    switch(type){
      case "Distortion":
        props.Distortion = new Tone.Distortion(0).toDestination()
        props.last.push(props.Distortion)
        props.last[dex].disconnect()
        props.Distortion.wet.value = 1
        props.last[dex].connect(props.Distortion)
        break;
      case "Chebyshev":
        props.Chebyshev = new Tone.Chebyshev(1).toDestination()
        props.Chebyshev.wet.value = 1
        props.last[dex].disconnect()
        props.last[dex].connect(props.Chebyshev)
        props.last.push(props.Chebyshev)
        break;
      case "BitCrusher":
        props.last[dex].disconnect()
        props.BitCrusher = new Tone.BitCrusher(1).toDestination()
        props.BitCrusher.wet.value = 1
        props.last[dex].connect(props.BitCrusher)
        props.last.push(props.BitCrusher)
        break;
      case "FeedbackDelay":
        props.last[dex].disconnect()
        props.FeedbackDelay = new Tone.FeedbackDelay(0, 0).toDestination()
        props.FeedbackDelay.wet.value = 1
        props.last[dex].connect(props.FeedbackDelay)
        props.last.push(props.FeedbackDelay)
        break;
      case "FrequencyShifter":
        props.last[dex].disconnect()
        props.FrequencyShifter = new Tone.FrequencyShifter(0).toDestination()
        props.FrequencyShifter.wet.value = 1
        props.last[dex].connect(props.FrequencyShifter)
        props.last.push(props.FrequencyShifter)
        break;
     case "LPFilter":
        props.last[dex].disconnect()
        props.LPFilter = new Tone.Filter(100, "lowpass").toDestination();
        props.last[dex].connect(props.LPFilter)
        props.last.push(props.LPFilter)
        break;
     case "HPFilter":
        props.last[dex].disconnect()
        props.HPFilter =new Tone.Filter(100, "highpass").toDestination();
        props.last[dex].connect(props.HPFilter)
        props.last.push(props.HPFilter)
        break;
    }
  }
  //not a real disconnect, more of a turning of.
  removeFX(synth, props, type){
    this.getAssoc(props,type).dispose();
    delete(this.getAssoc(props,type));
    for(let i = 0;i<props.last.length;i++){
      if(props.last[i].name==type){
        if(i=props.last.length-1)
          props.last[i-1].connect(Tone.Destination)
        else{
          props.last[i-1].connect(props.last[i+1])
        }
        props.last.splice(i, 1);
      }
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
          case "Wet":
            props.FeedbackDelay.wet.value=value
            break
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
    console.log(props)
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
      case 'removeFX':
        this.removeFX(synth,props,cmdLst[1])
        break;
      case 'changeFX':
        this.changeFX(props, cmdLst[1], cmdLst[2], cmdLst[3])
        break;

      case 'loadPreset':
        //remove all effects:
        console.log(props)
        for(let i = 1;i < props.last.length;i++){
          this.getAssoc(props,props.last[i].name).dispose()
          delete(this.getAssoc(props,props.last[i].name))
          props.last.splice(i, 1);  
        }
        let env = {
	        "attack" : 0.0005,
	        "decay" : 0.2,
	        "sustain" : 1,
	        "release" : 0.8,
          };
        synth.set({"envelope":env})
        let newRay = [synth]
        let nprops = {activeVoices : [],envelope : env,last:newRay}
        props=nprops
        props.last=newRay
        synth.connect(Tone.Destination)
        //console.log("cmdLst[1]: ", cmdLst[1])
        let remakeCmds = cmdLst[1].split('+').join('-') //slice(1,).join('#')
        //console.log("remakeCmds: ", remakeCmds)
        this.load(remakeCmds, graph, synth, props)
        break;

    }
  }
}
