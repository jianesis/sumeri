module Peatio
  module EveriToken
    class Wallet < Peatio::Wallet::Abstract
      include CashAddressFormat

      def initialize(settings = {})
        @settings = settings
      end

      def configure(settings = {})
        # Clean client state during configure.
        @client = nil

        @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))

        @wallet = @settings.fetch(:wallet) do
          raise Peatio::Wallet::MissingSettingError, :wallet
        end.slice(:uri, :address)

        @currency = @settings.fetch(:currency) do
          raise Peatio::Wallet::MissingSettingError, :currency
        end.slice(:id, :base_factor, :options)
      end

      def create_address!(_options = {})
        res = client.json_rpc("generate_address", "" , "3000")
        { address: res["address"], secret: res["key"] }
      rescue EveriToken::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      # def create_transaction!(transaction, options = {})
      #   txid = client.json_rpc(:sendtoaddress,
      #                          [
      #                            normalize_address(transaction.to_address),
      #                            transaction.amount,
      #                            '',
      #                            '',
      #                            options[:subtract_fee].to_s == 'true' # subtract fee from transaction amount.
      #                          ])
      #   transaction.hash = txid
      #   transaction
      # rescue EveriToken::Client::Error => e
      #   raise Peatio::Wallet::ClientError, e
      # end

      # def load_balance!
      #   client.json_rpc(:getbalance).to_d

      # rescue EveriToken::Client::Error => e
      #   raise Peatio::Wallet::ClientError, e
      # end
      
      def get_info
        client.json_rpc("get_info", "chain", "8888")
      rescue EveriToken::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end
  
      def chain_abi_json_to_bin(to_address: , amount: , from_address: ENV["EVERI_BASE_ADDRESS"], decimal: 4, key: "11575")
        client.json_rpc("abi_json_to_bin", "chain", "8888", 
        {
          "action": "transferft",
          "args": {
              "from": from_address,
              "to": to_address,
              "number": "#{"%.#{decimal}f" % amount} S##{key}",
              "memo": "From VHCEx"
          }
        })
      rescue EveriToken::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end
  
      def trx_json_to_digest(hash: , data: , from_address: ENV["EVERI_BASE_ADDRESS"], key: "11575")
        client.json_rpc("trx_json_to_digest", "chain", "8888",
        {
          "expiration": hash[:expiry],
          "ref_block_num": hash[:last_irreversible_block_num],
          "ref_block_prefix": hash[:last_irreversible_block_prefix],
          "max_charge": 10000,
          "payer": from_address,
          "actions": [
              {
                  "name": "transferft",
                  "domain": ".fungible",
                  "key": key,
                  "data": data,
              }
          ],
          "transaction_extensions": []
        })
      rescue EveriToken::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end
  
      def create_transaction!(transaction , from_address: ENV["EVERI_BASE_ADDRESS"], private_key: ENV["EVERI_PRIVATE_KEY"])
        hash = standard_hash
        data = chain_abi_json_to_bin(to_address: transaction.to_address, amount: transaction.amount, from_address: from_address)["binargs"]
        digest = trx_json_to_digest(hash: hash, data: data, from_address: from_address )["digest"]
        signature = sign(digest: digest, private_key: private_key)
        respond = call_push_transaction(signature: signature, hash: hash, data: data, from_address: from_address, key: "11575")
      end
  
      def send_evt_from_base(to_address:, amount:, from_address:ENV["EVERI_BASE_ADDRESS"], private_key:ENV["EVERI_PRIVATE_KEY"])
        hash = standard_hash
        data = chain_abi_json_to_bin(to_address: to_address, amount: amount, from_address: from_address, decimal: 5, key: "1")["binargs"]
        digest = trx_json_to_digest(hash: hash, data: data , from_address: from_address, key: "1")["digest"]
        signature = sign(digest: digest, private_key: private_key)
        respond = call_push_transaction(signature: signature, hash: hash, data: data, from_address: from_address, key: "1")
      end
  
      def standard_hash
        hash = get_info["last_irreversible_block_id"]
        standard = {
          last_irreversible_block_num: [hash.slice(4, 4)].pack('H*').unpack('S>').first,
          last_irreversible_block_prefix: [hash.slice(16, 8)].pack('H*').unpack('L<').first,
          expiry: (Time.now.utc + 30.minutes).to_s.gsub(" ", "T")
        }
      end
  
      def call_push_transaction(signature: , hash: , data: , from_address: , key: )
        client.json_rpc("push_transaction", "chain", "8888",
        {
          "signatures": [
            signature
          ],
          "compression": "none",
          "transaction": {
              "expiration": hash[:expiry],
              "ref_block_num": hash[:last_irreversible_block_num],
              "ref_block_prefix": hash[:last_irreversible_block_prefix],
              "max_charge": 10000,
              "payer": from_address,
              "actions": [
                  {
                    "name": "transferft",
                    "domain": ".fungible",
                    "key": key,
                      "data": data
                  }
              ],
              "transaction_extensions": []
          }
        })
      rescue EveriToken::Client::Error => e
        raise Peatio::Wallet::ClientError, e
      end

      private

      def client
        uri = @wallet.fetch(:uri) { raise Peatio::Wallet::MissingSettingError, :uri }
        @client ||= Client.new(uri)
      end
    end
  end
end
