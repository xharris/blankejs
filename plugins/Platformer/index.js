exports.info = {
    name: "Platformer",
    author: "XHH",
    description: "Quick platformer hitbox setup for Entity class",
    id: 'xhh-platformer',
    enabled: true
}

exports.autocomplete = {
    hints:{
        "blanke-entity-instance":[
            { fn: 'addPlatforming', vars: { options:'{ width, height, callbacks{head, body, feet} }' } }
        ]
    }
}
