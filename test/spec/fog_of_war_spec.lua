-- Unit tests for src/fog_of_war.lua

require("test.mocks.love_mock")

local FoW = require("src.fog_of_war")

describe("FoW.init", function()
    it("returns a correctly sized 2D grid initialized to 0", function()
        local vis = FoW.init(5, 4)
        -- 5 columns
        assert.are.equal(5, #vis)
        for col = 1, 5 do
            assert.are.equal(4, #vis[col])
            for row = 1, 4 do
                assert.are.equal(0, vis[col][row])
            end
        end
    end)

    it("handles 1x1 grid", function()
        local vis = FoW.init(1, 1)
        assert.are.equal(1, #vis)
        assert.are.equal(1, #vis[1])
        assert.are.equal(0, vis[1][1])
    end)

    it("handles empty grid (0 columns)", function()
        local vis = FoW.init(0, 0)
        assert.are.equal(0, #vis)
    end)

    it("returns a new grid on each call", function()
        local a = FoW.init(3, 3)
        local b = FoW.init(3, 3)
        a[1][1] = 9
        assert.are.equal(0, b[1][1])
    end)
end)

describe("FoW.update", function()
    local tileW, tileH = 32, 32
    local gridCols, gridRows = 10, 8
    -- map spans from 0 to 320x by 0 to 256y

    it("marks tiles around the player as visible (state 2)", function()
        local vis = FoW.init(gridCols, gridRows)
        -- player at center of tile (5,4) — world coords (5*32, 4*32) = (160, 128)
        FoW.update(vis, 160, 128, 100, tileW, tileH, gridCols, gridRows)

        -- player's tile col=5+1=6, row=4+1=5 should be visible (2)
        assert.are.equal(2, vis[6][5])
        -- far tile should stay 0
        assert.are.equal(0, vis[1][1])
        assert.are.equal(0, vis[10][8])
    end)

    it("demotes previously visible tiles to explored (state 2 → 1)", function()
        local vis = FoW.init(gridCols, gridRows)
        -- set player at (160, 128) → mark some tiles visible
        FoW.update(vis, 160, 128, 100, tileW, tileH, gridCols, gridRows)

        assert.are.equal(2, vis[6][5])

        -- now move player far away so old tiles are no longer visible
        FoW.update(vis, 320, 256, 10, tileW, tileH, gridCols, gridRows)
        -- the old visible tile should now be explored (1), not visible (2) nor unexplored (0)
        assert.are.equal(1, vis[6][5])
    end)

    it("does not change explored tiles back to unexplored", function()
        local vis = FoW.init(gridCols, gridRows)
        -- first reveal
        FoW.update(vis, 160, 128, 100, tileW, tileH, gridCols, gridRows)
        assert.are.equal(2, vis[6][5])

        -- move away
        FoW.update(vis, 320, 256, 1, tileW, tileH, gridCols, gridRows)
        assert.are.equal(1, vis[6][5])

        -- another update with player still away: should remain explored (1)
        FoW.update(vis, 320, 256, 1, tileW, tileH, gridCols, gridRows)
        assert.are.equal(1, vis[6][5])
    end)

    it("keeps tile visible if player stays in range", function()
        local vis = FoW.init(gridCols, gridRows)
        FoW.update(vis, 160, 128, 100, tileW, tileH, gridCols, gridRows)
        assert.are.equal(2, vis[6][5])
        FoW.update(vis, 160, 128, 100, tileW, tileH, gridCols, gridRows)
        assert.are.equal(2, vis[6][5])
    end)

    it("clamps view area to grid boundaries", function()
        local vis = FoW.init(gridCols, gridRows)
        -- player at (0, 0) with huge radius should cover entire grid without error
        FoW.update(vis, 0, 0, 9999, tileW, tileH, gridCols, gridRows)
        -- all tiles should be visible
        for col = 1, gridCols do
            for row = 1, gridRows do
                assert.are.equal(2, vis[col][row])
            end
        end
    end)

    it("uses Euclidean distance for visibility calculation", function()
        local vis = FoW.init(5, 5)
        -- player at center of tile (3,3) → world (2*32+16, 2*32+16) = (80, 80)
        -- tile (1,1) center is at (16, 16)
        -- distance = sqrt(64^2 + 64^2) = sqrt(8192) ≈ 90.51
        FoW.update(vis, 80, 80, 91, tileW, tileH, 5, 5)
        assert.are.equal(2, vis[1][1])

        -- reset and test with radius just below threshold
        local vis2 = FoW.init(5, 5)
        FoW.update(vis2, 80, 80, 90, tileW, tileH, 5, 5)
        assert.are.equal(0, vis2[1][1])
    end)
end)

describe("FoW.draw", function()
    local tileW, tileH = 32, 32
    local gridCols, gridRows = 4, 3

    it("draws opaque black rects for unexplored tiles (state 0)", function()
        local vis = FoW.init(1, 1)
        -- tile is 0 (unexplored) — FoW.draw sets setColor(0,0,0,1) for this tile,
        -- then sets setColor(1,1,1,1) at the end
        love.graphics._lastColor = nil
        love.graphics._lastRect = nil

        FoW.draw(vis, tileW, tileH, 1, 1)

        -- final setColor is always (1,1,1,1)
        assert.are.equal(1, love.graphics._lastColor[1])
        assert.are.equal(1, love.graphics._lastColor[2])
        assert.are.equal(1, love.graphics._lastColor[3])
        assert.are.equal(1, love.graphics._lastColor[4])
        -- but a rect was drawn for the unexplored tile
        assert.is_not_nil(love.graphics._lastRect)
    end)

    it("draws dimmed rects for explored tiles (state 1)", function()
        local vis2 = FoW.init(1, 1)
        vis2[1][1] = 1 -- explored

        love.graphics._lastColor = nil
        love.graphics._lastRect = nil
        FoW.draw(vis2, tileW, tileH, 1, 1)

        -- last setColor is white (reset at end), but rect was drawn for state 1
        assert.are.equal(1, love.graphics._lastColor[1])
        assert.are.equal(1, love.graphics._lastColor[2])
        assert.are.equal(1, love.graphics._lastColor[3])
        assert.are.equal(1, love.graphics._lastColor[4])
        assert.is_not_nil(love.graphics._lastRect)
    end)

    it("does not draw any rect for visible tiles (state 2)", function()
        local vis = FoW.init(1, 1)
        vis[1][1] = 2 -- visible

        love.graphics._lastColor = nil
        love.graphics._lastRect = nil
        FoW.draw(vis, tileW, tileH, 1, 1)

        -- setColor is called only at the end (white reset), no rect drawn
        assert.are.equal(1, love.graphics._lastColor[1])
        assert.are.equal(1, love.graphics._lastColor[2])
        assert.are.equal(1, love.graphics._lastColor[3])
        assert.are.equal(1, love.graphics._lastColor[4])
        assert.is_nil(love.graphics._lastRect)
    end)

    it("resets color to white after drawing", function()
        local vis = FoW.init(gridCols, gridRows)
        love.graphics._lastColor = nil
        FoW.draw(vis, tileW, tileH, gridCols, gridRows)
        -- final setColor call should be white
        assert.are.equal(1, love.graphics._lastColor[1])
        assert.are.equal(1, love.graphics._lastColor[2])
        assert.are.equal(1, love.graphics._lastColor[3])
        assert.are.equal(1, love.graphics._lastColor[4])
    end)
end)