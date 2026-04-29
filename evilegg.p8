pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- evil egg demake :3 thank you ivysly for the original game

local posx, posy = 64, 64
local speed = 1.2
local bspeed = 0.4

local mx, my = 64, 64

local velx, vely = 0, 0
local accelx, accely = 0, 0
local friction = 0.95

local hatched = false
local hatched_particles_spawned = false

local trails = {}
local trailmeter = 0

local dash_length = 2  -- pixels
local gap_length = 2   -- pixels
local num_dashes = 4   -- how many dashes to draw

local bullets = {}
local btrails = {}

local particles = {}

function _init()
    poke(0x5f2d, 1)
end

-- i wanna thank whoever made this function, i have no idea how it works but it does and i love it
function rspr(s,x,y,a)
    local sx=(s%16)*8
    local sy=flr(s/16)*8
    for i=0,7 do
        for j=0,7 do
            local c=sget(sx+i,sy+j)
            if c!=0 then 
                local dx,dy=i-3.5,j-3.5
                local rx=x+dx*cos(a)+dy*sin(a) 
                local ry=y-dx*sin(a)+dy*cos(a) 
                pset(rx,ry,c)
            end
        end
    end
end

-- thank you charlie omg omg omg
function newtrail(ix,iy,ixv,iyv)
    add(trails,{
        x=ix,
        y=iy,
        xv=ixv,
        yv=iyv,
        life=6,
        draw=function(self)
            self.x+=self.xv
            self.y+=self.yv
            self.life-=1
            if self.life<=0 then
                del(trails,self)
            end
            rectfill(self.x-1,self.y-1,self.x+1,self.y+1,7)
        end
    })
end

function newbtrail(ix,iy)
    add(btrails,{
        x=ix,
        y=iy,
        life=3,
        draw=function(self)
            if self.life==3 then
                color(2)
            else
                color(8)
            end
            rect(self.x,self.y,self.x+1,self.y+1)
            self.life-=1
            if self.life<=0 then
                del(btrails,self)
            end
        end
    })
end

function newbullet(ix,iy,ixv,iyv)
    add(bullets,{
        x=ix,
        y=iy,
        xv=ixv,
        yv=iyv,
        life=100,
        draw=function(self)
            self.x+=self.xv
            self.y+=self.yv
            self.life-=1
            if self.life<=0 then
                del(bullets,self)
            end
            newbtrail(self.x,self.y)
            rect(self.x,self.y,self.x+1,self.y+1,7)
        end
    })
end

-- so this is a bit of a mess but it works and i dont care
function _update()
    for p in all(particles) do
        if p.t>0 then
            p.x+=p.dx
            p.y+=p.dy
            p.t-=1
        end
        p.life-=1
        if p.life<=0 then del(particles,p) end
    end

    if hatched==true and not hatched_particles_spawned then 
        for j=1,8 do
            add(particles,{
                x=posx,y=posy,
                dx=rnd(4)-2,
                dy=rnd(4)-2,
                t=8,
                life=25+flr(rnd(20)),
                col=14
            })
            sfx(0)
        end
        hatched_particles_spawned = true 
    end

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

        if velx > 3 then velx = 3 end
        if velx < -3 then velx = -3 end
        if vely > 3 then vely = 3 end
        if vely < -3 then vely = -3 end

        if btn(4) then
            if btn(0) then velx -= bspeed end
            if btn(1) then velx += bspeed end
            if btn(2) then vely -= bspeed end
            if btn(3) then vely += bspeed end

            if posx<4 then posx=4 velx*=-0.7 sfx(1) end
            if posx>123 then posx=123 velx*=-0.7 sfx(1) end
            if posy<12 then posy=12 vely*=-0.7 sfx(1) end
            if posy>115 then posy=115 vely*=-0.7 sfx(1) end

            trailmeter += abs(velx) + abs(vely)
            if trailmeter >= 6 then
                newtrail(posx, posy, -velx*0.3+(rnd(2)-1), -vely*0.3+(rnd(2)-1))
                trailmeter -= 6
                sfx(2)
            end
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
            trailmeter = 0
        end

        mx = stat(32)
        my = stat(33)

        -- read mouse buttons (for single-click shooting)
        mbtnlast = mbtn
        mbtn = stat(34)

        -- single click: left mouse button just pressed this frame
        if (mbtn & 1) == 1 and (mbtnlast & 1) != 1 then
            local aim = atan2(mx - posx, my - posy)
            newbullet(posx, posy, cos(aim) * 4, sin(aim) * 4)
        end
    end
end

-- dont ask me how this works, i have no idea

