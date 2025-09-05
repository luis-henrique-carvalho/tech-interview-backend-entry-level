# == Schema Information
#
# Table name: carts
#
#  id                  :bigint           not null, primary key
#  abandoned_at        :datetime
#  last_interaction_at :datetime
#  total_price         :decimal(17, 2)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  session_id          :string
#
# Indexes
#
#  index_carts_on_abandoned_at  (abandoned_at)
#  index_carts_on_session_id    (session_id)
#
require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe 'scopes' do
    let!(:active_cart) { create(:cart, abandoned_at: nil) }
    let!(:abandoned_cart) { create(:cart, abandoned_at: 1.day.ago) }
    let!(:recent_cart) { create(:cart, last_interaction_at: 1.hour.ago) }
    let!(:old_cart) { create(:cart, last_interaction_at: 4.hours.ago) }
    let!(:old_abandoned_cart) { create(:cart, abandoned_at: 8.days.ago) }

    describe '.active' do
      it 'returns only active carts' do
        expect(Cart.active).to include(active_cart, recent_cart, old_cart)
        expect(Cart.active).not_to include(abandoned_cart, old_abandoned_cart)
      end
    end

    describe '.abandoned' do
      it 'returns only abandoned carts' do
        expect(Cart.abandoned).to include(abandoned_cart, old_abandoned_cart)
        expect(Cart.abandoned).not_to include(active_cart, recent_cart, old_cart)
      end
    end

    describe '.inactive_for' do
      it 'returns carts inactive for specified duration' do
        expect(Cart.inactive_for(3.hours)).to include(old_cart)
        expect(Cart.inactive_for(3.hours)).not_to include(recent_cart)
      end
    end

    describe '.abandoned_for' do
      it 'returns carts abandoned for specified duration' do
        expect(Cart.abandoned_for(7.days)).to include(old_abandoned_cart)
        expect(Cart.abandoned_for(7.days)).not_to include(abandoned_cart)
      end
    end
  end

  describe 'instance methods' do
    let(:cart) { create(:cart) }

    describe '#abandoned?' do
      it 'returns true when cart is abandoned' do
        cart.update!(abandoned_at: Time.current)
        expect(cart.abandoned?).to be true
      end

      it 'returns false when cart is active' do
        expect(cart.abandoned?).to be false
      end
    end

    describe '#active?' do
      it 'returns true when cart is active' do
        expect(cart.active?).to be true
      end

      it 'returns false when cart is abandoned' do
        cart.update!(abandoned_at: Time.current)
        expect(cart.active?).to be false
      end
    end

    describe '#mark_as_abandoned!' do
      it 'marks the cart as abandoned' do
        expect { cart.mark_as_abandoned! }
          .to change { cart.abandoned? }
          .from(false)
          .to(true)
      end

      it 'sets abandoned_at to current time' do
        before_time = Time.current
        cart.mark_as_abandoned!
        after_time = Time.current

        expect(cart.abandoned_at).to be_between(before_time, after_time)
      end
    end
  end
end
