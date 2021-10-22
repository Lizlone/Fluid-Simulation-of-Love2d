function rn(i, j)  -- 返回二维数组在一维数组中的位置
  return i + (j - 1) * screen_width
end
function dye(d)  -- 将粒子（浓度）注入，浓度为dens_val
  if love.mouse.isDown(1) then
    for i = 1, screen_width+2 do
      for j = 1, screen_height+2 do
        if math.pow(i-x, 2) + math.pow(j-y, 2) <= math.pow(dye_size, 2) then
          d[rn(i,j)] = dens_val
        end
      end
    end
  end
end
function slide(u, v)  -- 获得鼠标滑动的速度
  if love.mouse.isDown(1) then
    if ox and oy then
      local dx = x - ox
      local dy = y - oy
      for i = 1, screen_width + 2 do
        for j = 1, screen_height + 2 do
          if i == x and j == y then
            u[rn(i,j)] = dx
            v[rn(i,j)] = dy
          end
        end
      end
    end
    ox = x
    oy = y
  end
end
function velocities(u, u0, v, v0, dt)  -- 速率场变化
  u0, u = add_sourse(u, u0, dt)
  v0, v = add_sourse(v, v0, dt)
  u, u0 = diffuse(1, u, u0, dt)
  v, v0 = diffuse(2, v, v0, dt)
  u0, u, v0, v = project(u, u0, v, v0)
  u, u0 = advect(1, u, u0, u0, v0, dt)
  v, v0 = advect(2, v, v0, u0, v0, dt)
  u, u0, v, v0 = project(u, u0, v, v0)
end
function densities(d, d0, u, v, dt)  -- 流体的（粒子）密度变化
  d0, d = add_sourse(d, d0, dt)
  -- 浓度增加太快，所以取消了diffuse()
--   d0, d = diffuse(0, d, d0, dt)  -- dens_val增长过快
  set_boundary(0,d0)
  d = d0
  d, d0 = advect(0, d, d0, u, v, dt)
  for i = 1, (screen_width+2)*(screen_height+2) do
    d[i] = d[i] * decay
  end
end
function add_sourse(ori, new, dt)  -- 加入新增的浓度/速度
  for i = 1, (screen_width+2)*(screen_height+2) do
    ori[i] = ori[i] + dt * new[i]
  end
  return ori, new
end 
function diffuse(boundary, d, d0, dt)  -- 流体的扩散
   local a = dt * diff * screen_width * screen_height
  ---- origin.ver
  -- for j = 2, screen_height + 1 do
  --   for i = 2, screen_width + 1 do
  --     d[rn(i, j)] = d0[rn(i, j)] + a * (d[rn(i - 1, j)] + d[rn(i + 1, j)] + d[rn(i, j - 1)] + d[rn(i, j + 1)])
  --   end
  -- end
  --   set_boundary(boundary, d)
  
  ---- Gauss-Seidel relaxation.ver
  for k = 1, 20 do
    for j = 2, screen_height + 1 do
      for i = 2, screen_width + 1 do
        d[rn(i, j)] = d0[rn(i, j)] + a * (d[rn(i - 1, j)] + d[rn(i + 1, j)] + d[rn(i, j - 1)] + d[rn(i, j + 1)]) / (1+4*a)
      end
    end
    set_boundary(boundary, d)
  end
  return d, d0
end
function advect(boundary, d, d0, u, v, dt)  -- 流体平流输送
  local dtu, dtv, dx, dy, top, bottom, left, right, s, s0, t, t0
  dtu = dt * screen_width
  dtv = dt * screen_height
  for j = 2, screen_height + 1 do
    for i = 2, screen_width + 1 do
      dx = i - dtu * u[rn(i, j)]
      dy = j - dtv * v[rn(i, j)]
      if dx < 1.5 then
        dx = 1.5
      elseif dx > screen_width + 2.5 then
        dx = screen_width + 2.5
      end
      if dy < 1.5 then
        dy = 1.5
      elseif dy > screen_height + 2.5 then
        dy = screen_height + 2.5
      end
      bottom = math.floor(dy)
      top = bottom + 1
      left = math.floor(dx)
      right = left + 1
      s = dx - left
      s0 = 1 - s
      t = dy - bottom
      t0 = 1 - t
      d[rn(i, j)] = t0 * (s * d0[rn(right, bottom)] + s0 * d0[rn(left, bottom)]) + t * (s * d0[rn(right, top)] + s0 * d0[rn(left, top)])
    end
  end
  set_boundary(boundary, d)
  return d, d0
end
function set_boundary(b, x)  -- 设置反弹的边界
  if b == 1 then
    for j = 2, screen_height + 1 do
      x[rn(3,j)] = -x[rn(4,j)]
      x[rn(screen_width-1,j)] = -x[rn(screen_width,j)]
    end
  else
    for j = 2, screen_height + 1 do
      x[rn(3,j)] = x[rn(4,j)]
      x[rn(screen_width-1,j)] = x[rn(screen_width,j)]
    end
  end
  if b == 2 then
    for i = 2, screen_width + 1 do
      x[rn(i,1)] = -x[rn(i,2)]
      x[rn(i,screen_height+2)] = -x[rn(i,screen_height+1)]
    end
  else
    for i = 2, screen_width + 1 do
      x[rn(i,1)] = x[rn(i,2)]
      x[rn(i,screen_height+2)] = x[rn(i,screen_height+1)]
    end
  end
  x[rn(1,1)] = 0.5 * (x[rn(2,1)] + x[rn(1,2)])
  x[rn(1,screen_height+2)] = 0.5 * (x[rn(2,screen_height+2)] + x[rn(1,screen_height+1)])
  x[rn(screen_width+2,1)] = 0.5 * (x[rn(screen_width+1,1)] + x[rn(screen_width+2,2)])
  x[rn(screen_width+2,screen_height+2)] = 0.5 * (x[rn(screen_width+1,screen_height+2)] + x[rn(screen_width+2,screen_height+1)])
end
function project(u, u0, v, v0)  -- 优化结果
  local h = 1 / math.sqrt(screen_height * screen_width)
  for i = 2, screen_width + 1 do
    for j = 2, screen_height + 1 do
      v0[rn(i,j)] = -0.5*h*(u[rn(i+1,j)] - u[rn(i-1,j)] + v[rn(i,j+1)] - v[rn(i,j-1)])
      u0[rn(i,j)] = 0
    end
  end
  set_boundary(0, v0)
  set_boundary(0, u0)
  for k = 1, 20 do
    for i = 2, screen_width + 1 do
      for j = 2, screen_height + 1 do
        u0[rn(i,j)] = (v0[rn(i,j)] + u0[rn(i-1,j)] + u0[rn(i+1,j)] + u0[rn(i,j-1)] + u0[rn(i,j+1)]) / 4
      end
    end
    set_boundary(0, u0)
  end
  for i = 2, screen_width + 1 do
    for j = 2, screen_height + 1 do
      u[rn(i,j)] = u[rn(i,j)] - 0.5*screen_width*(u0[rn(i+1,j)] - u0[rn(i-1,j)])
      v[rn(i,j)] = v[rn(i,j)] - 0.5*screen_height*(u0[rn(i,j+1)] - u0[rn(i,j-1)])
    end
  end
  set_boundary(1, u)
  set_boundary(2, v)
  return u, u0, v, v0
end