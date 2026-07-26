-- Mock for libraries/windfield/init.lua
-- Provides just enough to let Player.new() and Player:applyMovement() run

local wf = {}

function wf.newWorld(gx, gy)
    local world = {}

    function world:newBSGRectangleCollider(x, y, w, h, offset)
        local collider = {
            _x = x,
            _y = y,
            _w = w,
            _h = h,
            _fixedRotation = false,
            _vx = 0,
            _vy = 0,
        }

        function collider:setFixedRotation(bool)
            collider._fixedRotation = bool
        end

        function collider:setLinearVelocity(vx, vy)
            collider._vx = vx or 0
            collider._vy = vy or 0
            -- simulate displacement
            collider._x = collider._x + (collider._vx * 0.016)  -- assumes ~60fps
            collider._y = collider._y + (collider._vy * 0.016)
        end

        function collider:getX()
            return collider._x
        end

        function collider:getY()
            return collider._y
        end

        function collider:setX(x)
            collider._x = x
        end

        function collider:setY(y)
            collider._y = y
        end

        return collider
    end

    function world:newRectangleCollider(x, y, w, h)
        local collider = {
            _x = x,
            _y = y,
            _w = w,
            _h = h,
            _type = "dynamic",
        }

        function collider:setType(t)
            collider._type = t
        end

        return collider
    end

    function world:update(dt)
        -- no-op
    end

    function world:draw()
        -- no-op
    end

    return world
end

return wf