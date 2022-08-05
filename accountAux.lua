local component = require("component")
local internet = require("internet")
local filesystem = require("filesystem")
local shell = require("shell")

local urlAccount = "https://data.dasrex.xyz/accountCreation"
local webIdPath = "/home/myaenetwork/webIdentification.txt"
local workDirectory = "/home/myaenetwork/"
local newDirectory = "/home/myaenetwork"

local bs = { [0] =
   'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
   'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
   'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
   'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/',
}

function encode(s)
   local byte, rep = string.byte, string.rep
   local pad = 2 - ((#s-1) % 3)
   s = (s..rep('\0', pad)):gsub("...", function(cs)
      local a, b, c = byte(cs, 1, 3)
      return bs[a>>2] .. bs[(a&3)<<4|b>>4] .. bs[(b&15)<<2|c>>6] .. bs[c&63]
   end)
   return s:sub(1, #s-pad) .. rep('=', pad)
end

function isConfigCorrect(rid, rusername,rpassword) --checks if each line of the identification file as the right data 
    if rid == nil or rusername == nil or rpassword == nil then
        return false
    end
    if rid == "" or rusername == "" or rpassword == "" then
        return false
    else
        return true
    end
end

function createAccount()
    print("Let's configure your account")
    print("The account is linked to the computer, you will use the account username and password to connect on the web page")
    print("Choose your account username")
    local id = math.floor(math.random(1000000))
    local username = io.read()
    while username == "" or string.match(username, ";") do
        print("Your username cannot be empty or contain ';'")
        print("Choose your account username.")
        username = io.read()
    end
    print("Your username is ".. username)
    print()
    print("Choose your account password.")
    print("DO NOT USE A SENSITIVE PASSWORD, THEY ARE NOT ENCRYPTED")
    print("I RECOMMAND YOU TO USE A PIN/SMALL PASSWORD")
    local password = io.read()
    while password == ""  or string.match(password, ";") do
        print("Your password cannot be empty or contain ';'")
        print("Choose your account password.")
        password = io.read()
    end
    if accountToServer(id,username,password) then 
        print("Account creation accepted by the server")
    else
        print("Account creation denied by the server")
        print("Server might be offline or account already registered")
        print("Please try the account creation one more time WITH A DIFFERENT USERNAME. Otherwise contact PoroCoco#4636 on Discord")
        return
    end
    local f = io.open(webIdPath,"w") -- writes the infos into the identification file
    f:write("id = "..tostring(id), "\n")
    f:write("username = "..username, "\n")
    f:write("password = "..password)
    f:close()
    print("Configuration is done !")
end

function accountToServer(id, username, password)
    local accountData = tostring(id)..";"..username..";"..password
    shell.setWorkingDirectory("/home/") -- if the server is down, internet.request will give an error so before trying it's going back to the basic dir 
    if internet.request(urlAccount, encode(accountData))() == "Account accepted" then
        shell.setWorkingDirectory(workDirectory)
        return true
    else 
        shell.setWorkingDirectory(workDirectory)
        return false
    end
end

if component.isAvailable("internet") then
    filesystem.makeDirectory(newDirectory)
    shell.setWorkingDirectory(workDirectory)
    if filesystem.exists(webIdPath) then --tries to read the identification file, if it cannot start an account creation
        local f = io.open(webIdPath,"r")
        local rid = f:read('*l')
        local rusername = f:read('*l')
        local rpassword = f:read('*l')
        if isConfigCorrect(rid,rusername,rpassword) then
            print("Computer is already configured")
            print("Your account "..rusername)
            print("Show account password ? Yes/No")
            if io.read() == "Yes" then
                print("Your account "..rpassword)
            end
        else
            print("config file isn't correct. Remaking one")
            createAccount()
        end
        f:close()
        shell.setWorkingDirectory("/home/")
    else 
        createAccount()
        shell.setWorkingDirectory("/home/")
    end
else
    print("Please insert the Internet Card into the computer")
end
