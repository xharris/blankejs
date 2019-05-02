import React, { Component } from 'react';
import { Icon } from './Icon';

class Button extends Component {
    render = () => {
        return (
        <button 
            id={`btn-${this.props.id}`} 
            onClick={this.props.onClick}
        >
            <Icon name="run"/>
        </button>    
    )}
}

export default Button;