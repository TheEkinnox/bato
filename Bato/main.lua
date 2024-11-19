-- todo: (prioritaire)
-- systeme de biome
-- generation des arbres

-- convert inventory icons to sspr

--réparer le drag de la minimap (et du minijoueur)

-- todo: (secondaire)
-- systeme de craft
-- détecter des layers
-- si le joueur est sous un layer, le rendre "transparent"
-- split draw func

--bugs :

--maps impact on performance

function _init()
    cls()
    print("chargement...", 41, 62)
    sspr(64, 24, 6, 8, 31, 61)

    sspr(57, 50, 6, 6, 1, 1)

    --valeurs, taille et chance par
    --valeurs du tableau

    -- tile info
    -- Data structure: type (1b), sprite (8b), color (4b), height (3b)
    typeBits = 1
    typeOffset = 0
    spriteBits = 8
    spriteOffset = typeOffset + typeBits
    minimapIdxBits = 4
    minimapIdxOffset = spriteOffset + spriteBits
    heightBits = 3
    heightOffset = minimapIdxOffset + minimapIdxBits

    --bloc sprites numbers (+ offset)
    water=192
    grass=194
    snow=196
    sand=198
    nightOffset = 32
    --sprite call for map and minimap after procedural generation
    --map
    -- TODO: setup biomes
    biomes = {
        {
            name="plain",
            gspr={grass},
            minimapIdx={2}
        },        
        {
            name="desert",
            gspr={sand},
            minimapIdx={4}
        },
        {
            name="snow",
            gspr={snow},
            minimapIdx={3}
        }
    }
    --minimap
    miniSpr={40, 48, 56, 64}

    playercol=8
    boatcol=11
    --map size
    width=64
    height=64
    --minimapsize
    mapWidth=min(width/2, 22)
    mapHeight=min(height/2, 22)
    --terrain height (z axis)
    groundheight={min=2,max=4}
    waterheight={min=0,max=2}
    density=.47
    --amount of procedural iterations at map creation
    iterations=3

    board=getMap()

    -- inventory
    items=loadItems()
    invColCount=7
    invLinesCount=4

    --hotbar
    selectedIndexUI = invColCount * invLinesCount - invColCount + 1

    inventory=initInventory()
    numStart=176 -- The sprite number of 0
    selectedIndex = 0

    --grid offset to create isometry
    xstep=8 -- xstep=tile width/2
    ystep=4 -- ystep=tile height/4
    zstep=4
    --camera and player position
    px=0
    py=height*ystep
    pz=0
    gpx=width/2
    gpy=height/2

    movespeed=1
    --caracter + hands subsprites
    maincara=0
    waterOffset=16
    hand=49
    --boat position
    xb=px-20
    yb=py
    zb=0
    gbx,gby=px_to_grid(xb,yb) -- grid position of the boat
    --animation delay
    anim=0
    wait=0.25
    --hands position
    x2=px+7
    x3=px
    --help message to get on/off the boat
    batutoff=""
    --boat / minimap / menu states
    onboat=false
    minimap=false
    menu=false
    --timers
    btndelay=5
    menutimer=0
    boattimer=0
    --day state and timer
    day=true
    daytimer=0
    daydelay=100

    wanimdelay=40 -- frames between each water height update
    wanimtimer=0
    --hp + hunger + thirst amount
    hp=20
    hunger=20
    thirst=20
    barui=20

    hungerloss=0
    healthloss=0
    thirstloss=0

    --subsprite y when in/out of water
    ssprswim=9

    --cursor delta to move the minimap

    initcursorx=0
    initcursory=0

    compcursorx=0
    compcursory=0

    finalcursorx=0
    finalcursory=0

    handsy=7
    face_frame=7
    animy=0
    anim_waity=.3

    feety=13
    animfeet=0
    anim_waitfeet=0.1

    idleornot=40

    hitkey=0
    hitsprflip=false

    hit_pos_x=0

    hit_pos_x2=0
    hit_pos_y2=0

    scrollhotbar = 0
    scrollup=0
    scrolldown=0

    -- Coroutine
    coroutines = {}


end

