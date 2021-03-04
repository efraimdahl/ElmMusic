//Adopted from https://github.com/pd-andy/elm-web-audio/tree/master/example-->

export default class PolySynthPlayer {
  // Static Methods ============================================================
  //
  static prepare (graph = []) {
      return graph
    }

  // Constructor ===============================================================
  //
  constructor () {


  }


  // Public Methods ============================================================
  //
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
      case 'sine':
        synth.set({oscillator:{type:'sine'}})
        break;
      case 'square':
        synth.set({oscillator:{type:'square'}})
        break;
      case 'triangle':
        synth.set({oscillator:{type:'triangle'}})
        break;
      case 'sawtooth':
        synth.set({oscillator:{type:'sawtooth'}})
        break;
      }
    }
  }
