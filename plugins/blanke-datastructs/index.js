exports.info = {
    name: "Array",
    author: "XHH",
    description: "Javascript-like Array structure",
    id: 'xhh-array',
    enabled: true
}

exports.autocomplete = {
    class_list: ['Array'],
    instance: {
        'array': /\b(\w+)\s*=\s*Array\(.*\)/g
    },
    hints: {
        'blanke-array':[
            {fn:'from',vars:{table:''}}
        ],
        'blanke-array-instance':[
            {fn:'push',vars:{val:'',etc:'opt'}}
        ]
    }
}