function _update()

    mousex=stat(32)
    mousey=stat(33)

    if time() - animy > anim_waity then
        face_frame+=8
        animy=time()
        if face_frame > 31 then
            face_frame=7
        end
    end

    if time() - animfeet > anim_waitfeet then
        feety+=1
        animfeet=time()
        if feety > 13 then
            feety=9
        end
    end

    if daydelay > daytimer then
        daytimer+=1
    end

    if daytimer==daydelay then
        daytimer=1
    end

    if daytimer < daydelay/2 then
        day=true
    else
        day=false
    end

    healthlossot()
    hungerlossot()
    thirstlossot()
    gbx,gby= px_to_grid(xb,yb) -- grid position of the boat
    gpx,gpy=px_to_grid(px,py) -- grid position of the player

    if menutimer >= btndelay then

        if stat(28,8) then
            menu= not menu
            minimap=false
            menutimer=0
        end

        if stat(28,43) then --tab
            minimap= not minimap
            menu=false
            menutimer=0
        end
    else
        menutimer+=1
    end


    if wanimtimer >= wanimdelay then
        wanimtimer=0
        animatewater()
    else
        wanimtimer+=1
    end

    batuton=""

    animtime()

    if hand > 54 then
        hand=49
    end
    dscreen()
    if not minimap then
    playermove()
    end
    boatmove()
    invNavigation()

    zb=board[gbx] and board[gbx][gby] and getHeight(board[gbx][gby]) or -4
    pz=onboat and zb or board[gpx] and board[gpx][gpy] and getHeight(board[gpx][gpy]) or -4

end

function drawSprite(sprite, x, y, width, height, clear_color)
    if clear_color then
        palt(clear_color, true)
        palt(0, false)
    end

    --if not day then
    --    nightpal()
    --end
    spr(sprite, x, y, width, height)

    if clear_color then
        palt()
    end
end

function drawNum(number, x, y, spacing)
    spacing = spacing or 1

    while number > 0 do
        local digit = number % 10
        number = flr(number / 10)
        spr(numStart + digit, x, y, .5, .5)
        x += spacing + 4
    end
end

function _draw()

    if hp > 0 then

        defaultpal()

        cls(0)
        dxb,dyb=grid_to_px(gbx,gby)
        camera(px-60,py-60)

        if not minimap then

            drawMap()

            drawPlayer()
            hit()

            hpc()
            hungerc()
            thirstc()
            drawUIminimap()

            cursordetector()

    
            if not menu then
                print(batuton,px-34,py+24,0)

                print(px,px-58,py+60,0)
                print(py,px-58,py+50,0)

                print(batutoff,px-58,py+52,0)
            end
        else
            hpc()
            hungerc()
            thirstc()
            local tmpx, tmpy = px_to_grid(finalcursorx, finalcursory)
            drawminimap(gpx - tmpx, gpy - tmpy)
        end

        drawInventory()


        -- print(compcursorx,px,py-52,0)
        -- print(initcursorx,px,py-46,0)

        -- print(finalcursorx,px,py-40,0)

        -- print(compcursory,px,py-34,0)
        -- print(initcursory,px,py-28,0)

        -- print(finalcursory,px,py-22,0)

        --print("gpx:"..gpx.." | gpy:"..gpy.."\ngbx:"..gbx.." | gby:"..gby,px-58,py+30)
    end

    sspr(((stat(34))*3)+4, 19, 3, 5, px-60+mousex, py-60+mousey) -- cursor sprites

    --wheel scroll animation
        if stat(36) > 0 then
            scrollup=1
        end
        if scrollup > 0 then
            scrollup += 1
                pset(px-59+mousex, py-58+mousey,12)
        end
        if scrollup > 8 then
            scrollup=0
        end
        
        if stat (36) < 0 then
            scrolldown=1
        end
        if scrolldown > 0 then 
            scrolldown += 1
                pset(px-59+mousex, py-57+mousey,12)

        end
        if scrolldown > 8 then
            scrolldown=0
        end

    --kill switch
        if stat(28, 11) then
            hp = 0
        end

    if minimap then
        print(finalcursorx,px-58,py+40,0)
        print(finalcursory,px-58,py+50,0)
        if btn(🅾️) then
            finalcursorx=0
            finalcursory=0
        end
        if stat(34) == 0 then
            initcursorx = mousex
            initcursory = mousey

        elseif stat(34) == 2 then

            compcursorx = mousex
            compcursory = mousey
            local pxMapX, pxMapY = grid_to_px(width, height)

            if initcursorx != compcursorx then
                finalcursorx = finalcursorx - initcursorx + compcursorx
                -- clamp to map
                finalcursorx = mid(finalcursorx, -pxMapX / 2, pxMapX / 2)

                initcursorx = compcursorx
            end

            if initcursory != compcursory then
                finalcursory = finalcursory - initcursory + compcursory
                -- clamp to map
                finalcursory = mid(finalcursory, -pxMapY / 2, pxMapY / 2)
                initcursory = compcursory
            end

        end
    end
end

--fonction deplacement + camera

--decplacement du jouer avec les
--valeurs x,y et changement de
--la direction du sprite


