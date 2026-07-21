--!nocheck
-- GAME SCANNER & REMOTE SPY

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

print("====================================")
print("STARTING GAME SCAN & REMOTE SPY")
print("====================================")

-- ============================================
-- 1. REMOTE SPY (Logs all RemoteEvents fired)
-- ============================================
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" then
        local args = {...}
        local argString = ""
        for i, v in pairs(args) do
            argString = argString .. tostring(v) .. " | "
        end
        print(string.format("[REMOTE SPY] %s -> %s\nArgs: %s", method, tostring(self), argString))
    end
    return oldNamecall(self, ...)
end)
print("[+] Remote Spy Active! Shoot your gun and check F9 console.")

-- ============================================
-- 2. SCRIPT DECOMPILER (Dumps Local & Module scripts)
-- ============================================
local function decompileScript(scriptObj)
    if not decompile then 
        print("[ERROR] Your executor does not support 'decompile()'")
        return nil
    end
    
    local success, source = pcall(function()
        return decompile(scriptObj)
    end)
    
    if success and source then
        return source
    end
    return nil
end

local scriptCount = 0
local gunScripts = {}

print("\n[+] Scanning game for client scripts...")

for _, obj in pairs(game:GetDescendants()) do
    if obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
        scriptCount = scriptCount + 1
        local src = decompileScript(obj)
        if src then
            -- Look for gun-related keywords to find the shooting script
            local lowerSrc = string.lower(src)
            if string.find(lowerSrc, "raycast") or string.find(lowerSrc, "firearm") or string.find(lowerSrc, "bullet") or string.find(lowerSrc, "shoot") or string.find(lowerSrc, "fireserver") then
                table.insert(gunScripts, {Name = obj:GetFullName(), Source = src})
            end
        end
    end
end

print(string.format("[+] Scanned %d scripts.", scriptCount))
print(string.format("[+] Found %d potential gun/combat scripts.", #gunScripts))

print("\n====================================")
print("POTENTIAL COMBAT/GUN SCRIPTS FOUND:")
print("====================================")

for i, data in pairs(gunScripts) do
    print("\n------------------------------------------------")
    print("SCRIPT PATH: " .. data.Name)
    print("------------------------------------------------")
    -- Only print first 2000 characters to avoid console lag
    if #data.Source > 2000 then
        print(string.sub(data.Source, 1, 2000) .. "\n... [TRUNCATED. Full source printed below if smaller]")
    else
        print(data.Source)
    end
end

print("\n====================================")
print("SCAN COMPLETE. Check your F9 Developer Console!")
print("Look for the script that handles 'Raycast' or 'FireServer' for the gun.")
print("====================================")
