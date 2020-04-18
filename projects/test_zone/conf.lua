io.stdout:setvbuf('no')

      package.path = "./lua/?/init.lua;./lua/?;" .. package.path
      require("blanke")
      
function love.conf(t)
    t.console = true
    
    t.window.title = "test_zone"
    -- t.gammacorrect = nil

end
