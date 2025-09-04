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
class Cart < ApplicationRecord
  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def calculate_total_price
    total = cart_items.sum { |item| item.total_price }

    self.update(total_price: total)
  end
end
