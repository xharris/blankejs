import React, { Component } from 'react';

import "./scss/main.scss";
import "./App.css";
/*
import Button from './js/components/Button';

export const themes = {
  green: {
    "ide-accent": "#5ad9a4",
    "theme-string": "#97e7c6",
    "theme-list-active-bg": "#233e2e",
    "theme-text-sub": "#e6ee9c",
    "theme-text-optional": "#b2dfdb"
  },
  pink: {
    "ide-accent": "#f48fb1",
    "theme-string": "#f9bed2",
    "theme-list-active-bg": "#3b2138",
    "theme-text-sub": "#ee9cd3",
    "theme-text-optional": "#dfb2d9"
  }
}

export const CtxApp = React.createContext({
  theme: "green" 
})

export const runGame = () => {

}
*/
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
        <header className="App-header">
          <img className="App-logo" alt="logo" />
          <p>
            Edit <code>src/App.js</code> and save to reload.
          </p>
          <a
            className="App-link"
            href="https://reactjs.org"
            target="_blank"
            rel="noopener noreferrer"
          >
            Learn React
          </a>
        </header>
      </div>
    );
  }
}

export default App;