function playermove()

    if hp < 1 then
        return
    end

    local vx,vy=0,0

    if not onboat then
        if stat(28,4) or stat(28,26) or stat(28,7) or stat(28,22) then
            idleornot=feety
        else
            idleornot=13
        end
    end

    if stat(28,4) then --q / ⬅️

        vx=-movespeed
        maincara=48
        x2=4
        x3=4
        ssprswim=9
    end

    if stat(28,26) then --w / ⬆️
        vy=-movespeed
        maincara=32
        x2=0
        x3=7
        ssprswim=9
    end

    if stat(28,7) then -- d / ⬅️
        vx=movespeed
        maincara=16
        x2=3
        x3=3
        ssprswim=9
    end

    if stat(28,22) then -- s / ⬇️
        vy=movespeed
        maincara=0
        x2=7
        x3=0
        ssprswim=9
    end

    if stat(28,4) and stat(28,22) then -- q / s
        maincara=56
        x2=6
        x3=6
        ssprswim=9
    end

    if stat(28,4) and stat(28,26) then -- q / w
        maincara=40
        x2=1
        x3=1
        ssprswim=9
    end

    if stat(28,7) and stat(28,26) then -- d / s
        maincara=24
        x2=6
        x3=6
        ssprswim=9
    end

    if stat(28,7) and stat(28,22) then --d / w
        maincara=8
        x2=1
        x3=1
        ssprswim=9
    end

    local tx,ty=(onboat and xb or px),(onboat and yb or py)
    local gtx,gty=px_to_grid(tx,ty)
    local multiplier=1

    if is_water(gtx,gty) and (vx != 0 or vy != 0) then
            ssprswim=8
        multiplier=.5
    end

    for i=(vx>0 and 1 or -1),vx,(vx>0 and 1 or -1) do
        px+=is_valid_pos(tx+i,ty,onboat) and i*multiplier or 0
    end

    for j=(vy>0 and 1 or -1),vy,(vy>0 and 1 or -1) do
        py+=is_valid_pos(tx,ty+j,onboat) and j*multiplier or 0
    end
end

-- Death screen
function dscreen()
    daypal()
    if hp < 1 then
        cls(1)
        spr(48,px,py)

        camera(px-60,py-60)
        print("you died",px-12,py-32,8)
        print("continue?",px-14,py-22,7)
        print("yes",px-10,py-10,dedyes)
        print("no",px+10,py-10,dedno)

        if px-60+mousex >= px-10 and px-60+mousex <= px and py-60+mousey >= py-10 and py-60+mousey <= py-6 then
            dedyes = 7

            if stat(34) == 1 then
                hp=20
                thirst=20
                hunger=20
                px=0
                py=height*ystep
                minimap=false
                menu=false
            end
        else
            dedyes = 0
        end
        if px-60+mousex >= px+10 and px-60+mousex <= px+20 and py-60+mousey >= py-10 and py-60+mousey <= py-6 then
            dedno = 7

            if stat(34) == 1 then
                dedno = 8
            end
        else
            dedno = 0

        end
    end
end

function hit()

    if stat(34) == 1 and hitkey < 1 then
        hitkey+=1
    end
    if hitkey > 0 then
        hitkey+=1
    end
    if hitkey > 23 then
        hitkey=0
    end
    

    if hitkey > 0 and hitkey <= 4 then
        --sfx(2)
            pal({[8]=6, [10]=7, [14]=6})
        
            palt(3,0)
            palt(9,0)
            palt(11,0)
            palt(15,0)
        
            sspr(hit_spr_pos_x, 32, hit_spr_size_x, hit_spr_size_y, hit_pos_x, hit_pos_y,hit_spr_size_x ,hit_spr_size_y , hitframeflips, hitframeflips)
        
            defaultpal()
    end
    if hitkey > 4 and hitkey <= 7 then
        
            pal({[8]=6, [9]=6, [10]=7, [14]=7, [15]=7})
        
            palt(3,0)
            palt(11,0)
            palt(6,0)
            palt(7,0)
        
            sspr(hit_spr_pos_x, 32, hit_spr_size_x, hit_spr_size_y, hit_pos_x, hit_pos_y,hit_spr_size_x ,hit_spr_size_y , hitframeflips, hitframeflips)
        
            defaultpal()
    end
    if hitkey > 7 and hitkey <= 9 then
        
            pal({ [3]=6, [11]=7}) 
            palt(9,0)
            palt(8,0)
            palt(10,0)
            palt(6,0)
            palt(7,0)
            palt(14,0)
            palt(15,0)
        
            sspr(hit_spr_pos_x, 32, hit_spr_size_x, hit_spr_size_y, hit_pos_x2, hit_pos_y2,hit_spr_size_x ,hit_spr_size_y , hitframeflips, hitframeflips)
            defaultpal()
    end
end

