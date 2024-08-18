-- helpers
local function splitstr(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- pseudo-classes
local function Slider(t)
    local slider = {
        type = 'slider',
    }

    if t.name ~= nil then
        slider.name = t.name
    else
        slider.name = 'Unnamed slider'
    end

    if t.min ~= nil then
        slider.min = t.min
    else
        slider.min = 0
    end

    if t.max ~= nil then
        slider.max = t.max
    else
        slider.max = 100
    end

    if t.step ~= nil then
        slider.step = t.step
    else
        slider.step = 1
    end

    if t.value ~= nil then
        slider.value = t.value
    else
        slider.value = slider.min
    end

    if t.onChange ~= nil then
        slider.onChange = t.onChange
    end

    function slider:onLeft()
        self.value = math.max(self.value - self.step, self.min)
    end
    function slider:onRight()
        self.value = math.min(self.value + self.step, self.max)
    end

    return slider
end

local function Menu(t)
    local menu = {
        options = t,
        selectedOptionID = 1,

        fetch = function(self, name)
            for i, v in ipairs(self.options) do
                if v.name == name then
                    return i
                end
            end
        end
    }

    return menu
end

return {
    Slider = Slider,

    Menu = Menu,
}