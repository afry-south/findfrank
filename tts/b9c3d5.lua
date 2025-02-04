--Alphabetize cards by their names if they have one (true or false)
alphabetize = false
--Color of the deck highlight and preview elements
uiColor = {0,1,0}
--How many rows or columns are possible
maxRowCol = 20
--How much space is put between cards
spacer = 0.2
--If it flips the cards or not
flip = false
--Optional height offset so cards are raised off the table more
heightOffset = 0

function onSave()
    saved_data = JSON.encode(layoutData)
    return saved_data
end

function onload(saved_data)
    --Loads the tracking for if the game has started yet
    if saved_data ~= "" then
        layoutData = JSON.decode(saved_data)
    else
        layoutData = {row=5, col=6}
    end
    makeText()
    createInputs()
    createClickButtons()
end



--Collision detection to find deck



--Detect if tool is placed on top of a deck, designating deck
function onCollisionEnter(collision_info)
    if collision_info.collision_object.tag == "Deck" and collision_info.collision_object ~= deck then
        if deck ~= nil then deck.highlightOff() end
        deck = collision_info.collision_object
        deck.highlightOn(uiColor)
    end
end
--Kill the highlight if the tool is destroyed
function onDestroy()
    if deck~=nil then deck.highlightOff() end
end



--Click actions and input changes

function mysplit (inputstr, sep)
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end


--Click of the submit button, starts layout
function click_submit()
    --Error protection
    if deck == nil then broadcastToAll("No deck designated.", {0.9,0.2,0.2}) return end
    --Remove buttons/previews
    previewActive = nil
    self.clearButtons()
    --Lock until finished
    self.setLock(true)
    --Lays out cards in a coroutine
    broadcastToAll(textInput, {0.9,0.2,0.2})
    local names = mysplit(textInput, ",")
    -- local names = {"klöver 8", "hjärter 12", "klöver 8", "klöver 8", "klöver 8", "klöver 8", "klöver 8", "klöver 8"}
    new_layout("card", names)
end

--Click of the preview button
function click_preview()
  broadcastToAll("asdf", {0.9,0.2,0.2})
    -- if previewActive ~= true then
    --     previewActive = true
    --     --Error protection
    --     if deck == nil then broadcastToAll("No deck designated.", {0.9,0.2,0.2}) return end
    --     --Start routine that will
    --     self.clearButtons()
    --     layout("button")
    -- else
    --     previewActive = nil
    --     self.clearButtons()
    --     createClickButtons()
    -- end
end

--Detect changes to number inputs
function input_change(_, _, userInput, stillEditing, layoutKey)
    if stillEditing == false then
        --Updates number or advises player to use a valid number
        if userInput=="" or tonumber(userInput)<1 or tonumber(userInput)>maxRowCol then
            broadcastToAll("Invalid number entry. Try a number from 1 - "..maxRowCol..".", {0.9,0.2,0.2})
        else
            layoutData[layoutKey] = math.abs(tonumber(userInput))
            if previewActive == true then
                self.clearButtons()
                layout("button")
            end
        end
    end
end



--Laying out of cards/buttons

function cardMatcher(name, card)
  name = name:lower()
  cardName = card.name:lower()
  return cardName == name
end

function getCardByName(deck, name, num, position)
  params = {}
  params.position = {30, 0, 0}
  params.sound = false
  tmp = deck.clone(params)
  found = false
  for key, value in pairs(tmp.getObjects()) do
    if (cardMatcher(name, value)) then
      found = true
      params = {}
      params.position = position
      params.smooth = false
      params.sound = false
      params['guid'] = value.guid
      c = tmp.takeObject(params)
      for i = 2, num, 1 do
        c.clone(params)
      end
      break
    end
  end
  if not found then
    print("WARNING CARD NOT FOUND: "..name)
  end
  tmp.destruct()
end


function new_layout(whichType, names)
  local size = deck.getBoundsNormalized().size
  size = {x=size.x+spacer, y=size.y, z=size.z+spacer}
  width = 3
  x = 0
  y = 0
  for index = 1, #names do
    -- broadcastToAll(names[index], {0.9,0.2,0.2})
    pos = vector(x*2.3, 2, 15-y*3.7)
    getCardByName(deck, names[index], 1, pos)
    x = x+1
    if x > width then
      x = 0
      y = y+1
    end
  end
end



