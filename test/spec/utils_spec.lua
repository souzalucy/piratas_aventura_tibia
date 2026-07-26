-- Unit tests for src/utils.lua

local utils = require("src.utils")

describe("utils.distance", function()
    it("returns 0 for same point", function()
        assert.are.equal(0, utils.distance(5, 5, 5, 5))
    end)

    it("calculates horizontal distance", function()
        assert.are.equal(4, utils.distance(0, 0, 4, 0))
    end)

    it("calculates vertical distance", function()
        assert.are.equal(3, utils.distance(0, 0, 0, 3))
    end)

    it("calculates diagonal distance (3-4-5 triangle)", function()
        assert.are.equal(5, utils.distance(0, 0, 3, 4))
    end)

    it("handles negative coordinates", function()
        assert.are.equal(5, utils.distance(-1, -1, 2, 3))
    end)
end)

describe("utils.pointInCircle", function()
    it("returns true when point is exactly at center", function()
        assert.is_true(utils.pointInCircle(0, 0, 0, 0, 10))
    end)

    it("returns true when point is inside the circle", function()
        assert.is_true(utils.pointInCircle(3, 4, 0, 0, 10))
    end)

    it("returns true when point is exactly on the radius", function()
        assert.is_true(utils.pointInCircle(10, 0, 0, 0, 10))
    end)

    it("returns false when point is outside the circle", function()
        assert.is_false(utils.pointInCircle(11, 0, 0, 0, 10))
    end)
end)

describe("utils.clamp", function()
    it("returns value when within range", function()
        assert.are.equal(5, utils.clamp(5, 0, 10))
    end)

    it("returns min when value is below minimum", function()
        assert.are.equal(0, utils.clamp(-5, 0, 10))
    end)

    it("returns max when value is above maximum", function()
        assert.are.equal(10, utils.clamp(15, 0, 10))
    end)

    it("returns min when value equals min", function()
        assert.are.equal(0, utils.clamp(0, 0, 10))
    end)

    it("returns max when value equals max", function()
        assert.are.equal(10, utils.clamp(10, 0, 10))
    end)

    it("works with negative ranges", function()
        assert.are.equal(-7, utils.clamp(-10, -7, 0))
    end)
end)

describe("utils.lerp", function()
    it("returns 'a' when t is 0", function()
        assert.are.equal(10, utils.lerp(10, 20, 0))
    end)

    it("returns 'b' when t is 1", function()
        assert.are.equal(20, utils.lerp(10, 20, 1))
    end)

    it("returns midpoint when t is 0.5", function()
        assert.are.equal(15, utils.lerp(10, 20, 0.5))
    end)

    it("extrapolates beyond range when t > 1", function()
        assert.are.equal(30, utils.lerp(10, 20, 2))
    end)

    it("extrapolates below range when t < 0", function()
        assert.are.equal(0, utils.lerp(10, 20, -1))
    end)
end)

describe("utils.normalizeVector", function()
    it("returns (0, 0) for zero vector", function()
        local vx, vy = utils.normalizeVector(0, 0, 50)
        assert.are.equal(0, vx)
        assert.are.equal(0, vy)
    end)

    it("normalizes pure horizontal vector to full speed", function()
        local vx, vy = utils.normalizeVector(1, 0, 100)
        assert.are.equal(100, vx)
        assert.are.equal(0, vy)
    end)

    it("normalizes pure vertical vector to full speed", function()
        local vx, vy = utils.normalizeVector(0, 1, 100)
        assert.are.equal(0, vx)
        assert.are.equal(100, vy)
    end)

    it("normalizes diagonal vector (both axes equal)", function()
        local vx, vy = utils.normalizeVector(1, 1, 100)
        -- length of (1,1) is sqrt(2) ≈ 1.414
        -- normalized: (100/sqrt(2), 100/sqrt(2)) ≈ (70.71, 70.71)
        local expected = 100 / math.sqrt(2)
        assert.is_near(expected, vx, 0.001)
        assert.is_near(expected, vy, 0.001)
    end)

    it("normalizes arbitrary non-unit vector", function()
        local vx, vy = utils.normalizeVector(3, 4, 50)
        -- length of (3,4) is 5
        -- normalized: (50*3/5, 50*4/5) = (30, 40)
        assert.are.equal(30, vx)
        assert.are.equal(40, vy)
    end)
end)

