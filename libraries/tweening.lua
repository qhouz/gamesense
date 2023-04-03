local f = string.format;
local floor, ceil, abs, minf = math.floor, math.ceil, math.abs, math.min;
local type, assert, setmetatable = type, assert, setmetatable;

local globals_frametime = globals.frametime;
local vtable_bind = vtable_bind;

-- @package tweening
local tweening = {}; do
    -- @private
    local native_GetTimescale = vtable_bind("engine.dll", "VEngineClient014", 91, "float(__thiscall*)(void*)");

    local function solve(easing_fn, prev, new, clock, duration)
        local prev = easing_fn(clock, prev, new - prev, duration);

        if type(prev) == "number" then
            if abs(new - prev) <= .01 then
                return new;
            end

            local fmod = prev % 1;

            if fmod < .001 then
                return floor(prev);
            end

            if fmod > .999 then
                return ceil(prev);
            end
        end

        return prev;
    end

    -- @class mt
    local mt = {}; do
        local function update(self, duration, target, easing_fn)
            local value_type = type(self.value);
            local target_type = type(target);

            if target_type == "boolean" then
                target = target and 1 or 0;
                target_type = "number";
            end

            assert(value_type == target_type, f("type mismatch, expected %s (received %s)", value_type, target_type));

            if target ~= self.to then
                self.clock = 0;

                self.from = self.value;
                self.to = target;
            end

            local clock = globals_frametime() / native_GetTimescale();
            local duration = duration or .15;

            if self.clock == duration then
                return target;
            end

            if clock <= 0 and clock >= duration then
                self.clock = 0;

                self.from = target;
                self.to = target;

                self.value = target;

                return target;
            end

            self.clock = minf(self.clock + clock, duration);
            self.value = solve(easing_fn or self.easing, self.from, target, self.clock, duration);

            return self.value;
        end

        mt.__metatable = false;
        mt.__call = update;
        mt.__index = mt;
    end

    -- @public
    function tweening:new(default, easing_fn)
        if type(default) == "boolean" then
            default = default and 1 or 0;
        end

        local this = {};

        this.clock = 0;
        this.value = default or 0;

        this.easing = easing_fn or function(t, b, c, d)
            return c * t / d + b;
        end

        return setmetatable(this, mt);
    end
end

return tweening;
