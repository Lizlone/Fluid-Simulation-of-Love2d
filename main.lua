require "func"
function love.load()
  -- x,y,n,d{}已经全局到了整个项目中
  n = 600
  x = nil
  y = nil
  ox = nil
  oy = nil
  mouse_down = nil
  fps = nil
  screen_width, screen_height = love.graphics.getDimensions()
  particles = {}
  color = {r = 22, g = 1, b = 1, a = 1}	-- still don't know how to set the correct color
  u = {}
  v = {}
  u_prev = {}
  v_prev = {}
  dens = {}
  dens_prev = {}
  diff = 0
  decay = 0.998
  dye_size = 1
  dens_val = 30
  for i = 1, (screen_width+2)*(screen_height+2) do
    u[i] = 0
    v[i] = 0
    u_prev[i] = 0
    v_prev[i] = 0
    dens[i] = 0
    dens_prev[i] = 0
  end
end
function love.update(dt)
  fps = 1/dt
  -- get x,y position
  x = nil
  y = nil
  if love.mouse.isDown(1) then
    x, y = love.mouse.getPosition()
  end
  -- simulate
  dye(dens_prev)
  slide(u_prev,v_prev)
  velocities(u, u_prev, v, v_prev, dt)
  densities(dens, dens_prev, u, v, dt)
end
function love.draw()
  local r = nil
  for j = 2, screen_height+1 do
    for i = 2, screen_width+1 do
      local ratio = dens[rn(i,j)]/10
      if ratio ~= 0 and ratio then
        r = ratio
      end
      particles[rn(i-1,j-1)] = {i-1+0.5, j-1+0.5, color.r * ratio, color.g * ratio, color.b * ratio, color.a}
    end
  end
  love.graphics.points(particles)
  if r~= 0 and r then
    love.graphics.print("ratio now is: "..r, 0, 40)
  else
    love.graphics.print("ratio now is: nil", 0, 40)
  end
  love.graphics.print("drawing", 0, 0)
  love.graphics.print("FPS: "..fps, 0, 20)
  love.graphics.print("corner dens: "..dens[rn(screen_width+1, screen_height+2)], 0, 60)
  love.graphics.print("corner dens type: "..type(dens[rn(screen_width+1, screen_height+2)]), 0, 80)
end