function cursordetector()
    --line(px-28, py-60, px+35, py+67, 8)   --to visualize "hitbox" guidelines
    --line(px-28, py+67, px+35, py-60, 8)
    --line(px-60 , py-28, px+67, py+35, 8)
    --line(px+67, py-28, px-60, py+35, 8) 
    if mousex - mousey / 2 > 32 and mousex + mousey / 2 < 95 then -- ↑
        hitframedirection=40
        hitframeflips=true
        hit_pos_x = (onboat and dxb or px) - 12
        hit_pos_y = (onboat and dyb or py) - pz * 2 - 6
        hit_pos_x2 = (onboat and dxb or px) - 3
        hit_pos_y2 = (onboat and dyb or py) - pz * 2 - 13

        hit_spr_pos_x=45
        hit_spr_size_x=31
        hit_spr_size_y=18
    elseif mousex + mousey / 2 >= 95 and mousex / 2 + mousey < 96 and mousex > 63 then    -- ↗
        hitframedirection=42
        hitframeflips=true
        hit_pos_x = (onboat and dxb or px) - 9
        hit_pos_y = (onboat and dyb or py) - pz * 2 - 6
        hit_pos_x2 = (onboat and dxb or px) + 3
        hit_pos_y2 = (onboat and dyb or py) - pz * 2 - 8

        hit_spr_pos_x=16
        hit_spr_size_x=29
        hit_spr_size_y=21
    elseif mousex / 2 + mousey >= 96 and mousex / 2 - mousey >= -31 then                    -- →
        hitframedirection=44
        hitframeflips=false
        hit_pos_x = (onboat and dxb or px) + 1
        hit_pos_y = (onboat and dyb or py) - pz * 2 - 6
        hit_pos_x2 = (onboat and dxb or px) + 1
        hit_pos_y2 = (onboat and dyb or py) - pz * 2 - 10

        hit_spr_pos_x=77
        hit_spr_size_x=19
        hit_spr_size_y=28
    elseif mousex - mousey / 2 > 31 and mousex / 2 - mousey < -31 and mousey > 63 then    -- ↘
        hitframedirection=46
        hitframeflips=false
        hit_pos_x = (onboat and dxb or px) - 4
        hit_pos_y = (onboat and dyb or py) - pz * 2 - 4
        hit_pos_x2 = (onboat and dxb or px) - 5
        hit_pos_y2 = (onboat and dyb or py) - pz * 2 + 6

        hit_spr_pos_x=96
        hit_spr_size_x=24
        hit_spr_size_y=22
    elseif mousex - mousey / 2 <= 31 and mousex + mousey / 2 >= 96 then                     -- ↓
        hitframedirection=40
        hitframeflips=false
        hit_pos_x = (onboat and dxb or px) - 11
        hit_pos_y = (onboat and dyb or py) - pz * 2 
        hit_pos_x2 = (onboat and dxb or px) - 20
        hit_pos_y2 = (onboat and dyb or py) - pz * 2 + 7

        hit_spr_pos_x=45
        hit_spr_size_x=31
        hit_spr_size_y=18
    elseif mousex + mousey / 2 < 96 and mousex / 2 + mousey >= 95 and mousex < 64 then    -- ↙
        hitframedirection=42
        hitframeflips=false
        hit_pos_x = (onboat and dxb or px) - 12
        hit_pos_y = (onboat and dyb or py) - pz * 2 - 3
        hit_pos_x2 = (onboat and dxb or px) -24
        hit_pos_y2 = (onboat and dyb or py) - pz * 2 - 1

        hit_spr_pos_x=16
        hit_spr_size_x=29
        hit_spr_size_y=21
    elseif mousex / 2 + mousey < 95 and mousex / 2 - mousey < -32 then                      -- ←
        hitframedirection=44
        hitframeflips=true
        hit_pos_x = (onboat and dxb or px) - 12
        hit_pos_y = (onboat and dyb or py) - pz * 2 - 10
        hit_pos_x2 = (onboat and dxb or px) - 12
        hit_pos_y2 = (onboat and dyb or py) - pz * 2 - 6

        hit_spr_pos_x=77
        hit_spr_size_x=19
        hit_spr_size_y=28
    elseif mousex - mousey / 2 <= 32 and mousex / 2 - mousey >= -32 and mousey < 64  then -- ↖
        hitframedirection=46
        hitframeflips=true
        hit_pos_x = (onboat and dxb or px) - 12
        hit_pos_y = (onboat and dyb or py) - pz * 2 - 6
        hit_pos_x2 = (onboat and dxb or px) - 11
        hit_pos_y2 = (onboat and dyb or py) - pz * 2 - 16
        
        hit_spr_pos_x=96
        hit_spr_size_x=24
        hit_spr_size_y=22
    end
end

--deplacement du bateau quand
--le joueur se trouve dessus
--et appuie sur 🅾️
function boatmove()
    if is_boat(gpx,gpy,2) then
        if onboat then
            xb=px-3
            yb=py+3

            if not menu and not minimap then
            batuton=""
            batutoff="🅾️ : descendre"
            end
        else
            if not menu and not minimap then
            batuton="🅾️ : monter sur\n     le bateau"
            batutoff=""
            end
        end

        if boattimer>=btndelay then
            if not menu and not minimap then
                if btnp(🅾️) then
                    onboat = not onboat
                end
            end
        else
            boattimer+=1
        end
    end
