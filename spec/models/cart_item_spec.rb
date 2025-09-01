require 'rails_helper'

RSpec.describe CartItem, type: :model do
  subject(:cart_item) { build(:cart_item) }

  describe 'Associations' do
    it { should belong_to(:cart) }
    it { should belong_to(:product) }
  end

  describe 'Validations' do
    it 'is valid with valid attributes' do
      expect(cart_item).to be_valid
    end
    it { should validate_presence_of(:quantity) }
    it do
      should validate_numericality_of(:quantity)
        .only_integer
        .is_greater_than(0)
    end
  end

  describe 'Delegations' do
    let(:product) { create(:product, name: 'Mouse Gamer', price: 150.00) }
    subject(:cart_item_with_product) { build(:cart_item, product: product) }

    it 'delegates #name to its product' do
      expect(cart_item_with_product.name).to eq('Mouse Gamer')
    end

    it 'delegates #price (unit price) to its product' do
      expect(cart_item_with_product.price).to eq(150.00)
    end
  end

  describe '#total_price' do
    it 'calculates the total price for the line item correctly' do
      product = create(:product, price: 50.00)
      cart_item = build(:cart_item, product: product, quantity: 3)
      expect(cart_item.total_price).to eq(150.00)
    end
  end

  describe 'Callbacks' do
    let(:cart) { create(:cart) }
    let(:product) { create(:product) }

    it 'calls #update_cart_total after saving' do
      new_cart_item = build(:cart_item, cart: cart, product: product)
      expect(new_cart_item).to receive(:update_cart_total)
      new_cart_item.save
    end

    it 'calls #update_cart_total after being destroyed' do
      existing_cart_item = create(:cart_item, cart: cart, product: product)
      expect(existing_cart_item).to receive(:update_cart_total)
      existing_cart_item.destroy
    end

    context 'when an item is created, updated or destroyed' do
      it 'updates the associated cart total price' do
        expect(cart).to receive(:calculate_total_price).exactly(3).times
        item = CartItem.create(cart: cart, product: product, quantity: 2)
        item.update(quantity: 3)
        item.destroy
      end
    end
  end
end
