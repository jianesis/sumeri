
module Peatio
  module EveriToken
    # TODO: Processing of unconfirmed transactions from mempool isn't supported now.
    class Blockchain < Peatio::Blockchain::Abstract
      include CashAddressFormat

      DEFAULT_FEATURES = {case_sensitive: true, cash_addr_format: false}.freeze

      def initialize(custom_features = {})
        @features = DEFAULT_FEATURES.merge(custom_features).slice(*SUPPORTED_FEATURES)
        @settings = {}
      end

      def configure(settings = {})
        # Clean client state during configure.
        @client = nil

        @settings.merge!(settings.slice(*SUPPORTED_SETTINGS))
      end

      def fetch_block!(block_number)
        histories = client.json_rpc("get_fungible_actions", "history" , "8888", 
        {
          "sym_id": 11575,
          "dire": "desc",
          "skip": 0,
          "take": 20,
        })

        txs = build_transaction(histories)
      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      def latest_block_number
        client.json_rpc("get_head_block_header_state", "chain", "8888")["block_num"]
      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      def load_balance_of_address!(address, currency_id)
        address_with_balance = client.json_rpc("get_fungible_balance", "evt", "8888", {
          "address": address,
          "sym_id": 11575
        })
      rescue Client::Error => e
        raise Peatio::Blockchain::ClientError, e
      end

      private

      def build_transaction(txs)
        txs.each_with_object([]) do |tx, formatted_txs|
          no_currency_tx =
            { hash: tx['trx_id'], txout: '',
              to_address: tx["data"]["to"],
              amount: tx["data"]["amount"].to_d,
              status: 'success' }

          # Build transaction for each currency belonging to blockchain.
          settings_fetch(:currencies).pluck(:id).each do |currency_id|
            formatted_txs << no_currency_tx.merge(currency_id: currency_id)
          end
        end
      end

      def client
        @client ||= Client.new(settings_fetch(:server))
      end

      def settings_fetch(key)
        @settings.fetch(key) { raise Peatio::Blockchain::MissingSettingError, key.to_s }
      end
    end
  end
end
