import React from 'react';

const importAll = (r) => r.keys().map(r);


const icons = importAll(require.context('./../../icons',false,/\.svg/));

export const SVG = (name) => (
    <img src={icons[name]} alt={name}/>
);