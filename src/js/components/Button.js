import React, { Component } from 'react';

class Button extends Component {
    render = () => (
        <button 
            id={`btn-${this.props.id}`} 
            onClick={this.props.onClick}
        >
        {
            this.props.svg == null ? null :
            (
                <object 
                    className="blanke-icon" 
                    data={`icons/${this.props.svg}.svg`} 
                    type="image/svg+xml">{this.props.svg}</object>
            )
        }
        </button>    
    )
}

export default Button;