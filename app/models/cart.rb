class Cart < ApplicationRecord
  validates_numericality_of :total_price, greater_than_or_equal_to: 0

  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  def calculate_total_price
    total = cart_items.sum { |item| item.total_price }

    self.update(total_price: total)
  end
end
