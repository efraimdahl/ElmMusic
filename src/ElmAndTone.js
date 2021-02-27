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
  update (graph,synth,props) {
    console.log(graph)
    console.log(props)
    graph = graph.replace(/[&\/\\#,+()$~%'":*?<>{}]/g, '');
    let cmdLst = graph.split('-');
    console.log(cmdLst[0],cmdLst[1])
    let pre= 0
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
        synth.triggerRelease(pre,Tone.now())
        break;
    }
  }
}