-- Inofficial TAO Token Distribution Extension for MoneyMoney
-- Fetches TAO Token quantity for address via bscscan API
-- Fetches TAO price in EUR via cryptocompare API
-- Returns cryptoassets as securities
--
-- Username: TAO Token Adresses comma seperated
-- Password: BSCscan API-Key

-- MIT License

-- Copyright (c) 2021 Nick Jüttner:

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


WebBanking{
  version = 0.1,
  description = "Include your TAO Tokens as cryptoportfolio in MoneyMoney by providing a TAO BSC addresses (usernme, comma seperated) and bscscan-API-Key (Password)",
  services= { "TAO Tokens" }
}

local taoAddresses
local bscscanApiKey
local contractAddress = "0xe12d3c8675a88fedcf61946089079323342982bb"
local connection = Connection()
local currency = "EUR"

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "TAO Tokens"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  taoAddresses = username:gsub("%s+", "")
  bscscanApiKey = password
end

function ListAccounts (knownAccounts)
  local account = {
    name = "TAO Token",
    accountNumber = "Crypto Asset TAO Token",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  local s = {}
  prices = requestTaoPrice()

  for address in string.gmatch(taoAddresses, '([^,]+)') do
    weiQuantity = requestWeiQuantityForTaoAddress(address)
    taoQuantity = convertWeiToTAO(weiQuantity)

    s[#s+1] = {
      name = address,
      currency = nil,
      market = "cryptocompare",
      quantity = taoQuantity,
      price = prices["taodao"]["eur"],
    }
  end

  return {securities = s}
end

function EndSession ()
end

-- Querry Functions
function requestTaoPrice()
  content = connection:request("GET", cryptocompareRequestUrl(), {})
  json = JSON(content)

  return json:dictionary()
end

function requestWeiQuantityForTaoAddress(taoAddress)
  content = connection:request("GET", bscscanRequestUrl(taoAddress), {})
  json = JSON(content)

  return json:dictionary()["result"]
end


-- Helper Functions
function convertWeiToTAO(wei)
  return wei / 1000000000
end

function cryptocompareRequestUrl()
  return "https://api.coingecko.com/api/v3/simple/price?ids=taodao&vs_currencies=eur"
end

function bscscanRequestUrl(taoAddress)
  bscscanRoot = "https://api.bscscan.com/api?"
  params = "&module=account&action=tokenbalance&tag=latest&contractaddress=" .. contractAddress
  address = "&address=" .. taoAddress
  apiKey = "&apikey=" .. bscscanApiKey

  return bscscanRoot .. params .. address .. apiKey
end

