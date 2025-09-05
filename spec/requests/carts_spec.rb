# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Carts API', type: :request do
  path '/carts' do
    get 'Get current cart', params: { use_as_request_example: true } do
      tags 'Carts'
      consumes 'application/json'

      generate_response_examples

      response 200, 'Successful' do
        schema '$ref' => '#/components/schemas/v1/carts/responses/show'

        it 'returns the correct data structure' do
          expect(response_body).to have_key('id')
          expect(response_body).to have_key('products')
          expect(response_body).to have_key('total_price')
        end

        it 'returns products as array' do
          expect(response_body['products']).to be_an(Array)
        end

        run_test!
      end
    end

    post 'Create cart', params: { use_as_request_example: true } do
      tags 'Carts'
      consumes 'application/json'
      parameter name: :cart_item, in: :body, schema: { '$ref' => '#/components/schemas/v1/carts/requests/create' }

      let(:cart_item) { nil }

      generate_response_examples

      response 201, 'Successful' do
        let!(:product) { create(:product, name: 'Test Product', price: 10.00) }
        let(:cart_item) { { cart: { product_id: product.id, quantity: 2 } } }

        schema '$ref' => '#/components/schemas/v1/carts/responses/create'

        it 'returns the correct data structure' do
          expect(response_body).to have_key('id')
          expect(response_body).to have_key('products')
          expect(response_body).to have_key('total_price')
        end

        it 'returns products with correct length' do
          expect(response_body['products'].length).to eq(1)
        end

        it 'returns correct product data' do
          cart_product = response_body['products'].first
          expect(cart_product['name']).to eq('Test Product')
          expect(cart_product['quantity']).to eq(2)
        end

        run_test!
      end

      response 201, 'Successful - Update existing item' do
        let!(:product) { create(:product, name: 'Test Product', price: 10.00) }
        let(:cart_item) { { cart: { product_id: product.id, quantity: 3 } } }

        before do
          post '/carts', params: { cart: { product_id: product.id, quantity: 1 } }
        end

        schema '$ref' => '#/components/schemas/v1/carts/responses/create'

        it 'updates existing item quantity' do
          cart_product = response_body['products'].first
          expect(cart_product['quantity']).to eq(3) # Should replace, not add
        end

        it 'returns correct total price' do
          expect(response_body['total_price']).to eq(30.0) # 3 * 10.0
        end

        run_test!
      end

      response 404, 'Product not found' do
        let(:cart_item) { { cart: { product_id: 999, quantity: 1 } } }

        it 'returns not found error' do
          expect(response.status).to eq(404)
        end

        run_test!
      end

      response 422, 'Validation errors' do
        let!(:product) { create(:product) }

        context 'with invalid quantity' do
          let(:cart_item) { { cart: { product_id: product.id, quantity: 0 } } }

          it 'returns validation errors' do
            expect(response.status).to eq(422)
            expect(response_body).to have_key('errors')
          end

          run_test!
        end

        context 'with negative quantity' do
          let(:cart_item) { { cart: { product_id: product.id, quantity: -1 } } }

          it 'returns validation errors' do
            expect(response.status).to eq(422)
            expect(response_body).to have_key('errors')
          end

          run_test!
        end
      end
    end
  end

  path '/carts/add_item' do
    post 'Add quantity to existing item', params: { use_as_request_example: true } do
      tags 'Carts'
      consumes 'application/json'
      parameter name: :cart_item, in: :body, schema: { '$ref' => '#/components/schemas/v1/carts/requests/add_item' }

      let(:cart_item) { nil }

      generate_response_examples

      response 200, 'Successful' do
        let!(:product) { create(:product, name: 'Test Product', price: 10.00) }
        let(:cart_item) { { cart: { product_id: product.id, quantity: 1 } } }

        before do
          post '/carts', params: { cart: { product_id: product.id, quantity: 1 } }
        end

        schema '$ref' => '#/components/schemas/v1/carts/responses/add_item'

        it 'returns the correct data structure' do
          expect(response_body).to have_key('id')
          expect(response_body).to have_key('products')
          expect(response_body).to have_key('total_price')
        end

        it 'returns products with correct quantity' do
          cart_product = response_body['products'].first
          expect(cart_product['quantity']).to eq(2) # 1 + 1
        end

        run_test!
      end

      response 200, 'Successful - Add new item to cart' do
        let!(:product) { create(:product, name: 'New Product', price: 15.00) }
        let(:cart_item) { { cart: { product_id: product.id, quantity: 2 } } }

        schema '$ref' => '#/components/schemas/v1/carts/responses/add_item'

        it 'creates new item in cart' do
          cart_product = response_body['products'].first
          expect(cart_product['name']).to eq('New Product')
          expect(cart_product['quantity']).to eq(2)
        end

        it 'returns correct total price' do
          expect(response_body['total_price']).to eq(30.0) # 2 * 15.0
        end

        run_test!
      end

      response 404, 'Product not found' do
        let(:cart_item) { { cart: { product_id: 999, quantity: 1 } } }

        it 'returns not found error' do
          expect(response.status).to eq(404)
        end

        run_test!
      end

      response 422, 'Validation errors' do
        let!(:product) { create(:product) }

        context 'with invalid quantity' do
          let(:cart_item) { { cart: { product_id: product.id, quantity: 0 } } }

          it 'returns validation errors' do
            expect(response.status).to eq(422)
            expect(response_body).to have_key('errors')
          end

          run_test!
        end

        context 'with negative quantity' do
          let(:cart_item) { { cart: { product_id: product.id, quantity: -1 } } }

          it 'returns validation errors' do
            expect(response.status).to eq(422)
            expect(response_body).to have_key('errors')
          end

          run_test!
        end
      end
    end
  end

  path '/carts/{product_id}' do
    parameter name: :product_id, in: :path, type: :string

    delete 'Remove item from cart', params: { use_as_request_example: true } do
      tags 'Carts'
      consumes 'application/json'

      let(:product_id) { nil }

      generate_response_examples

      response 200, 'Successful' do
        let!(:product) { create(:product, name: 'Test Product', price: 10.00) }
        let(:product_id) { product.id }

        before do
          post '/carts', params: { cart: { product_id: product.id, quantity: 1 } }
        end

          schema '$ref' => '#/components/schemas/v1/carts/responses/remove_item'

        it 'returns the correct data structure' do
          expect(response_body).to have_key('id')
          expect(response_body).to have_key('products')
          expect(response_body).to have_key('total_price')
        end

        it 'returns empty products array' do
          expect(response_body['products']).to be_empty
        end

        run_test!
      end

      response 404, 'Item not found in cart' do
        let(:product_id) { '999' }

        it 'returns not found error' do
          expect(response.status).to eq(404)
        end

        run_test!
      end
    end
  end
end
