/**
 * Name: Tween.js
 * Author: Tween.js @ <a href='https://github.com/tweenjs'>Github</a>
 * Description: JavaScript tweening engine for easy animations, incorporating optimised Robert Penner's equations.
 * ID: xhh-tween
 */

document.addEventListener('blankeLoaded',(e)=>{
    let blanke = e.detail.Blanke;
    blanke.Event.on('update',(dt)=>{
        TWEEN.update();
    })
})