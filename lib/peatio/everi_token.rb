require "active_support/core_ext/object/blank"
require "active_support/core_ext/enumerable"
require "active_support/core_ext/string/inquiry"
require "peatio"

module Peatio
  module EveriToken
    require "bigdecimal"
    require "bigdecimal/util"
    require "cash_addr"

    require "peatio/everi_token/concerns/cash_address_format"

    require "peatio/everi_token/blockchain"
    require "peatio/everi_token/client"
    require "peatio/everi_token/wallet"

    require "peatio/everi_token/hooks"

    require "peatio/everi_token/version"
  end
end
