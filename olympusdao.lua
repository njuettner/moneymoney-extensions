-- Inofficial OHM Token Distribution Extension for MoneyMoney
-- Fetches OHM Token quantity for address via etherscan API
-- Fetches OHM price in EUR via cryptocompare API
-- Returns cryptoassets as securities
--
-- Username: OHM Token Adresses comma seperated
-- Password: Etherscan API-Key

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
  description = "Include your OHM Tokens as cryptoportfolio in MoneyMoney by providing a OHM Etheradresses (usernme, comma seperated) and etherscan-API-Key (Password)",
  services= { "OHM Tokens" }
}

local ohmAddresses
local etherscanApiKey
local contractAddress = "0x31932e6e45012476ba3a3a4953cba62aee77fbbe"
local connection = Connection()
local currency = "EUR"

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "OHM Tokens"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  ohmAddresses = username:gsub("%s+", "")
  etherscanApiKey = password
end

function ListAccounts (knownAccounts)
  local account = {
    name = "OHM Token",
    accountNumber = "Crypto Asset OHM Token",
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  local s = {}
  prices = requestOhmPrice()

  for address in string.gmatch(ohmAddresses, '([^,]+)') do
    weiQuantity = requestWeiQuantityForOhmAddress(address)
    ohmQuantity = convertWeiToOHM(weiQuantity)

    s[#s+1] = {
      name = address,
      currency = nil,
      market = "cryptocompare",
      quantity = ohmQuantity,
      price = prices["olympus"]["eur"],
    }
  end

  return {securities = s}
end

function EndSession ()
end

-- Querry Functions
function requestOhmPrice()
  content = connection:request("GET", cryptocompareRequestUrl(), {})
  json = JSON(content)

  return json:dictionary()
end

function requestWeiQuantityForOhmAddress(ohmAddress)
  content = connection:request("GET", etherscanRequestUrl(ohmAddress), {})
  json = JSON(content)

  return json:dictionary()["result"]
end


-- Helper Functions
function convertWeiToOHM(wei)
  return wei / 1000000000
end

function cryptocompareRequestUrl()
  return "https://api.coingecko.com/api/v3/simple/price?ids=olympus&vs_currencies=eur"
end

function etherscanRequestUrl(ohmAddress)
  etherscanRoot = "https://api.etherscan.io/api?"
  params = "&module=account&action=tokenbalance&tag=latest&contractaddress=" .. contractAddress
  address = "&address=" .. ohmAddress
  apiKey = "&apikey=" .. etherscanApiKey

  return etherscanRoot .. params .. address .. apiKey
end

