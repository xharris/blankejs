exports.info = {
    name: "Platformer",
    author: "XHH",
    description: "Quick platformer hitbox setup for Entity class",
    id: 'xhh-platformer',
    enabled: false
}

exports.autocomplete = {
    hints:{
        "blanke-entity-instance":[
            { fn: 'addPlatforming', vars: { w:'opt', h:'opt' } }
        ]
    }
}
