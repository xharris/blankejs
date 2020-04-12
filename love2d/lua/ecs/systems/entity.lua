local callbacks = {'update','draw','add','remove'}

Entity = callable {
  __call = function(_, name, template)
    template = copy(template)
    extract(template,'pos')
    extract(template,'vel')
    -- move callbacks to a system 
    local sys_info = {type=name}
    local add_system = false
    for _, cb_name in ipairs(callbacks) do 
      if type(template[cb_name]) == 'function' then 
        add_system = true
        sys_info[cb_name] = template[cb_name]
        template[cb_name] = nil
      end
    end
    if add_system then 
      System(sys_info)
    end
    return Spawner(name, template)
  end
}