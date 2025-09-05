require 'rails_helper'

RSpec.describe "/carts", type: :request do
  let(:product) { create(:product, name: "Test Product", price: 10.0) }
  let(:valid_attributes) {
    {
      cart: {
        product_id: product.id,
        quantity: 2
      }
    }
  }
  let(:invalid_attributes) {
    {
      cart: {
        product_id: product.id,
        quantity: -1
      }
    }
  }
  let(:valid_headers) {
    {}
  }

  describe "GET /show" do
    it "renders a successful response" do
      get carts_url, headers: valid_headers, as: :json
      expect(response).to be_successful
    end

    it "returns cart with products" do
      get carts_url, headers: valid_headers, as: :json

      cart_id = JSON.parse(response.body)["id"]
      cart = Cart.find(cart_id)

      cart_item = create(:cart_item, cart: cart, product: product, quantity: 2)

      get carts_url, headers: valid_headers, as: :json

      expect(response).to be_successful
      expect(response.content_type).to match(a_string_including("application/json"))

      json_response = JSON.parse(response.body)
      expect(json_response["products"]).to be_an(Array)
      expect(json_response["total_price"]).to eq("20.0")
    end
  end

  describe "POST /create" do
    context "with valid parameters" do
      it "creates a new CartItem" do
        expect {
          post carts_url,
               params: valid_attributes, headers: valid_headers, as: :json
        }.to change(CartItem, :count).by(1)
      end

      it "renders a JSON response with the new cart" do
        post carts_url,
             params: valid_attributes, headers: valid_headers, as: :json
        expect(response).to have_http_status(:created)
        expect(response.content_type).to match(a_string_including("application/json"))
      end

      it "updates existing cart item quantity when product already exists" do
        post carts_url,
             params: valid_attributes, headers: valid_headers, as: :json

        post carts_url,
             params: valid_attributes, headers: valid_headers, as: :json

        cart_item = CartItem.last
        expect(cart_item.quantity).to eq(2)
      end
    end

    context "with invalid parameters" do
      it "does not create a new CartItem" do
        expect {
          post carts_url,
               params: invalid_attributes, as: :json
        }.to change(CartItem, :count).by(0)
      end

      it "renders a JSON response with errors" do
        post carts_url,
             params: invalid_attributes, headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "POST /add_item" do
    let(:add_item_attributes) {
      {
        cart: {
          product_id: product.id,
          quantity: 3
        }
      }
    }

    context "with valid parameters" do
      it "adds quantity to existing cart item" do
        post carts_url,
             params: { cart: { product_id: product.id, quantity: 2 } }, headers: valid_headers, as: :json

        expect {
          post add_item_carts_url,
               params: add_item_attributes, headers: valid_headers, as: :json
        }.to change { CartItem.last.reload.quantity }.by(3)
      end

      it "creates new cart item if product doesn't exist in cart" do
        expect {
          post add_item_carts_url,
               params: add_item_attributes, headers: valid_headers, as: :json
        }.to change(CartItem, :count).by(1)
      end

      it "renders a JSON response with the updated cart" do
        post add_item_carts_url,
             params: add_item_attributes, headers: valid_headers, as: :json
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end

    context "with invalid parameters" do
      let(:invalid_add_item_attributes) {
        {
          cart: {
            product_id: product.id,
            quantity: -1
          }
        }
      }

      it "renders a JSON response with errors" do
        post add_item_carts_url,
             params: invalid_add_item_attributes, headers: valid_headers, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to match(a_string_including("application/json"))
      end
    end
  end

  describe "DELETE /remove_item" do
    it "destroys the requested cart item" do
      post carts_url,
           params: { cart: { product_id: product.id, quantity: 2 } }, headers: valid_headers, as: :json

      expect {
        delete remove_item_carts_url(product.id), headers: valid_headers, as: :json
      }.to change(CartItem, :count).by(-1)
    end

    it "renders a JSON response with the updated cart" do
      post carts_url,
           params: { cart: { product_id: product.id, quantity: 2 } }, headers: valid_headers, as: :json

      delete remove_item_carts_url(product.id), headers: valid_headers, as: :json
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to match(a_string_including("application/json"))
    end

    it "returns error when product not found in cart" do
      non_existent_product = create(:product)
      delete remove_item_carts_url(non_existent_product.id), headers: valid_headers, as: :json
      expect(response).to have_http_status(:not_found)
      expect(response.content_type).to match(a_string_including("application/json"))
    end
  end

  describe "session management" do
    it "creates a new cart for new session" do
      expect {
        get carts_url, headers: valid_headers, as: :json
      }.to change(Cart, :count).by(1)
    end

    it "reuses existing cart for same session" do
      get carts_url, headers: valid_headers, as: :json
      first_cart_id = JSON.parse(response.body)["id"]

      get carts_url, headers: valid_headers, as: :json
      second_cart_id = JSON.parse(response.body)["id"]

      expect(first_cart_id).to eq(second_cart_id)
    end
  end

  describe "last_interaction_at updates" do
    it "updates last_interaction_at when adding item" do
      get carts_url, headers: valid_headers, as: :json
      cart_id = JSON.parse(response.body)["id"]
      cart = Cart.find(cart_id)
      cart.update!(last_interaction_at: 1.hour.ago)

      post add_item_carts_url,
           params: valid_attributes, headers: valid_headers, as: :json

      expect(cart.reload.last_interaction_at).to be > 1.hour.ago
    end

    it "updates last_interaction_at when removing item" do
      post carts_url,
           params: { cart: { product_id: product.id, quantity: 2 } }, headers: valid_headers, as: :json

      cart_id = JSON.parse(response.body)["id"]
      cart = Cart.find(cart_id)
      cart.update!(last_interaction_at: 1.hour.ago)

      delete remove_item_carts_url(product.id), headers: valid_headers, as: :json

      expect(cart.reload.last_interaction_at).to be > 1.hour.ago
    end
  end
end