--Coroutine that lays out cards
function layout(whichType)
    function layout_routine()
        --Get size of cards (need x/z) and add the spacer to it
        local size = deck.getBoundsNormalized().size
        size = {x=size.x+spacer, y=size.y, z=size.z+spacer}
        --Rotate the x/z to match the deck+tool's rotation
        local angle = math.rad(deck.getRotation().y - self.getRotation().y)
        local x = math.abs(size.x * math.cos(angle)) + math.abs(size.z * math.sin(angle))
        local z = math.abs(size.x * math.sin(angle)) + math.abs(size.z * math.cos(angle))
        size.x = x
        size.z = z
        --Determine first card's location
        local pos_starting = {
            x = -size.x * (layoutData.col-1)/2,
            y = 0 + heightOffset,
            z = -size.z
        }
        --Create variables used in placement
        local rowStep, colStep = 0, 0

        --Placement
        for i=1, layoutData.col*layoutData.row do
            --Find position for card
            local pos_local = {
                x = pos_starting.x + size.x * colStep,
                y = pos_starting.y,
                z = pos_starting.z - size.z * rowStep,
            }
            local pos = self.positionToWorld(pos_local)
            --Set up next loop
            colStep = colStep + 1
            if colStep > layoutData.col-1 then
                colStep = 0
                rowStep = rowStep + 1
            end
            --Apply action for position
            if whichType == "card" then
                --Places card
                if alphabetize == false then
                    getCardByName(deck, "ASDF", 1, pos)
                    -- deck.takeObject({position=pos, flip=flip})
                else
                    if #deck.getObjects() > 0 then
                        --Handles most cards
                        local nextIndex = findNextCardIndex()
                        deck.takeObject({position=pos, flip=flip, index=nextIndex})
                    else
                        --Handles the leftover card
                        local find_func = function(o) return o.tag=="Card" end
                        local objList = findInRadiusBy(deck.getPosition(), 0.5, find_func)
                        if #objList > 0 then
                            objList[1].setPosition(pos)
                            if flip then
                                local rot = objList[1].getRotation()
                                rot.z = rot.z+180
                                objList[1].setRotationSmooth(rot)
                            end
                        end
                    end
                end
            elseif whichType == "button" then
                --Places button
                self.createButton({
                    label="X", click_function="none", function_owner=self,
                    position=pos_local, height=0, width=0, font_size=1000,
                    font_color=uiColor,
                    rotation={0,deck.getRotation().y-self.getRotation().y,0},
                })
            end
            coroutine.yield(0)
            --Kills loop if deck is exhausted
            if deck==nil then break end
        end

        self.setLock(false)
        createClickButtons()
        return 1
    end
    startLuaCoroutine(self, "layout_routine")
end

--Gets the order of cards alphabetized
function findNextCardIndex()
    local orderList = {}
    for _, card in ipairs(deck.getObjects()) do
        if card.nickname ~= "" then
            local insertTable = {name=card.nickname, index=card.index}
            table.insert(orderList, insertTable)
        end
    end
    --Sort ordered list
    local sort_func = function(a,b) return a["name"] > b["name"] end
    table.sort(orderList, sort_func)
    --Add no-names onto start
    for _, card in ipairs(deck.getObjects()) do
        if card.nickname == "" then
            local insertTable = {name=card.nickname, index=card.index}
            table.insert(orderList, 1, insertTable)
        end
    end
    return orderList[1].index
end

--Finds objects in radius of a position, accepts optional filtering function
--Example func: function(o) return o.tag=="Deck" or o.tag=="Card" end
function findInRadiusBy(pos, radius, func)
    local objList = Physics.cast({
        origin=pos, direction={0,1,0}, type=2, size={radius,radius,radius},
        max_distance=0, --debug=true
    })

    local refinedList = {}
    for _, obj in ipairs(objList) do
        if func == nil then
            table.insert(refinedList, obj.hit_object)
        else
            if func(obj.hit_object) then
                table.insert(refinedList, obj.hit_object)
            end
        end
    end

    return refinedList
end



--Button/input creation
function makeText()
  -- Create textbox
  local input_parameters = {}
  input_parameters.input_function = "inputTyped"
  input_parameters.function_owner = self
  input_parameters.position = {2.5,0.2,0}
  input_parameters.width = 1000
  input_parameters.scale = {1,1,1}
  input_parameters.height = 1800
  input_parameters.font_size = 50
  input_parameters.tooltip = "Paste the card names here"
  input_parameters.alignment = 2
  input_parameters.value="Paste here"
  self.createInput(input_parameters)
  textInput = input_parameters.value
end

function inputTyped(objectInputTyped, playerColorTyped, input_value, selected)
    textInput = input_value
end


function createInputs()
    function colInput(w,x,y,z) input_change(w,x,y,z,"col") end
    self.createInput({
        input_function="colInput", function_owner=self, tooltip="Columns",
        alignment=3, position={0.2,0.1,-0.415}, height=250, width=630,
        font_size=226, validation=2, tab=2, value=layoutData.col
    })
    function rowInput(w,x,y,z) input_change(w,x,y,z,"row") end
    self.createInput({
        input_function="rowInput", function_owner=self, tooltip="Rows",
        alignment=3, position={0.2,0.1,0.195}, height=250, width=630,
        font_size=226, validation=2, tab=2, value=layoutData.row
    })
end

function createClickButtons()
    self.createButton({
        click_function="click_submit", function_owner=self,
        position={0.45,0.1,0.695}, height=190, width=440, color={1,1,1,0}
    })
    self.createButton({
        click_function="click_preview", function_owner=self,
        position={-0.45,0.1,0.695}, height=190, width=440, color={1,1,1,0}
    })
end
