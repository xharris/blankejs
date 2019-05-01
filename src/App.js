import React, { Component } from 'react';

import "./scss/main.scss";
import "./App.css";

import Button from "./js/components/Button";
/*
export const CtxApp = React.createContext({
  theme: "green" 
})
*/

export const runGame = () => {

}

class App extends Component {
  /*
  constructor(props) {
    //const ctxApp = useContext(CtxApp);
		//less.modifyVars(themes["green"]);
		//less.refresh();

    return super();
  }
  */

  render() {
    return (
      <div className="App theme-green">
        <Button id="play" svg="run" onClick={runGame}/>
      </div>
    );
  }
}

export default App;
