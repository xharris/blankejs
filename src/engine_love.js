const engine = {
    game_preview_enabled: false,
    main_file: 'main.moon',
    file_ext: 'moon',
    language: 'coffeescript',
    code_associations: [
        [
            /[--state:(\w+)]/g,
            "state"
        ],[
            /[--entity:(\w+)]/g,
            "entity"
        ],
    ],

}