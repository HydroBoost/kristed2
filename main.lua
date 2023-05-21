local kapi = require("kristapi")
local dw = require("discordWebhook")
local frontend = require("modules.frontend")
local backed = require("modules.backend")
local alive = require("modules.alive")

local cfg = fs.open("config.conf","r")
local config = textutils.unserialise(cfg.readAll())
cfg.close()

local storages = {}
local perps = peripheral.getNames()
for k,v in ipairs(perps) do
    local _, t = peripheral.getType(v)
    if t == "inventory" then
        table.insert(storages, {
            id = v,
            wrap = peripheral.wrap(v)
        })
    end
end

local itemCountCache = {}
function getItemCount(id)
    if itemCountCache[id] then
        local out = itemCountCache[id].count
        if os.clock() > itemCountCache[id].time+10 then
            itemCountCache[id] = nil
        end
        return out
    else
        local co = 0
        for k,v in ipairs(storages) do
            for kk,vv in pairs(v.wrap.list()) do
                if vv.name == id then
                    co = co + vv.count
                end
            end
        end
        itemCountCache[id] = {
            count = co,
            time = os.clock()
        }
        return co
    end
end

if kristed ~= nil then
    kristed.ws.close()
end

_G.kristed = {
    kapi = kapi,
    dw = dw,
    config = config,
    storages = storages,
    version = "0.1.0",
    getItemCount = getItemCount,
    getItemById = function(id)
        for k,v in ipairs(config.items) do
            if v.id == id then
                return v
            end
        end
    end,
    checkout = {
        currently = false,
        price = 0,
        paid = 0,
        cart = {}
    }
}

print([[
 _  __     _     _           _ ___
| |/ /    (_)   | |         | |__ \
| ' / _ __ _ ___| |_ ___  __| |  ) |
|  < | '__| / __| __/ _ \/ _` | / /
| . \| |  | \__ \ ||  __/ (_| |/ /_
|_|\_\_|  |_|___/\__\___|\__,_|____|
]])

function rawNotify(message,bg,fg)
    local screen = peripheral.find("monitor")
    local w,h = screen.getSize()
    local nw = 52
    local nh = 10
    local x = math.floor(w/2 - nw/2)
    local y = math.floor(h/2 - nh/2)
    screen.setCursorPos(x,y)
    screen.setBackgroundColor(bg)
    screen.setTextColor(fg)
    -- Render the background background
    for iy=y,y+nh-1,1 do
        for ix=x,x+nw-1,1 do
            screen.setCursorPos(ix,iy)
            screen.write(" ")
        end
    end

    -- Render the message
    if type(message) == "table" then
        local nny = y+math.floor(nh/2)
        for k,v in ipairs(message) do
            local nnx = x+math.floor(nw/2-#v:sub(1,nw)/2)
            local nnyn = nny-(math.floor(#message/2)-k)-1
            screen.setCursorPos(nnx,nnyn)
            screen.write(v:sub(1,nw))
        end
    else
        local nnx = x+math.floor(nw/2-#message:sub(1,nw)/2)
        local nny = y+math.floor(nh/2)
        screen.setCursorPos(nnx,nny)
        screen.write(message:sub(1,nw))
    end
end

parallel.waitForAny(function()
    local ok,err = pcall(frontend)
    if not ok then
        rawNotify({
            "An error occurred",
            "Please report this to the owner",
            kristed.config.owner,
            "And/or to the github repo",
            "afonya/kristed2",
            "And please specify this error message:",
            err
        }, colors.red, colors.white)
        print(err)
    end
end, function()
    local ok,err = pcall(backend)
    if not ok then
        rawNotify({
            "An error occurred",
            "Please report this to the owner",
            kristed.config.owner,
            "And/or to the github repo",
            "afonya/kristed2",
            "And please specify this error message:",
            err
        }, colors.red, colors.white)
        print(err)
    end
end, function()
    local ok,err = pcall(alive)
    if not ok then
        rawNotify({
            "An error occurred",
            "Please report this to the owner",
            kristed.config.owner,
            "And/or to the github repo",
            "afonya/kristed2",
            "And please specify this error message:",
            err
        }, colors.red, colors.white)
        print(err)
    end
end)