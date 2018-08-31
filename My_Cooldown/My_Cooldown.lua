local timers = {}

local function GetTimeText(seconds)
    if seconds < 5 then
        return floor(seconds), 1, 0, 0, 0.2
    elseif seconds < 100 then
        return floor(seconds), 1, 1, 0, seconds - floor(seconds)
    elseif seconds < 3600 then
        local text = ceil(seconds / 60) .. "m"
        local nextUpdate
        if seconds < 120 then
            nextUpdate = seconds - 100
        else
            nextUpdate = seconds % 60
        end
        return text, 1, 1, 1, nextUpdate
    elseif seconds < 86400 then
        return ceil(seconds / 3600) .. "h", 1, 1, 1, seconds % 3600
    end
    return ceil(seconds / 86400) .. "d", 1, 1, 1, seconds % 86400
end

local function CreateTimer(cd)
    local parent = cd:GetParent()
    local size = parent:GetSize()
    if size >= 20 then
        local frame = parent
        local name = frame:GetName()
        while not name do
            frame = frame:GetParent()
            name = frame:GetName()
        end

        if not name:find("ThreatPlatesFrame") and not name:find("LossOfControlFrame") then
            local type = name:find("SUF") and "Aura" or "Action"
            local timer = CreateFrame("Frame", nil, parent)
            timer:SetAllPoints(parent)

            timer.cd = cd
            timer.nextUpdate = 0

            timer.text = timer:CreateFontString(nil, "Overlay")
            local fontSize = floor(0.5 * size)
            if fontSize > 15 then
                fontSize = 15
            end
            timer.text:SetFont("Fonts\\ARHei.ttf", fontSize, "Outline")
            if type == "Aura" then
                timer.text:SetPoint("TopRight", timer, "TopRight", 0, 0)
            else
                timer.text:SetPoint("Center", timer, "Center", 0, 0)
            end
            timers[cd] = timer

            timer:SetScript("OnUpdate", function(self, elapsed)
                -- cd未顯示時，隱藏timer，例如總是顯示快捷列時，移動冷卻中的技能到另一個按鈕時，原按鈕位置應該不再顯示計時
                if not self.cd:IsShown() then
                    self:Hide()
                end

                self.elapsed = (self.elapsed or 0) + elapsed
                if self.elapsed < self.nextUpdate then
                    return
                end
                self.elapsed = 0

                local remain = self.start + self.duration - GetTime()
                -- 大於最大顯示時間時，隱藏文字顯示
                if remain > 864000 then
                    if self.text:IsShown() then
                        self.nextUpdate = remain % 864000
                        self.text:Hide()
                    end
                else
                    if not self.text:IsShown() then
                        self.text:Show()
                    end
                end

                if self.text:IsShown() then
                    local text, r, g, b, nextUpdate = GetTimeText(remain)
                    self.text:SetText(text)
                    self.text:SetTextColor(r, g, b)
                    self.nextUpdate = nextUpdate
                end

                if remain < 0.2 then
                    self:Hide()
                end
            end)

            -- 顯示timer時立即更新
            timer:SetScript("OnShow", function(self)
                self.nextUpdate = 0
            end)

            return timer
        end
    end
end

local f = CreateFrame("Cooldown", nil, nil, "CooldownFrameTemplate")
local mt = getmetatable(f).__index
hooksecurefunc(mt, "SetCooldown", function(cd, start, duration)
    -- 2：最小時間，公共冷卻時間不顯示
    if duration > 2 then
        -- 使用key作爲該cd內容的標記
        local key = ("%s-%s"):format(floor(start * 1000), floor(duration * 1000))
        local timer = timers[cd] or CreateTimer(cd)
        if timer then
            timer.start = start
            timer.duration = duration
            -- 當該cd的內容發生變化時立即更新，例如右鍵取消suf上一個光環時，下一個光環移到上一個的位置，需要立即更新計時
            if timer.key ~= key then
                timer.key = key
                timer.nextUpdate = 0
            end
            timer:Show()
        end
    end
end)