function _draw()
    cls()
    local x_dist = mx - posx
    local y_dist = my - posy
    local ang = atan2(x_dist, y_dist)
    local endx = posx + cos(ang) * 15
    local endy = posy + sin(ang) * 15

    rect(0, 8, 127, 119, 12)

    for i in all(trails) do
        i.draw(i)
    end

    if not hatched then
        spr(2, posx-3, posy-3)
    else

    for p in all(particles) do
        local c=p.t>0 and 14 or p.col
        pset(p.x,p.y,c)
    end

        -- draw dashed pink line under the player sprite
        local segments = {
            {start_pct=0.0, end_pct=0.2},
            {start_pct=0.4, end_pct=0.6},
            {start_pct=0.8, end_pct=1.0}
        }

        for _, seg in ipairs(segments) do
            local x1 = posx + seg.start_pct * (endx - posx)
            local y1 = posy + seg.start_pct * (endy - posy)
            local x2 = posx + seg.end_pct   * (endx - posx)
            local y2 = posy + seg.end_pct   * (endy - posy)
            line(x1, y1, x2, y2, 14)
        end

        -- draw player sprite on top of the line
        spr(1, posx-3, posy-3)

        -- draw cursor
        rspr(0, mx, my, t())

        for i in all (btrails) do i.draw(i) end
        for i in all (bullets) do i.draw(i) end
    end
end
__gfx__
77700777777777700077e0000aaaaa008ccccc8800000000880000880077770007700770006666000777777000ee200000111100022222200009900009090900
7000000777eee770077eee00aaaaaaa0ccccccc8000cc000880cc088000770007700007706777760078888700ee2220001000010222222220008800098888890
7000000777777770eeeee7e0a88a88a0c00c00c0008cc8000c0cc0c00077770077777777677777767777777722222e201c0000c1222222220088880008898800
0007700077777770eeeee770a88a88a0c00c00c008888880077777700007700077700777677777767777777722222ee0c0c00c0c222222229888888998999890
0007700000eee00077eeee70aaaaaaaacccccccc888888880888888000cccc00777777776771177677777777ee2222e01c0000c1111122229888888908898800
7000000700777000777eeee0aaaaaaaacccccccc88000088007777000cccccc7077887706710017677777777eee2222010000001112211110088880098888890
7000000700777000077eee00aaaaaaaacccccccc880000880cccccc00cccccc78808808806100160000000000ee2220001000010001111000008800009090900
7770077700000000000000000a0a0a0a08080808088888800cc00cc00770000080088008000110000cccccc00000000000111100001111000009900000000000
999900000111100000aaaa00009999905550055500aa0aaa007700000008800000cccc000a900a90000b0b0088088088000880000000eee002c2000000077700
929800001000010000a00a0009999999222552220aaa0000077e0e0000aaaa000c1010c0a998a99800bbb0008aaaaaa80aa22aa0000ec7ce2202200000072700
999890001808010000aaaa0009aaaaa982855288000000aaeee007e00aaaaaa0c100000ca998a99800b0bb000a0000a0a88aa889000ecc7ec000cc0000072700
9888990010808100000aa00009aaaaa982855288aa0000aae00e00700aaaaaa0c008881c999899980000bb0089090098a88aa889000eccce220220c000077700
0099899911111100008888009999999922255222a000000a70eee07008888880c100000c99989998022bb2208999999809899890000eccce02c200c200777720
00099109011110000888888a99999999288288280a090a00707e0ee0aaaaaaaac000001c9998999822bbbb2202888820020220200000eee00000202007777720
00009000100001000888888a99999999288288280a888a00077eee00000000000c0101c099989998220bb02282022028aaaaaaaaeeeeeeee0002020277777722
00009900011110000aa00000909090900555555000080000000000000008800000cccc0008800880022222208808808899999999eeeeeeee0000002077777222
bbbbbbbbeeeeeeee88888888ccccccccaaaaaaaa0ee00e80999999990b0bb0b0bb00bb0000000000900000000077070000000000000000000000000000000000
b003b30be002e0ee80000008c0000ccca00a900ae888888890000009bb0bb0bb0bbb0b000cccccc0998899990077070000000000000000000000000000000000
b00000bbe000000e80088008c00ccccca000000a88088888909a9a09bbb00bbb00b0000001cccdd1880089090077770000000000000000000000000000000000
bb0bbbbbe2e02eee80888808c0011c0ca90aa0aa80888882909a9a09000bb000bbbb00b0c1ccc101809908900077770000000000000000000000000000000000
b30333b322e02ee2208888021ccc1c019a0990998888888290aaaa09bb0000bb00bbbb00c1ccc101880089090077770000000000000000000000000000000000
300000b32000000220222202101c000190000009088888209099990900b00b0000bbbb000cccc11198889999eeeeeeee00000000000000000000000000000000
3003b3032002e02220888802110c00019009a00900888200900000090bb00bb000b00b000111111080000000eeeeeeee00000000000000000000000000000000
3333333322222222222222221111111199999999000220009999999
