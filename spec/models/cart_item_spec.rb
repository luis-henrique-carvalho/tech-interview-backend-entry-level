require 'rails_helper'

RSpec.describe CartItem, type: :model do
  let(:cart) { create(:cart) }
  let(:product) { create(:product) }

  describe 'associations' do
    it { should belong_to(:cart) }
    it { should belong_to(:product) }
  end

  describe 'validations' do
    it { should validate_presence_of(:quantity) }
    it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
  end

  describe '#total_price' do
    it 'returns the product price multiplied by quantity' do
      cart_item = build(:cart_item, cart: cart, product: product, quantity: 3)
      expect(cart_item.total_price).to eq(product.price * 3)
    end
  end

  describe 'callbacks' do
    it 'calls update_cart_total after save and destroy' do
      cart_item = build(:cart_item, cart: cart, product: product, quantity: 2)
      expect(cart_item).to receive(:update_cart_total).at_least(:once)
      cart_item.save
      cart_item.destroy
    end

    it 'updates the cart total_price after save' do
      cart_item = create(:cart_item, cart: cart, product: product, quantity: 2)
      expect(cart.reload.total_price).to eq(product.price * 2)
    end

    it 'updates the cart total_price after destroy' do
      cart_item = create(:cart_item, cart: cart, product: product, quantity: 2)
      cart_item.destroy
      expect(cart.reload.total_price).to eq(0)
    end
  end
end