describe("utils.clampCamera", function()
    it("does not modify camera position when within bounds", function()
        local cam = { x = 200, y = 150 }
        utils.clampCamera(cam, 800, 600, 400, 300)
        assert.are.equal(200, cam.x)
        assert.are.equal(150, cam.y)
    end)

    it("clamps camera to minimum x", function()
        local cam = { x = 50, y = 150 }
        utils.clampCamera(cam, 800, 600, 400, 300)
        assert.are.equal(200, cam.x)
        assert.are.equal(150, cam.y)
    end)

    it("clamps camera to minimum y", function()
        local cam = { x = 200, y = 50 }
        utils.clampCamera(cam, 800, 600, 400, 300)
        assert.are.equal(200, cam.x)
        assert.are.equal(150, cam.y)
    end)

    it("clamps camera to maximum x", function()
        local cam = { x = 700, y = 150 }
        utils.clampCamera(cam, 800, 600, 400, 300)
        assert.are.equal(600, cam.x)
        assert.are.equal(150, cam.y)
    end)

    it("clamps camera to maximum y", function()
        local cam = { x = 200, y = 500 }
        utils.clampCamera(cam, 800, 600, 400, 300)
        assert.are.equal(200, cam.x)
        assert.are.equal(450, cam.y)
    end)

    it("clamps x to half viewport even when map is smaller than viewport", function()
        -- The min-clamp (cam.x < halfVW) runs unconditionally.
        local cam = { x = 50, y = 150 }
        utils.clampCamera(cam, 300, 600, 400, 300)
        -- halfVW = 200, so x is clamped to 200
        assert.are.equal(200, cam.x)
        assert.are.equal(150, cam.y)
    end)

    it("clamps y to half viewport even when map is smaller than viewport", function()
        -- The min-clamp (cam.y < halfVH) runs unconditionally.
        local cam = { x = 200, y = 50 }
        utils.clampCamera(cam, 800, 200, 400, 300)
        -- halfVH = 150, so y is clamped to 150
        assert.are.equal(200, cam.x)
        assert.are.equal(150, cam.y)
    end)
end)

describe("utils.colors", function()
    describe(".withAlpha", function()
        it("returns color array with alpha appended", function()
            local result = utils.colors.withAlpha(utils.colors.red, 0.5)
            assert.are.same({ 1, 0, 0, 0.5 }, result)
        end)
    end)

    describe(".blend", function()
        it("returns equal mixture at factor 0.5", function()
            local result = utils.colors.blend(
                { 0, 0, 0, 1 },
                { 1, 1, 1, 1 },
                0.5
            )
            assert.are.same({ 0.5, 0.5, 0.5, 1 }, result)
        end)

        it("returns color1 at factor 0", function()
            local result = utils.colors.blend(
                { 0.2, 0.4, 0.6, 0.8 },
                { 0.9, 0.9, 0.9, 0.1 },
                0
            )
            assert.are.same({ 0.2, 0.4, 0.6, 0.8 }, result)
        end)

        it("returns color2 at factor 1", function()
            local result = utils.colors.blend(
                { 0.2, 0.4, 0.6, 0.8 },
                { 0.9, 0.9, 0.9, 0.1 },
                1
            )
            assert.is_near(0.9, result[1], 0.0001)
            assert.is_near(0.9, result[2], 0.0001)
            assert.is_near(0.9, result[3], 0.0001)
            assert.is_near(0.1, result[4], 0.0001)
        end)

        it("defaults missing alpha channels to 1", function()
            local result = utils.colors.blend(
                { 0, 0, 0 },
                { 1, 1, 1 },
                0.5
            )
            assert.are.same({ 0.5, 0.5, 0.5, 1 }, result)
        end)
    end)
end)