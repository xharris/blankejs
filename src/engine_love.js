const engine = {
    game_preview_enabled: false,
    main_file: 'main.lua',
    file_ext: 'lua',
    language: 'lua',
    code_associations: [
        [
            /[--state:(\w+)]/g,
            "state"
        ],[
            /[--entity:(\w+)]/g,
            "entity"
        ],
    ]
}