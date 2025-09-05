require 'swagger_helper'

RSpec.describe 'Carts API', type: :request do
  path '/carts' do
    get 'Get current cart' do
      tags 'Carts'
      produces 'application/json'

      response '200', 'Cart returned successfully' do
        schema '$ref' => '#/components/schemas/Cart'

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('id')
          expect(data).to have_key('products')
          expect(data).to have_key('total_price')
        end
      end
    end

    post 'Add item to cart' do
      tags 'Carts'
      consumes 'application/json'
      parameter name: :cart_item, in: :body, schema: {
        type: :object,
        properties: {
          cart: {
            type: :object,
            properties: {
              product_id: { type: :integer },
              quantity: { type: :integer }
            },
            required: ['product_id', 'quantity']
          }
        },
        required: ['cart']
      }

      response '201', 'Item added to cart successfully' do
        schema '$ref' => '#/components/schemas/Cart'

        let!(:product) { create(:product, name: 'Test Product', price: 10.00) }
        let(:cart_item) { { cart: { product_id: product.id, quantity: 2 } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('id')
          expect(data).to have_key('products')
          expect(data['products'].length).to eq(1)
        end
      end

      response '404', 'Product not found' do
        let(:cart_item) { { cart: { product_id: 999, quantity: 1 } } }

        run_test!
      end
    end
  end

  path '/carts/add_item' do
    post 'Add quantity to existing item' do
      tags 'Carts'
      consumes 'application/json'
      parameter name: :cart_item, in: :body, schema: {
        type: :object,
        properties: {
          cart: {
            type: :object,
            properties: {
              product_id: { type: :integer },
              quantity: { type: :integer }
            },
            required: ['product_id', 'quantity']
          }
        },
        required: ['cart']
      }

      response '200', 'Quantity added successfully' do
        schema '$ref' => '#/components/schemas/Cart'

        let!(:product) { create(:product, name: 'Test Product', price: 10.00) }
        let(:cart_item) { { cart: { product_id: product.id, quantity: 1 } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('id')
          expect(data).to have_key('products')
        end
      end

      response '404', 'Product not found' do
        let(:cart_item) { { cart: { product_id: 999, quantity: 1 } } }

        run_test!
      end
    end
  end

  path '/carts/{product_id}' do
    parameter name: :product_id, in: :path, type: :integer

    delete 'Remove item from cart' do
      tags 'Carts'

      response '200', 'Item removed successfully' do
        schema '$ref' => '#/components/schemas/Cart'

        let!(:product) { create(:product, name: 'Test Product', price: 10.00) }
        let(:product_id) { product.id }

        before do
          # First add the product to cart
          post '/carts', params: { cart: { product_id: product.id, quantity: 1 } }
        end

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('id')
          expect(data).to have_key('products')
        end
      end

      response '404', 'Item not found in cart' do
        let(:product_id) { 999 }

        run_test!
      end
    end
  end
end
