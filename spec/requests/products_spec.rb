# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Products API', type: :request do
  path '/products' do
    get 'List all products', params: { use_as_request_example: true } do
      tags 'Products'
      consumes 'application/json'
      produces 'application/json'


      before do
        create_list(:product, 3, name: 'Test Product', price: 10.00)
      end

      response 200, 'Successful' do
        schema '$ref' => '#/components/schemas/v1/products/responses/index'

        it 'returns the correct data length' do
          expect(response_body.length).to eq(3)
        end

        it 'returns products with correct attributes' do
          expect(response_body.first).to have_key('id')
          expect(response_body.first).to have_key('name')
          expect(response_body.first).to have_key('price')
        end

        run_test!
      end
    end

    post 'Create a new product', params: { use_as_request_example: true } do
      tags 'Products'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :product, in: :body, schema: { '$ref' => '#/components/schemas/v1/products/requests/create' }

      let(:product) { nil }


      response 201, 'Successful' do
        let(:product) { { product: { name: 'New Product', price: 15.99 } } }

        schema '$ref' => '#/components/schemas/v1/products/responses/create'

        it 'returns the correct data' do
          expect(response_body['name']).to eq('New Product')
          expect(response_body['price']).to eq('15.99')
        end

        it 'creates the product in database' do
          expect(Product.count).to eq(1)
          expect(Product.first.name).to eq('New Product')
        end

        run_test!
      end

      response 422, 'Validation errors' do
        let(:product) { { product: { name: '', price: -1 } } }

        it 'returns validation errors' do
          expect(response_body).to have_key('name')
          expect(response_body).to have_key('price')
        end

        run_test!
      end
    end
  end

  path '/products/{id}' do
    parameter name: :id, in: :path, type: :string

    get 'Show product', params: { use_as_request_example: true } do
      tags 'Products'
      consumes 'application/json'
      produces 'application/json'

      let(:id) { nil }


      response 200, 'Successful' do
        let(:id) { create(:product, name: 'Test Product', price: 20.00).id }

        schema '$ref' => '#/components/schemas/v1/products/responses/show'

        it 'returns the correct data' do
          expect(response_body['id']).to eq(id)
          expect(response_body['name']).to eq('Test Product')
          expect(response_body['price']).to eq('20.0')
        end

        run_test!
      end

      response 404, 'Not found' do
        let(:id) { '999999' }

        it 'returns not found error' do
          expect(response.status).to eq(404)
        end

        run_test!
      end
    end

    patch 'Update product', params: { use_as_request_example: true } do
      tags 'Products'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :product, in: :body, schema: { '$ref' => '#/components/schemas/v1/products/requests/update' }

      let(:id) { nil }
      let(:product) { nil }


      response 200, 'Successful' do
        let(:id) { create(:product, name: 'Original Product', price: 10.00).id }
        let(:product) { { product: { name: 'Updated Product', price: 15.00 } } }

        schema '$ref' => '#/components/schemas/v1/products/responses/update'

        it 'returns the correct data' do
          expect(response_body['name']).to eq('Updated Product')
          expect(response_body['price']).to eq('15.0')
        end

        it 'updates the product in database' do
          updated_product = Product.find(id)
          expect(updated_product.name).to eq('Updated Product')
          expect(updated_product.price).to eq(15.0)
        end

        run_test!
      end

      response 422, 'Validation errors' do
        let(:id) { create(:product).id }
        let(:product) { { product: { name: '', price: -1 } } }

        it 'returns validation errors' do
          expect(response_body).to have_key('name')
          expect(response_body).to have_key('price')
        end

        run_test!
      end

      response 404, 'Not found' do
        let(:id) { '999999' }
        let(:product) { { product: { name: 'Test' } } }

        it 'returns not found error' do
          expect(response.status).to eq(404)
        end

        run_test!
      end
    end

    delete 'Delete product', params: { use_as_request_example: true } do
      tags 'Products'
      consumes 'application/json'

      let(:id) { nil }


      response 204, 'Successful' do
        let(:id) { create(:product).id }

        it 'returns correct status' do
          expect(response.status).to eq(204)
        end

        it 'verifies if the product was deleted' do
          expect { Product.find(id) }.to raise_error(ActiveRecord::RecordNotFound)
        end

        run_test!
      end

      response 404, 'Not found' do
        let(:id) { '999999' }

        it 'returns not found error' do
          expect(response.status).to eq(404)
        end

        run_test!
      end
    end
  end
end
