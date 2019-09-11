module Peatio
  module EveriToken
    module Hooks
      BLOCKCHAIN_VERSION_REQUIREMENT = "~> 1.0.0"
      WALLET_VERSION_REQUIREMENT = "~> 1.0.0"

      class << self
        def check_compatibility
          unless Gem::Requirement.new(BLOCKCHAIN_VERSION_REQUIREMENT)
                                 .satisfied_by?(Gem::Version.new(Peatio::EveriToken::VERSION))
            [
              "EveriToken blockchain version requirement was not satisfied by Peatio::Blockchain.",
              "EveriToken blockchain requires #{BLOCKCHAIN_VERSION_REQUIREMENT}.",
              "Peatio::Blockchain version is #{Peatio::Blockchain::VERSION}"
            ].join('\n').tap { |s| Kernel.abort s }
          end

          unless Gem::Requirement.new(WALLET_VERSION_REQUIREMENT)
                                 .satisfied_by?(Gem::Version.new(Peatio::Wallet::VERSION))
            [
              "EveriToken wallet version requirement was not satisfied by Peatio::Wallet.",
              "EveriToken wallet requires #{WALLET_VERSION_REQUIREMENT}.",
              "Peatio::Wallet version is #{Peatio::Wallet::VERSION}"
            ].join('\n').tap { |s| Kernel.abort s }
          end
        end

        def register
          Peatio::Blockchain.registry[:everitoken] = EveriToken::Blockchain.new
          Peatio::Wallet.registry[:everitoken] = EveriToken::Wallet.new
        end
      end

      if defined?(Rails::Railtie)
        require "peatio/everitoken/railtie"
      else
        check_compatibility
        register
      end
    end
  end
end
