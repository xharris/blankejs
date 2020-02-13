exports.info = {
    name: "Array",
    author: "XHH",
    description: "Javascript-like Array structure",
    id: 'xhh-array',
    enabled: true
}

exports.autocomplete = {
    class_list: ['Array','Set'],
    instance: {
        'array': [
            /\b(\w+)\s*=\s*Array\(.*\)/g,
            /\b(\w+)\s*=\s*Set\(.*\)/g
        ]
    },
    hints: {
        'blanke-array':[
            {fn:'from',vars:{table:''}}
        ],
        'blanke-array-instance':[
            {fn:'push',vars:{val:'',etc:'opt'}},
            {prop:'length'}
        ]
    }
}