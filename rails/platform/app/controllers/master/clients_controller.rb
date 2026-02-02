# frozen_string_literal: true

module Master
  class ClientsController < ApplicationController
    before_action :authorize_master_access
    before_action :set_client, only: %i[show edit update destroy]

    def index
      @clients = Client.order(:code)
    end

    def show; end

    def new
      @client = Client.new
    end

    def edit; end

    def create
      @client = Client.new(client_params)

      if @client.save
        redirect_to master_clients_path, notice: "顧客を登録しました"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @client.update(client_params)
        redirect_to master_clients_path, notice: "顧客を更新しました"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      if @client.destroy
        redirect_to master_clients_path, notice: "顧客を削除しました"
      else
        redirect_to master_clients_path, alert: "削除できませんでした: #{@client.errors.full_messages.join(', ')}"
      end
    end

    private

    def set_client
      @client = Client.find(params[:id])
    end

    def authorize_master_access
      authorize_feature!(:master)
    end

    def client_params
      params.require(:client).permit(
        :code, :name, :name_kana, :postal_code, :address,
        :phone, :contact_name, :contact_email, :payment_terms_text, :notes
      )
    end
  end
end
