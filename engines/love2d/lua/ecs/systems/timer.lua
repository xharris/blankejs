--TIMER
Timer = nil 
do 
    local l_after = {}
    local l_every = {}
    local addTimer = function(t, fn, tbl)
        local id = uuid()
        local timer = {
            fn = fn,
            duration = t,
            t = t,
            iteration = 1,
            paused = false,
            destroy = function()
                tbl[id] = nil
            end
        }
        tbl[id] = timer
        return timer
    end

    Timer = {
        update = function(dt) 
            -- after
            for id,timer in pairs(l_after) do 
                if not timer.paused then
                    timer.t = timer.t - dt 
                    if timer.t < 0 then 
                        if timer.fn and timer.fn(timer) then 
                            -- another one (restart timer)
                            timer.t = timer.duration
                            timer.iteration = timer.iteration + 1
                        else 
                            -- destroy it
                            timer.destroy()
                        end
                    end
                end
            end
            -- every
            for id,timer in pairs(l_every) do
                if not timer.paused then 
                    timer.t = timer.t - dt 
                    if timer.t < 0 then 
                        if not timer.fn or timer.fn(timer) then 
                            -- destroy it!
                            timer.destroy()
                        else
                            -- restart timer
                            timer.t = timer.duration
                            timer.iteration = timer.iteration + 1
                        end
                    end
                end
            end
        end,
        after = function(t, fn) 
            addTimer(t, fn, l_after)
        end,
        every = function(t, fn) 
            addTimer(t, fn, l_every)
        end
    }
end