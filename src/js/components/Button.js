import React, { Component } from 'react';
import { SVG } from './Svg';

class Button extends Component {
    render = () => {
        return (
        <button 
            id={`btn-${this.props.id}`} 
            onClick={this.props.onClick}
        >
        {
            this.props.icon == null ? this.props.id :
            (
                <SVG name="play"/>
            )
        }
        </button>    
    )}
}

export default Button;