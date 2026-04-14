pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
local posx, posy = 64, 64
local speed = 1.2
local bspeed = 0.5

local mx, my = 64, 64

local velx, vely = 0, 0
local accelx, accely = 0, 0
local friction = 0.95

local hatched = false

function _init()
    poke(0x5f2d, 1)
end

-- custom function by the community thank you so much omg i wanna kiss whoever made this
function rspr(s,x,y,a)
    local sx=(s%16)*8
    local sy=flr(s/16)*8
    for i=0,7 do
        for j=0,7 do
            local c=sget(sx+i,sy+j)
            if c!=0 then 
                local dx,dy=i-3.5,j-3.5
                local rx=x+dx*cos(a)-dy*sin(a)
                local ry=y+dx*sin(a)+dy*cos(a)
                pset(rx,ry,c)
            end
        end
    end
end

function _update()

    if not hatched then
        if btn(4) then hatched=true end

    else
        velx += accelx
        vely += accely

        accelx, accely = 0, 0

        velx *= friction
        vely *= friction

        posx += velx
        posy += vely

        if velx > 4 then velx = 4 end
        if velx < -4 then velx = -4 end
        if vely > 4 then vely = 4 end
        if vely < -4 then vely = -4 end

        if btn(4) then
            hatched = true

            if btn(0) then velx -= bspeed end
            if btn(1) then velx += bspeed end
            if btn(2) then vely -= bspeed end
            if btn(3) then vely += bspeed end

            if posx<4 then posx=4 velx*=-0.5 end
            if posx>123 then posx=123 velx*=-0.5 end
            if posy<12 then posy=12 vely*=-0.5 end
            if posy>115 then posy=115 vely*=-0.5 end
        else
            if btn(0) then posx -= speed end
            if btn(1) then posx += speed end
            if btn(2) then posy -= speed end
            if btn(3) then posy += speed end

            if posx<4 then posx=4 end
            if posx>123 then posx=123 end
            if posy<12 then posy=12 end
            if posy>115 then posy=115 end

            velx, vely = 0, 0
        end

        mx = stat(32)
        my = stat(33)
    end
end

function _draw()
    cls()
  

    local x_dist = mx - posx
    local y_dist = my - posy
    local ang = atan2(x_dist, y_dist)
    local endx = posx + cos(ang) * 15
    local endy = posy + sin(ang) * 15

    rect(0, 8, 127, 119, 12)
  
    if not hatched then
        spr(2, posx - 3, posy - 3)
    else
        spr(1, posx - 3, posy - 3)
        line(posx, posy, endx, endy, 7)
        rspr(0, mx, my, t()) 
    end
end

__gfx__
77700777777777700077e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000777eee770077eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000777777770eeeee7e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700077777770eeeee77000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000eee00077eeee7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000700777000777eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7000000700777000077eee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77700777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
