require 'swagger_helper'

RSpec.describe 'Products API', type: :request do
  path '/products' do
    get 'List all products' do
      tags 'Products'
      produces 'application/json'

      response '200', 'Products list returned successfully' do
        schema type: :array,
               items: { '$ref' => '#/components/schemas/Product' }

        let!(:product1) { create(:product, name: 'Produto 1', price: 10.50) }
        let!(:product2) { create(:product, name: 'Produto 2', price: 25.00) }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(2)
          expect(data.first['name']).to eq('Produto 1')
          expect(data.first['price']).to eq('10.5')
        end
      end
    end

    post 'Create a new product' do
      tags 'Products'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :product, in: :body, schema: {
        type: :object,
        properties: {
          product: {
            type: :object,
            properties: {
              name: { type: :string },
              price: { type: :number, format: :decimal }
            },
            required: ['name', 'price']
          }
        }
      }

      response '201', 'Product created successfully' do
        let(:product) { { product: { name: 'Novo Produto', price: 15.99 } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq('Novo Produto')
          expect(data['price']).to eq('15.99')
        end
      end

      response '422', 'Validation error' do
        let(:product) { { product: { name: '', price: -1 } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('name')
          expect(data).to have_key('price')
        end
      end
    end
  end

  path '/products/{id}' do
    parameter name: :id, in: :path, type: :integer

    get 'Get a specific product' do
      tags 'Products'
      produces 'application/json'

      response '200', 'Product found' do
        schema '$ref' => '#/components/schemas/Product'

        let(:id) { create(:product, name: 'Produto Teste', price: 20.00).id }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq('Produto Teste')
          expect(data['price']).to eq('20.0')
        end
      end

      response '404', 'Product not found' do
        let(:id) { 999999 }

        run_test!
      end
    end

    patch 'Update a product' do
      tags 'Products'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :product, in: :body, schema: {
        type: :object,
        properties: {
          product: {
            type: :object,
            properties: {
              name: { type: :string },
              price: { type: :number, format: :decimal }
            }
          }
        }
      }

      response '200', 'Product updated successfully' do
        schema '$ref' => '#/components/schemas/Product'

        let(:id) { create(:product, name: 'Produto Original', price: 10.00).id }
        let(:product) { { product: { name: 'Produto Atualizado', price: 15.00 } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data['name']).to eq('Produto Atualizado')
          expect(data['price']).to eq('15.0')
        end
      end

      response '422', 'Validation error' do
        let(:id) { create(:product).id }
        let(:product) { { product: { name: '', price: -1 } } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to have_key('name')
          expect(data).to have_key('price')
        end
      end

      response '404', 'Product not found' do
        let(:id) { 999999 }
        let(:product) { { product: { name: 'Teste' } } }

        run_test!
      end
    end

    delete 'Delete a product' do
      tags 'Products'

      response '204', 'Product deleted successfully' do
        let(:id) { create(:product).id }

        run_test!
      end

      response '404', 'Product not found' do
        let(:id) { 999999 }

        run_test!
      end
    end
  end
end
