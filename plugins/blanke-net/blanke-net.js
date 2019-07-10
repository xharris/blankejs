/**
 * Name: Net.js
 * Author: XHH
 * Description: Simple networking plugin for BlankE. Uses socket.io
 */

var Net = {
    join: () => {
        console.log("ive joined >:)");
        const socket = io('http://localhost');
    },
    disconnect: () => {}
}