end

--tick de temps pour une
--animation plus lente des sprite
function animtime()
    if time() - anim > wait then
    anim=time()
    hand+=1
    end
end

--tableau carte

function getType(tile)
    return readBits(tile, typeBits, typeOffset)
end

function getSprite(tile)
    return readBits(tile, spriteBits, spriteOffset)
end

function getMinimapIdx(tile)
    return readBits(tile, minimapIdxBits, minimapIdxOffset)
end

function getHeight(tile)
    return readBits(tile, heightBits, heightOffset)
end

function setHeight(tile, height)
    return writeBits(tile, heightBits, heightOffset, height)
end

function getTile(tiletype, biome)
    local tile = writeBits(0, typeBits, typeOffset, tiletype)
    local sprite=nil
    local minimapIdx=nil
    local height=nil

    -- TODO: select minimap idx based on the biome
    if tiletype==0 then
        -- ground tile

        local index=random(1, #biome.gspr + 1)
        sprite = biome.gspr[index]
        minimapIdx = biome.minimapIdx[index]
        height = random(groundheight.min, groundheight.max)
    else
        -- water tile
        sprite = biome.wspr and rnd(biome.wspr) or water
        minimapIdx = 1
        height = random(waterheight.min, waterheight.max)
    end

    tile = writeBits(tile, spriteBits, spriteOffset, sprite)
    tile = writeBits(tile, minimapIdxBits, minimapIdxOffset, minimapIdx)
    tile = writeBits(tile, heightBits, heightOffset, height)

    return tile
end

--generation d'un tableau pour
--la carte procedural
function getMap()
    local grid={{},{}}

    -- initial generation

    for x=1,width do
        grid[1][x]={}
        grid[2][x]={}
        for y=1,height do
            grid[1][x][y]=0
            if rnd(1)>density then
                -- water
                grid[2][x][y]=1
            else
                -- ground
                grid[2][x][y]=0
            end
        end
    end


    local main=1
    local nxt=2

    function countneighbors(cx,cy)
        local n=0

        for x=cx-1,cx+1 do
            if x<=0 or x>width then
                n+=3
            else
                for y=cy-1,cy+1 do
                    if y<=0 or y>height then
                        n+=1
                    else
                        n+=grid[main][x][y]
                    end
                end
            end
        end

        return n-grid[main][cx][cy]
    end

    -- neighbour based discrimination
    for i=1, iterations do
        main = nxt
        --nxt = main % 2

        for x = 1, width do
            for y = 1, height do
                local n = countneighbors(x,y)

                if n != 4 then
                    grid[nxt][x][y]=n>4 and 1 or 0
                end
            end
        end
    end

    grid=grid[main]

    -- TODO: select biome
    local biome = rnd(biomes)
    -- replace tile types with sprite numbers
    for x=1,width do
        for y=1,height do
            grid[x][y]=getTile(grid[x][y], biome)
        end
    end

    return grid
end

function drawMap()
    for x=mid(1,gpx-13,width),min(width,gpx+13) do
        for y=mid(1,gpy-13,height),min(height,gpy+13) do
            gx,gy=grid_to_px(x,y)
            local tile = board[x][y]

            local sprite = getSprite(tile)

            --local sprite = day and getSprite(tile) or getSprite(tile) + nightOffset

            if x==width or y==height then
                for z=0, getHeight(tile) do
                    drawSprite(sprite, gx, gy - z * 2, 2, 2, 15)
                end
            else
                drawSprite(sprite, gx, gy - getHeight(tile) * 2, 2, 2, 15)
            end
            --defaultpal()
        end
    end
end


function drawPlayer()
    sspr(48, 19, 16, 10, dxb, dyb - zb * 2) -- boat

    sspr(maincara, 0, 8, ssprswim, (onboat and dxb or px), (onboat and dyb or py) - pz * 2, 8, ssprswim)

    if ssprswim==9 then
    sspr(maincara+1, idleornot, 6, 1, (onboat and dxb or px+1), (onboat and dyb or py) - pz * 2 + 9, 6, 1)
    end
    --defaultpal()

    chara_anim()
    if ssprswim==9 then
    pset((onboat and dxb or px) + x2, (onboat and dyb or py) - pz * 2 + handsy, 14)
    pset((onboat and dxb or px) + x3, (onboat and dyb or py) - pz * 2 + handsy, 14)
    end

    if ssprswim==8 then
        sspr(104, 8, 6, 2, (onboat and dxb or px)+1, (onboat and dyb or py) - pz * 2 + 6)
    end


end


function animatewater()
    for x=mid(1,gpx-12,width),min(width,gpx+12) do
        for y=mid(1,gpy-12,height),min(height,gpy+12) do
            if getType(board[x][y])==1 then
                board[x][y] = setHeight(board[x][y], random(waterheight.min, waterheight.max))
            end
        end
    end
end

--minimap

function drawminimap(centerX, centerY)
    --centrer la génération sur la caméra
    centerX = mid(centerX or gpx, mapWidth / 2, width - mapWidth / 2)
    centerY = mid(centerY or gpy, mapWidth / 2, height - mapHeight / 2)

    local mapX = mid(centerX - mapWidth / 2, 1, width - mapWidth)
    local mapY = mid(centerY - mapHeight / 2, 1, height - mapHeight)

    local maxX = min(width, mapX + mapWidth)
    local maxY = min(height, mapY + mapHeight)

    local xOffset, yOffset = grid_to_px(gpx - centerX, gpy - centerY)

    for x=mapX, maxX do
        for y=mapY, maxY do
            local isPlayerTile = (not onboat and gpx==x and gpy==y or onboat and gbx==x and gby==y)
            local isBoatTile = not onboat and gbx==x and gby==y

            local wx, wy = grid_to_px(x, y)
            wx += xOffset
            wy += yOffset
            
            sspr(miniSpr[getMinimapIdx(board[x][y])], 64, 8, 8, (wx + px) / 2, (wy + py) / 2)
 

            sspr(0, 19, 4, 5, px+3, py + 5) -- sprite personnage quand minimap

            --sspr(24, 48, 8, 7, dxb, dyb)

            if ssprswim==8 then
                sspr(104, 8, 6, 2, px+2, py + 8)
            end
        end
    end
end


function drawUIminimap()
    --centrer la génération sur la caméra
    local centerX = mid(gpx, mapWidth / 2, width - mapWidth / 2)
    local centerY = mid(gpy, mapWidth / 2, height - mapHeight / 2)

    local mapX = mid(centerX - mapWidth / 2, 1, width - mapWidth)
    local mapY = mid(centerY - mapHeight / 2, 1, height - mapHeight)

    local maxX = min(width, mapX + mapWidth)
    local maxY = min(height, mapY + mapHeight)

    for x=mapX, maxX do
        for y=mapY, maxY do
            local isPlayerTile = (not onboat and gpx==x and gpy==y or onboat and gbx==x and gby==y)
            local isBoatTile = not onboat and gbx==x and gby==y

            local wx, wy = grid_to_px(x, y)

            sspr(miniSpr[getMinimapIdx(board[x][y])]+2, 66, 2, 1, (px * 7 + wx) / 8 + 46, (py * 3 + wy) / 4 - 40 )

            pset(px+45, py-39, 14)

        end
    end
    line(px+45, py-60,px+24, py-39, 6)
    line(px+45, py-61,px+23, py-39, 6)
    line(px+45, py-62,px+22, py-39, 0)


    line(px+24, py-39, px+45, py-18, 6)
    line(px+23, py-39, px+45, py-17, 6)
    line(px+22, py-39, px+45, py-16, 0)


    line(px+46, py-17, px+67, py-38, 6)
    line(px+46, py-16, px+68, py-38, 6)
    line(px+46, py-15, px+69, py-38, 0)

    for x=0,11 do
        for y=0,11 do
            line(x+px+67, py-38-y, x+px+45, py-60-y, 6)
        end
    end
end

function createItem(subspritex, subspritey, subsizex, subsizey, offsetx, offsety, use)
    return {
        subspritex = subspritex,
        subspritey = subspritey,
        subsizex = subsizex,
        subsizey = subsizey,
        offsetx = offsetx,
        offsety = offsety,

        use = use or function() end
    }
end


function loadItems()
    return {

        createItem(93, 24, 4, 8, 2, 0, function() hp+=5 return true end), --health fiol
        createItem(80, 19, 8, 5, 0, 1, function() hunger+=3 return true end), -- banana

    }
end

function initInventory()
    local inventorygrid={}

    for i=1, invColCount * invLinesCount do
        inventorygrid[i] = rnd(items) -- todo: init with null
    end

    return inventorygrid
end

function drawInventory()
    if minimap then
        return
    end

    if menu then

        --Inventory ui
        --inside white
        line(px-36, py+7, px+43, py+7, 6)
        rectfill(px-38, py+8, px+45, py+57, 6)

        --bordure noir
        line(px-36, py+6, px+43, py+6, 0)
        
        for x=0,1 do
            pset(x*81 + px-37, py+7, 0)
            pset(x*83+px-38, py+8, 0)
            line(x*85 + px-39, py+9, x*85+px-39, py+53)
        end

        --inventory
        for x=1, invColCount do
            for y=1, invLinesCount - 1 do
                local index = getIndex(x, y, invColCount)
                local xpos = (x*12) + px-48
                local ypos = (y*14) + py-5
                local item = inventory[index]

                rectfill(xpos, ypos, xpos + 7, ypos + 7, 0)

                if px-60+mousex >= xpos and px-60+mousex <= xpos+7 and py-60+mousey >= ypos and py-60+mousey <= ypos+7 then
                    sspr(112, 0, 10, 10, xpos - 1, ypos -1)
                    selectedIndex=index

                end

                if stat(34) == 1 and px-60+mousex >= xpos and px-60+mousex <= xpos+7 and py-60+mousey >= ypos and py-60+mousey <= ypos+7 then
                    if (selectedIndex <= #inventory) then
                        local item = inventory[selectedIndex]

                        if item and item.use() then
                            inventory[selectedIndex] = nil
                        end
                    end
                end

                if stat(34) == 2 and px-60+mousex >= xpos and px-60+mousex <= xpos+7 and py-60+mousey >= ypos and py-60+mousey <= ypos+7 then
                    itemoptions= not itemoptions
                end

                if itemoptions then
                    if selectedIndex==index then
                    rectfill(xpos +8, ypos, xpos + 16, ypos+16)
                    elseif itemoptions==true and stat(34)>0 then
                        itemoptions=false
                    end
                end

                if item then
                    sspr(item.subspritex, item.subspritey, item.subsizex, item.subsizey,xpos + item.offsetx, ypos + item.offsety)
                end
            end
        end
    end


    --hotbar ui
    --inside blanc
    line(px-36, py+52, px+44, py+52, 7)
    rectfill(px-38, py+53, px+45, py+70, 7)

    --bordure noir
    line(px-36, py+51, px+43, py+51, 0)
    for x=0,1 do
    pset(x*81 + px-37, py+52, 0)
    pset(x*83+px-38, py+53, 0)
    end
    for x=0,1 do
        line(x*85 + px-39, py+54, x*85 + px-39, py+68)
    end

    --hotbar
    for x=1, invColCount do
        for y=invLinesCount, invLinesCount do

            local index = getIndex(x, y, invColCount)
            local xpos = (x*12) + px-48
            local ypos = (y*21) + py-30
            local item = inventory[index]

            print(selectedIndex, px+50, py, 6)
            print(selectedIndexUI, px+50, py+10, 6)
            print(index, px+50, py+20, 6)
        
            rectfill(xpos, ypos, xpos + 7, ypos + 7, 0)

        --selectedIndex selection via cursor in hotbar 

            if stat(34) == 0 and px-60+mousex >= xpos and px-60+mousex <= xpos+7 and py-60+mousey >= ypos and py-60+mousey <= ypos+7 then
                sspr(112, 0, 10, 10, xpos - 1, ypos -1)
                selectedIndex=index

            end
            
            if stat(34) == 1 and px-60+mousex >= xpos and px-60+mousex <= xpos+7 and py-60+mousey >= ypos and py-60+mousey <= ypos+7 then
                selectedIndexUI=index
            end

            invNavigation()

            if index == selectedIndexUI then
                rect(xpos - 1, ypos - 1, xpos + 8, ypos + 8, 5)
                rectfill(xpos - 1, ypos + 9, xpos + 8, ypos + 13, 6)
            end

            if item then
                sspr(item.subspritex, item.subspritey, item.subsizex, item.subsizey,xpos + item.offsetx, ypos + item.offsety)
            end

        end
    end
end

function invNavigation()
    if menu or minimap then
        return
    end

    if stat(36) > 0 and scrollhotbar == 0 then
        selectedIndexUI -= 1
    end
    
    if stat(36) < 0 and scrollhotbar == 0 then
        selectedIndexUI += 1

    end

    if stat(36) > 0 or stat (36) < 0 then
        scrollhotbar+=1
    end

    if scrollhotbar > 0 then 
        scrollhotbar += 1
    end

    if scrollhotbar > 18 then
        scrollhotbar=0
    end




    if selectedIndexUI > invColCount * invLinesCount then
        selectedIndexUI = invColCount * invLinesCount - invColCount + 1
    end

    if selectedIndexUI < invColCount * invLinesCount - invColCount + 1 then
        selectedIndexUI = invColCount * invLinesCount
    end

    if stat(34)==2 then
        if (selectedIndexUI <= #inventory) then
            local item = inventory[selectedIndexUI]

            if item and item.use() then
                inventory[selectedIndexUI] = nil
            end
        end
    end
end



--hitbox et barres de ressources

function hitline(x,y)
    line(x+7,y,x,y+3,8)
    line(x+8,y,x+15,y+3)
    line(x+8,y+7,x+15,y+4)
    line(x+7,y+7,x,y+4)
end

function hpc()

    for x=1,25 do
       for y=1,3 do
            pset(x+px-60,y+py-60,6)
        end
    end

    sspr(125, 0, 3, 3,px-37,py-59)

    for a=1,barui do
        pset(a + px - 59, py - 58, 5)
    end

    for a=1,hp do
        pset(a + px -59, py - 58, 8)
    end
end

function hungerc()

    for x=1,25 do
       for y=1,3 do
            pset(x+px-60,y+py-56,6)
        end
    end

    sspr(122, 0, 3, 3,px-37,py-55)

    for a=1,barui do
        pset(a+px-59,py-54,5)
    end

    for a=1,hunger do
        pset(a+px-59,py-54,4)
    end
end

function thirstc()

    for x=1,25 do
        for y=1,3 do
             pset(x+px-60,y+py-52,6)
         end
     end

     sspr(122, 3, 3, 3,px-37,py-51)

    for a=1,barui do
        pset(a+px-59,py-50,5)
    end

    for a=1,thirst do
        pset(a+px-59,py-50,12)
    end
end

function healthlossot()
    if hp >=0 then
        if time()-healthloss > 10 and hunger==0 or thirst==0 then
        hp-=1
        healthloss=time()
        end
    end
end

function hungerlossot()
    if hunger <= 0 then
        if time()-hungerloss > ( is_water(gpx,gpy) and not onboat and 2 or 20 ) and hunger>0 then
            hunger-=1
            hungerloss=time()
        end
    end
end

function thirstlossot()
    if thirst <= 0 then
        if time()-thirstloss > 15 and hunger>0 then
            thirst-=1
            thirstloss=time()
        end
    end
end

-- collision
function grid_to_px(gx,gy)
    return gx*xstep-gy*xstep,gx*ystep+gy*ystep
end

function px_to_grid(x,y)
    local gy=(x-xstep*y/ystep)/(-xstep*xstep/ystep)

    return flr((y-ystep*gy)/ystep)+1,flr(gy)+1
end

function is_valid_pos(x,y,isboat)
    local gx,gy=px_to_grid(x,y)

    if gx>0 and gx<=width and gy>0 and gy<=height then
        local tileType = getType(board[gx][gy])

        if isboat then
            return tileType==1
        else
            return tileType==0 or tileType==1
        end
    end

    return false
end

function is_water(gx,gy,ignoreboat)
    return (ignoreboat or not is_boat(gx,gy)) and board[gx] and board[gx][gy] and getType(board[gx][gy])==1 or false
end

function is_boat(gx,gy,range)
    return abs(gx-gbx)<(range or 1) and abs(gy-gby)<(range or 1)
end

function chara_anim()

    if maincara == 0 then
        sspr(face_frame, 11, 2, 3, (onboat and dxb or px+2), (onboat and dyb or py) - pz * 2 + 3)
        sspr(face_frame, 11, 2, 3, (onboat and dxb or px+4), (onboat and dyb or py) - pz * 2 + 3,
    2, 3,true)
    end

    if maincara == 8 then
        sspr(face_frame, 11, 2, 3, (onboat and dxb or px+3), (onboat and dyb or py) - pz * 2 + 3)
        sspr(face_frame, 11, 2, 3, (onboat and dxb or px+5), (onboat and dyb or py) - pz * 2 + 3,
    2, 3,true)
    end

    if maincara == 16 then
        sspr(face_frame, 11, 2, 3, (onboat and dxb or px+5), (onboat and dyb or py) - pz * 2 + 3)
    end

    if maincara == 48 then
        sspr(face_frame, 11, 2, 3, (onboat and dxb or px+1), (onboat and dyb or py) - pz * 2 + 3,
    2, 3,true)

    end

    if maincara == 56 then
        sspr(face_frame, 11, 2, 3, (onboat and dxb or px+1), (onboat and dyb or py) - pz * 2 + 3)
        sspr(face_frame, 11, 2, 3, (onboat and dxb or px+3), (onboat and dyb or py) - pz * 2 + 3,
    2, 3,true)
    end

    if face_frame == 7 then
        handsy=8
    end

    if face_frame == 15 then
        handsy=7
    end

    if face_frame == 23 then
        handsy=6
    end

    if face_frame == 31 then
        handsy=7
    end

end

function defaultpal()
    if day then
        pal()
        pal({   [0]=128,    1,      2,      3,
                    4,      5,      6,      7,
                    8,      9,      10,     139,
                    140,    13,     143,    15
            }, 1)
    else
        pal()
        pal({   [0]=0,      129,    130,    131,
                    132,    133,    13,      6,
                    2,      4,      9,      3,
                    1,      141,    142,    143
            }, 1)
    end
end

function daypal()
    pal()
    pal({   [0]=128,    1,      2,      3,
                4,      5,      6,      7,
                8,      9,      10,     139,
                140,    13,     143,    15
        }, 1)
end

function nightpal()
    pal()
    pal({   [0]=0,      129,    130,    131,
                132,    133,    5,      6,
                2,      4,      9,      3,
                1,      141,    142,    143
        }, 1)
end

