import React from 'react';
import "./../../scss/components/Button.scss";

// construct list of svg icons
const importAll = (r) => {
   return r.keys().map(r);
};
const re_icon_path = /\/([\w_-]+)\.[\w\d]+\.svg/;
const icons = {};
importAll(require.context('./../../icons',false,/\.svg/)).forEach((v) => {
    icons[re_icon_path.exec(v)[1]] = v; 
});

export const Icon = (props) => {
    console.log(props)
    return (
    <img className="Icon" src={icons[props.name]} alt={props.name}/>
)};